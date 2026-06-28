import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/active_room_tracker.dart';
import '../../../core/services/notification_click_handler.dart';
import '../../../core/window/window_focus_tracker.dart';
import '../../../core/network/websocket_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_room_bloc.dart';
import '../../blocs/chat/chat_room_event.dart';
import '../../blocs/chat/chat_room_state.dart';
import '../../blocs/chat/message_search/message_search_bloc.dart';
import '../../blocs/chat/message_search/message_search_event.dart';
import '../../widgets/message_search_widget.dart';
import '../../widgets/connection_status_banner.dart';
import '../profile/handlers/image_picker_handler.dart';
import 'media_gallery_page.dart';
import 'widgets/widgets.dart';

/// Main chat room page that orchestrates message display, input, and BLoC subscriptions.
class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final WindowFocusTracker? windowFocusTracker;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    this.windowFocusTracker,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

/// 채팅 방(room) 전용 라이프사이클 옵저버.
///
/// 책임 경계(M2): 이 옵저버는 방이 열려 있는 동안의 **per-room presence와
/// WebSocket 연결**을 담당한다 — paused 즉시 presence-inactive 전송, 1.5s
/// 디바운스 후 ChatRoomBackgrounded(소켓 정리), iOS inactive-vs-paused 구분.
/// 앱 전역 보안 잠금은 app.dart의 _AppLifecycleHandler가 담당한다(역할 분리).
/// presence는 per-room이므로, 방 밖(채팅 목록)에서의 백그라운드 전환에는 별도
/// presence 의무가 없다 — 자세한 근거는 app.dart의 _AppLifecycleHandler 주석 참고.
class _ChatRoomPageState extends State<ChatRoomPage> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageFocusNode = FocusNode();
  late final ChatRoomBloc _chatRoomBloc;
  late final ChatListBloc _chatListBloc;
  AppLifecycleState? _lastLifecycleState;
  bool _hasResumedOnce = false;
  late final WindowFocusTracker _windowFocusTracker;
  StreamSubscription<bool>? _windowFocusSubscription;
  bool? _lastWindowFocused;
  Timer? _focusTimer;
  Timer? _backgroundDebounceTimer;
  bool? _hasFocusTracking;
  bool _isSearchMode = false;
  bool _initialFocusEventSent = false;
  bool _showScrollFab = false;
  int _unreadWhileScrolled = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatRoomBloc = context.read<ChatRoomBloc>();
    _chatListBloc = context.read<ChatListBloc>();

    // Register same-room refresh callback for notification taps
    try {
      final notificationClickHandler = GetIt.instance<NotificationClickHandler>();
      notificationClickHandler.onSameRoomRefresh = (roomId) {
        if (!_chatRoomBloc.isClosed) {
          _chatRoomBloc.add(const ChatRoomRefreshRequested());
        }
      };
    } catch (_) {
      // NotificationClickHandler not registered in DI (e.g., tests)
    }

    // Notify ChatListBloc of room entry (to prevent unreadCount increase)
    _chatListBloc.add(ChatRoomEntered(widget.roomId));

    _scrollController.addListener(_onScroll);

    _windowFocusTracker = widget.windowFocusTracker ?? WindowFocusTracker.platform();
    _windowFocusSubscription = _windowFocusTracker.focusStream.listen((focused) {
      if (_lastWindowFocused == focused) return;

      final wasNull = _lastWindowFocused == null;
      _lastWindowFocused = focused;

      if (wasNull) {
        debugPrint('[ChatRoomPage] focusStream: Initial event, saving state only (focused=$focused)');
        return;
      }

      if (_chatRoomBloc.isClosed) return;

      _initialFocusEventSent = true;

      debugPrint('[ChatRoomPage] focusStream: Sending ${focused ? "ChatRoomForegrounded" : "ChatRoomBackgrounded"}');
      _chatRoomBloc.add(focused
          ? const ChatRoomForegrounded()
          : const ChatRoomBackgrounded());

      // Sync ChatListBloc: suppress/restore unread count based on window focus
      if (!_chatListBloc.isClosed) {
        if (focused) {
          _chatListBloc.add(ChatRoomEntered(widget.roomId));
        } else {
          _chatListBloc.add(const ChatRoomExited());
        }
      }
    });

    _chatRoomBloc.add(ChatRoomOpened(widget.roomId));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (_hasFocusTracking == null) {
        debugPrint('[ChatRoomPage] Checking focus tracking support...');
        final focus = await _windowFocusTracker.currentFocus();
        _hasFocusTracking = focus != null;
        debugPrint('[ChatRoomPage] Focus tracking support: $_hasFocusTracking (currentFocus returned: $focus)');
      }

      if (_hasFocusTracking == true) {
        debugPrint('[ChatRoomPage] Focus tracking is enabled, using _syncFocusOnce()');
        debugPrint('[ChatRoomPage] Desktop: calling _syncFocusOnce()');
        _syncFocusOnce().then((_) {
          debugPrint('[ChatRoomPage] Desktop: _syncFocusOnce() completed successfully');
        }).catchError((error) {
          debugPrint('[ChatRoomPage] Desktop: _syncFocusOnce failed: $error, treating as background');
          if (!_chatRoomBloc.isClosed && mounted && _lastWindowFocused != false) {
            _lastWindowFocused = false;
            _chatRoomBloc.add(const ChatRoomBackgrounded());
            debugPrint('[ChatRoomPage] Desktop: Sent ChatRoomBackgrounded as fallback');
          }
        });
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      } else {
        debugPrint('[ChatRoomPage] Focus tracking is NOT enabled, sending ChatRoomForegrounded directly');
        if (!_chatRoomBloc.isClosed) {
          _chatRoomBloc.add(const ChatRoomForegrounded());
          debugPrint('[ChatRoomPage] Sent ChatRoomForegrounded (no focus tracking)');
        }
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      }
    });
  }

  Future<void> _syncFocusOnce() async {
    if (_chatRoomBloc.isClosed) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: bloc is closed, skipping');
      return;
    }

    if (_initialFocusEventSent) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: focusStream already sent event, skipping');
      return;
    }

    debugPrint('[ChatRoomPage] _syncFocusOnce: calling currentFocus()');
    final focused = await _windowFocusTracker.currentFocus();
    if (_chatRoomBloc.isClosed) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: bloc closed after currentFocus(), skipping');
      return;
    }

    if (_initialFocusEventSent) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: focusStream sent event during await, skipping');
      return;
    }

    debugPrint('[ChatRoomPage] _syncFocusOnce: currentFocus() returned: $focused, _lastWindowFocused: $_lastWindowFocused');

    if (focused == null) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: focused is null, treating as background');
      _lastWindowFocused = false;
      _initialFocusEventSent = true;
      _chatRoomBloc.add(const ChatRoomBackgrounded());
      debugPrint('[ChatRoomPage] _syncFocusOnce: Sent ChatRoomBackgrounded (focused=null)');
      return;
    }

    final actualFocused = _lastWindowFocused ?? focused;
    _lastWindowFocused = actualFocused;
    _initialFocusEventSent = true;

    if (actualFocused) {
      _chatRoomBloc.add(const ChatRoomForegrounded());
      debugPrint('[ChatRoomPage] _syncFocusOnce: Sent ChatRoomForegrounded (actualFocused=true)');
    } else {
      _chatRoomBloc.add(const ChatRoomBackgrounded());
      debugPrint('[ChatRoomPage] _syncFocusOnce: Sent ChatRoomBackgrounded (actualFocused=false)');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    if (_chatRoomBloc.isClosed) return;

    switch (state) {
      case AppLifecycleState.inactive:
        if (_hasFocusTracking == true) return;
        if (!_hasResumedOnce) return;
        // On iOS, inactive fires for notification center, control center, etc.
        // Don't do anything here - wait for paused if it's a real background.
        break;
      case AppLifecycleState.paused:
        // Send presence-inactive immediately (independent of _hasResumedOnce
        // and the debounce). This is lightweight and idempotent on the server,
        // so the server stops suppressing push even if the OS suspends the app
        // before the 1.5s debounce fires. WebSocket disconnect stays debounced.
        if (!_chatRoomBloc.isClosed) {
          _chatRoomBloc.add(const ChatRoomViewInactive());
        }
        if (!_hasResumedOnce) return;
        // Debounce: only dispatch backgrounded after 1.5 seconds.
        // iOS fires paused for brief interruptions like notification center.
        // If the user returns quickly, the timer is cancelled by resumed.
        _backgroundDebounceTimer?.cancel();
        _backgroundDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!_chatRoomBloc.isClosed) {
            _chatRoomBloc.add(const ChatRoomBackgrounded());
          }
          if (!_chatListBloc.isClosed) {
            _chatListBloc.add(const ChatRoomExited());
          }
        });
        break;
      case AppLifecycleState.resumed:
        _hasResumedOnce = true;
        // Cancel any pending background timer - user returned quickly
        _backgroundDebounceTimer?.cancel();
        _backgroundDebounceTimer = null;
        if (_hasFocusTracking == true) {
          _syncFocusOnce();
          return;
        }
        _chatRoomBloc.add(const ChatRoomForegrounded());
        if (!_chatListBloc.isClosed) {
          _chatListBloc.add(ChatRoomEntered(widget.roomId));
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Send presence-inactive immediately (see paused case above).
        if (!_chatRoomBloc.isClosed) {
          _chatRoomBloc.add(const ChatRoomViewInactive());
        }
        if (!_hasResumedOnce) return;
        // For detached/hidden, also debounce
        _backgroundDebounceTimer?.cancel();
        _backgroundDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!_chatRoomBloc.isClosed) {
            _chatRoomBloc.add(const ChatRoomBackgrounded());
          }
          if (!_chatListBloc.isClosed) {
            _chatListBloc.add(const ChatRoomExited());
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _windowFocusSubscription?.cancel();
    _focusTimer?.cancel();
    _backgroundDebounceTimer?.cancel();
    _windowFocusTracker.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();

    // ActiveRoomTracker를 동기적으로 즉시 해제 (FCM 알림 suppress 방지)
    // 소유권 가드: 방 A->B 빠른 전환 시 B의 initState가 이미 activeRoomId=B로
    // 설정했을 수 있으므로, 현재 활성 방이 "내 방"일 때만 해제한다.
    // 무조건 null로 덮어쓰면 B의 active 설정이 지워져 B 알림 억제가 깨진다.
    try {
      final activeRoomTracker = GetIt.instance<ActiveRoomTracker>();
      if (activeRoomTracker.activeRoomId == widget.roomId) {
        activeRoomTracker.activeRoomId = null;
      }
    } catch (e) {
      // best-effort: dispose 중 GetIt 미등록 등은 무시하되 debug에서는 가시화.
      if (kDebugMode) {
        debugPrint('[ChatRoomPage] ActiveRoomTracker reset skipped: $e');
      }
    }

    if (!_chatRoomBloc.isClosed) {
      _chatRoomBloc.add(const ChatRoomClosed());
    }
    if (!_chatListBloc.isClosed) {
      _chatListBloc.add(const ChatRoomExited());
    }
    // Unregister same-room refresh callback
    try {
      final notificationClickHandler = GetIt.instance<NotificationClickHandler>();
      notificationClickHandler.onSameRoomRefresh = null;
    } catch (e) {
      // best-effort: 콜백 해제 실패는 무시하되 debug에서는 가시화.
      if (kDebugMode) {
        debugPrint('[ChatRoomPage] onSameRoomRefresh unregister skipped: $e');
      }
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatRoomBloc>().add(const MessagesLoadMoreRequested());
    }

    // Show/hide scroll-to-bottom FAB based on scroll position
    final showFab = _scrollController.position.pixels > 100;
    if (showFab != _showScrollFab) {
      setState(() {
        _showScrollFab = showFab;
        if (!showFab) {
          _unreadWhileScrolled = 0; // Reset unread count when at bottom
        }
      });
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatRoomBloc>().add(MessageSent(content));
    _messageController.clear();
    _messageFocusNode.requestFocus();

    // 메시지 전송 시 부드럽게 스크롤 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _scrollToBottom({bool smooth = true}) {
    if (!_scrollController.hasClients) return;
    if (smooth) {
      _scrollController.animateTo(
        0,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _pickAndUpdateGroupImage(BuildContext context) async {
    final imagePicker = ImagePickerHandler();
    final file = await imagePicker.pickFromGallery();
    if (file == null) return;

    if (!context.mounted) return;

    try {
      final chatRepository = GetIt.instance<ChatRepository>();
      final uploadResult = await chatRepository.uploadFile(file);
      await chatRepository.updateChatRoomImage(widget.roomId, uploadResult.fileUrl);

      if (!context.mounted) return;

      _chatListBloc.add(const ChatListRefreshRequested());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatRoomImageUpdated)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatRoomImageUpdateFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChatRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(AppLocalizations.of(context)!.chatRoomChangeImage),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndUpdateGroupImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context)!.chatMediaGallery),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MediaGalleryPage(roomId: widget.roomId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.chatRoomLeave, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showLeaveConfirmDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chatRoomLeave),
        content: Text(AppLocalizations.of(context)!.chatRoomLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ChatRoomBloc>().add(const ChatRoomLeaveRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.chatRoomLeaveAction),
          ),
        ],
      ),
    );
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        context.read<MessageSearchBloc>().add(const MessageSearchCleared());
      }
    });
  }

  void _onMessageSelected(int messageId) {
    setState(() {
      _isSearchMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(AppRoutes.chatList);
            },
          ),
          title: BlocBuilder<ChatRoomBloc, ChatRoomState>(
            buildWhen: (previous, current) =>
                previous.otherUserNickname != current.otherUserNickname ||
                previous.roomName != current.roomName ||
                previous.roomType != current.roomType,
            builder: (context, state) {
              return Text(
                state.displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          actions: [
            if (!_isSearchMode) ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearchMode,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showChatRoomOptions(context),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSearchMode,
              ),
            ],
          ],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: MultiBlocListener(
          listeners: [
            // Auto-scroll on new messages
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                if (current.messages.isEmpty || previous.messages.isEmpty) {
                  return false;
                }
                // Skip loadMore completions (old messages added at the end)
                if (previous.isLoadingMore && !current.isLoadingMore) {
                  return false;
                }
                // Only fire when the NEWEST message changed (new message arrived)
                return current.messages.first.id != previous.messages.first.id;
              },
              listener: (context, state) {
                if (_scrollController.hasClients) {
                  final isNearBottom = _scrollController.position.pixels < 100;
                  if (isNearBottom) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  } else if (_showScrollFab) {
                    // User is scrolled up, show new message indicator
                    setState(() {
                      _unreadWhileScrolled++;
                    });
                  }
                }
              },
            ),
            // Notify ChatListBloc when read is marked
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return !previous.isReadMarked && current.isReadMarked && current.roomId != null;
              },
              listener: (context, state) {
                if (state.roomId != null && !_chatListBloc.isClosed) {
                  _chatListBloc.add(ChatRoomReadCompleted(state.roomId!));
                }
              },
            ),
            // Navigate to chat list when leaving room
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return !previous.hasLeft && current.hasLeft;
              },
              listener: (context, state) {
                if (!_chatListBloc.isClosed) {
                  _chatListBloc.add(const ChatListRefreshRequested());
                }
                context.go(AppRoutes.chatList);
              },
            ),
            // Reinvite result feedback
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return previous.isReinviting && !current.isReinviting;
              },
              listener: (context, state) {
                if (state.reinviteSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.chatReinviteSuccess(
                        state.otherUserNickname ?? AppLocalizations.of(context)!.chatOtherUser,
                      )),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (!_chatListBloc.isClosed) {
                    _chatListBloc.add(const ChatListRefreshRequested());
                  }
                } else if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.chatReinviteFailed(state.errorMessage ?? '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            // General error messages (excluding reinvite)
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return current.errorMessage != null &&
                    previous.errorMessage != current.errorMessage &&
                    !current.isReinviting;
              },
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            // Forward success feedback
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return previous.isForwarding && !current.isForwarding;
              },
              listener: (context, state) {
                if (state.forwardSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.chatMessageForwarded),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
          child: _isSearchMode
              ? MessageSearchWidget(
                  chatRoomId: widget.roomId,
                  onMessageSelected: _onMessageSelected,
                  onClose: _toggleSearchMode,
                )
              : StreamBuilder<WebSocketConnectionState>(
                  stream: GetIt.instance<WebSocketService>().connectionState,
                  builder: (context, snapshot) {
                    final connectionState = snapshot.data ?? WebSocketConnectionState.connected;

                    return Stack(
                      children: [
                        Column(
                          children: [
                            // Connection status banner at the top
                            ConnectionStatusBanner(
                              connectionState: connectionState,
                              onReconnect: () {
                                final webSocketService = GetIt.instance<WebSocketService>();
                                webSocketService.resetReconnectAttempts();
                                webSocketService.connect();
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _dismissKeyboard,
                                behavior: HitTestBehavior.opaque,
                                child: MessageList(scrollController: _scrollController),
                              ),
                            ),
                            BlocBuilder<ChatRoomBloc, ChatRoomState>(
                              buildWhen: (previous, current) =>
                                  previous.replyToMessage != current.replyToMessage,
                              builder: (context, state) {
                                return MessageInput(
                                  controller: _messageController,
                                  focusNode: _messageFocusNode,
                                  onSend: _sendMessage,
                                  onChanged: () {
                                    context.read<ChatRoomBloc>().add(const UserStartedTyping());
                                  },
                                  replyToMessage: state.replyToMessage,
                                  onCancelReply: () {
                                    context.read<ChatRoomBloc>().add(const ReplyCancelled());
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        Positioned(
                          right: 16,
                          bottom: 80,
                          child: ScrollToBottomFab(
                            visible: _showScrollFab,
                            unreadCount: _unreadWhileScrolled,
                            onTap: () {
                              _scrollToBottom();
                              setState(() {
                                _unreadWhileScrolled = 0;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
    );
  }
}
