import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/window/window_focus_tracker.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_room_bloc.dart';
import '../../blocs/chat/chat_room_event.dart';
import '../../blocs/chat/chat_room_state.dart';
import '../../blocs/chat/message_search/message_search_bloc.dart';
import '../../blocs/chat/message_search/message_search_event.dart';
import '../../widgets/message_search_widget.dart';

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
  bool? _hasFocusTracking;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatRoomBloc = context.read<ChatRoomBloc>();
    _chatListBloc = context.read<ChatListBloc>();

    // ChatListBloc에 채팅방 진입 알림 (unreadCount 증가 방지용)
    _chatListBloc.add(ChatRoomEntered(widget.roomId));

    _scrollController.addListener(_onScroll);

    _windowFocusTracker = widget.windowFocusTracker ?? WindowFocusTracker.platform();
    _windowFocusSubscription = _windowFocusTracker.focusStream.listen((focused) {
      // 포커스 추적이 지원되는 경우 blur/focus를 "읽음 처리 여부"의 기준으로 사용한다.
      // 같은 값 연속 방출은 무시한다.
      if (_lastWindowFocused == focused) return;

      final wasNull = _lastWindowFocused == null;
      _lastWindowFocused = focused;

      // 초기 이벤트(첫 번째 이벤트)는 상태만 저장하고 이벤트를 보내지 않음
      // _syncFocusOnce()가 초기 상태를 처리하므로 중복 방지
      if (wasNull) {
        debugPrint('[ChatRoomPage] focusStream: Initial event, saving state only (focused=$focused)');
        return;
      }

      if (_chatRoomBloc.isClosed) return;

      // 이벤트 전송 플래그 설정 - _syncFocusOnce()가 중복 이벤트를 보내지 않도록
      _initialFocusEventSent = true;

      debugPrint('[ChatRoomPage] focusStream: Sending ${focused ? "ChatRoomForegrounded" : "ChatRoomBackgrounded"}');
      _chatRoomBloc.add(focused
          ? const ChatRoomForegrounded()
          : const ChatRoomBackgrounded());
    });

    // 방 진입은 즉시 수행하되, "읽음"은 foreground 이벤트(또는 포커스 추적 미지원 시 초기 foreground)에 맡긴다.
    _chatRoomBloc.add(ChatRoomOpened(widget.roomId));

    // 포커스 추적 지원 여부를 확인하고 초기화 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // 포커스 추적 지원 여부 확인 (한 번만 확인)
      if (_hasFocusTracking == null) {
        debugPrint('[ChatRoomPage] Checking focus tracking support...');
        final focus = await _windowFocusTracker.currentFocus();
        _hasFocusTracking = focus != null;
        debugPrint('[ChatRoomPage] Focus tracking support: $_hasFocusTracking (currentFocus returned: $focus)');
      }

      if (_hasFocusTracking == true) {
        debugPrint('[ChatRoomPage] Focus tracking is enabled, using _syncFocusOnce()');
        // 포커스 추적이 지원되는 경우: 초기 포커스 상태를 조회해 foreground/background를 동기화
        // _syncFocusOnce()는 focused == null 또는 false일 때 ChatRoomBackgrounded를 보냄
        debugPrint('[ChatRoomPage] Desktop: calling _syncFocusOnce()');
        _syncFocusOnce().then((_) {
          debugPrint('[ChatRoomPage] Desktop: _syncFocusOnce() completed successfully');
        }).catchError((error) {
          debugPrint('[ChatRoomPage] Desktop: _syncFocusOnce failed: $error, treating as background');
          // 예외 발생 시 background로 처리 (포커스 확인 불가 = 읽음 처리 안 함)
          if (!_chatRoomBloc.isClosed && mounted && _lastWindowFocused != false) {
            _lastWindowFocused = false;
            _chatRoomBloc.add(const ChatRoomBackgrounded());
            debugPrint('[ChatRoomPage] Desktop: Sent ChatRoomBackgrounded as fallback');
          }
        });
        // 입력창에 자동 포커스
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      } else {
        // 포커스 추적이 지원되지 않는 경우: 페이지 진입 자체가 '보고 있음'이므로 초기 foreground를 한 번 보낸다
        debugPrint('[ChatRoomPage] Focus tracking is NOT enabled, sending ChatRoomForegrounded directly');
        if (!_chatRoomBloc.isClosed) {
          _chatRoomBloc.add(const ChatRoomForegrounded());
          debugPrint('[ChatRoomPage] Sent ChatRoomForegrounded (no focus tracking)');
        }
        // 입력창에 자동 포커스 (약간의 딜레이로 키보드가 부드럽게 올라오도록)
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      }
    });
  }

  bool _initialFocusEventSent = false;

  Future<void> _syncFocusOnce() async {
    if (_chatRoomBloc.isClosed) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: bloc is closed, skipping');
      return;
    }

    // 이미 focusStream에서 초기 이벤트 이후 다른 이벤트가 전송되었으면 스킵
    // (focusStream이 더 최신 상태를 반영)
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

    // 비동기 호출 중에 focusStream에서 이벤트가 전송되었으면 스킵
    if (_initialFocusEventSent) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: focusStream sent event during await, skipping');
      return;
    }

    debugPrint('[ChatRoomPage] _syncFocusOnce: currentFocus() returned: $focused, _lastWindowFocused: $_lastWindowFocused');

    // focused가 null이면 포커스 상태를 확인할 수 없으므로 background로 처리
    // (포커스 없이 채팅방에 들어온 경우 읽음 처리를 하지 않음)
    if (focused == null) {
      debugPrint('[ChatRoomPage] _syncFocusOnce: focused is null, treating as background');
      _lastWindowFocused = false;
      _initialFocusEventSent = true;
      _chatRoomBloc.add(const ChatRoomBackgrounded());
      debugPrint('[ChatRoomPage] _syncFocusOnce: Sent ChatRoomBackgrounded (focused=null)');
      return;
    }

    // _lastWindowFocused를 사용 (focusStream에서 이미 설정된 경우 그 값이 더 최신)
    // currentFocus()는 비동기 호출이므로 호출 시점의 상태일 수 있음
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
    // 포커스 추적이 지원되는 경우 창 포커스가 빠지는 경우 inactive로 올 수 있어 읽음 방지 위해 background 처리.
    // 포커스 추적이 지원되지 않는 경우 incoming call/시스템 UI 등 transient 상황에서도 inactive가 발생할 수 있어 과한 구독 해제를 피한다.
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    if (_chatRoomBloc.isClosed) return;

    switch (state) {
      case AppLifecycleState.inactive:
        // 포커스 추적이 지원되는 경우 window focus 이벤트가 더 정확하다.
        // inactive는 transient하게 발생할 수 있어(IME/시스템 UI 등) 여기서는 읽음 상태를 바꾸지 않는다.
        if (_hasFocusTracking == true) return;
        if (!_hasResumedOnce) return;
        break;
      case AppLifecycleState.paused:
        if (!_hasResumedOnce) return;
        _chatRoomBloc.add(const ChatRoomBackgrounded());
        break;
      case AppLifecycleState.resumed:
        _hasResumedOnce = true;
        // 포커스 추적이 지원되는 경우 resumed만으로는 포커스가 보장되지 않는다. 실제 포커스 상태를 기준으로 동기화한다.
        if (_hasFocusTracking == true) {
          _syncFocusOnce();
          return;
        }
        _chatRoomBloc.add(const ChatRoomForegrounded());
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // hidden은 플랫폼별로 동작이 다를 수 있어 paused와 동일하게 취급
        if (!_hasResumedOnce) return;
        _chatRoomBloc.add(const ChatRoomBackgrounded());
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _windowFocusSubscription?.cancel();
    _focusTimer?.cancel();
    _windowFocusTracker.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    if (!_chatRoomBloc.isClosed) {
      _chatRoomBloc.add(const ChatRoomClosed());
    }
    // ChatListBloc에 채팅방 퇴장 알림
    if (!_chatListBloc.isClosed) {
      _chatListBloc.add(const ChatRoomExited());
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatRoomBloc>().add(const MessagesLoadMoreRequested());
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatRoomBloc>().add(MessageSent(content));
    _messageController.clear();
    // 메시지 전송 후에도 입력창 포커스 유지
    _messageFocusNode.requestFocus();
  }

  void _scrollToBottom({bool smooth = true}) {
    if (!_scrollController.hasClients) return;
    if (smooth) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  void _showChatRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('채팅방 나가기', style: TextStyle(color: Colors.red)),
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
        title: const Text('채팅방 나가기'),
        content: const Text('채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ChatRoomBloc>().add(const ChatRoomLeaveRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        // 검색 모드 종료 시 검색 상태 초기화
        context.read<MessageSearchBloc>().add(const MessageSearchCleared());
      }
    });
  }

  void _onMessageSelected(int messageId) {
    // 검색 모드 종료
    setState(() {
      _isSearchMode = false;
    });
    // 선택한 메시지로 스크롤 (TODO: 메시지 위치 찾아서 스크롤)
    // 현재는 검색 결과 선택 시 검색 모드만 종료
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 방을 만든 사람(또는 go로 진입한 경우)은 스택에 이전 라우트가 없어서
              // 기본 back 버튼이 안 보일 수 있다. 항상 안전한 뒤로가기를 제공한다.
              if (context.canPop()) {
                context.pop();
                return;
              }
              // 스택 pop이 불가능하면 채팅 목록으로 이동
              context.go(AppRoutes.chatList);
            },
          ),
          title: const Text(
            '채팅',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
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
            // 새 메시지가 도착하면 자동으로 스크롤 (내가 보낸 메시지이거나, 상대방 메시지일 때)
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                // 메시지가 추가되었을 때만 스크롤
                if (previous.messages.length == current.messages.length) {
                  return false;
                }
                // 첫 로드 시에는 스크롤하지 않음 (이미 reverse: true로 맨 아래에 있음)
                if (previous.messages.isEmpty) {
                  return false;
                }
                return true;
              },
              listener: (context, state) {
                // 새 메시지가 추가되었고, 사용자가 맨 아래 근처에 있으면 자동 스크롤
                if (_scrollController.hasClients) {
                  final isNearBottom = _scrollController.position.pixels < 100;
                  if (isNearBottom) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                }
              },
            ),
            // isReadMarked가 false -> true로 변경될 때 ChatListBloc에 알림
            // 서버가 chatRoomUpdates로 unreadCount를 보내주지만, 클라이언트에서도 알림을 보내서
            // 서버 응답이 지연되거나 누락되는 경우에도 UI가 빠르게 업데이트되도록 함
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                // isReadMarked가 false -> true로 변경될 때만
                return !previous.isReadMarked && current.isReadMarked && current.roomId != null;
              },
              listener: (context, state) {
                // ChatListBloc에 읽음 완료 알림 전송
                if (state.roomId != null && !_chatListBloc.isClosed) {
                  _chatListBloc.add(ChatRoomReadCompleted(state.roomId!));
                }
              },
            ),
            // 채팅방 나가기 완료 시 채팅 목록으로 이동
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                return !previous.hasLeft && current.hasLeft;
              },
              listener: (context, state) {
                // 채팅 목록 새로고침
                if (!_chatListBloc.isClosed) {
                  _chatListBloc.add(const ChatListRefreshRequested());
                }
                // 채팅 목록으로 이동
                context.go(AppRoutes.chatList);
              },
            ),
            // 재초대 결과 피드백
            BlocListener<ChatRoomBloc, ChatRoomState>(
              listenWhen: (previous, current) {
                // 재초대가 완료되었을 때 (성공 또는 에러)
                return previous.isReinviting && !current.isReinviting;
              },
              listener: (context, state) {
                if (state.reinviteSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.otherUserNickname ?? "상대방"}님을 다시 초대했습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // 채팅 목록 새로고침
                  if (!_chatListBloc.isClosed) {
                    _chatListBloc.add(const ChatListRefreshRequested());
                  }
                } else if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('재초대 실패: ${state.errorMessage}'),
                      backgroundColor: Colors.red,
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
              : Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
              builder: (context, state) {
                if (state.status == ChatRoomStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '메시지가 없습니다',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '대화를 시작해보세요',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final isMe = message.senderId == state.currentUserId;

                          final showDateSeparator = index == state.messages.length - 1 ||
                              !AppDateUtils.isSameDay(
                                message.createdAt,
                                state.messages[index + 1].createdAt,
                              );

                          return Column(
                            children: [
                              if (showDateSeparator) _DateSeparator(date: message.createdAt),
                              _MessageBubble(message: message, isMe: isMe),
                            ],
                          );
                        },
                      ),
                    ),
                    // 타이핑 인디케이터
                    if (state.isAnyoneTyping)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.typingIndicatorText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSend: _sendMessage,
            onChanged: () {
              // 타이핑 시작 이벤트 발생
              context.read<ChatRoomBloc>().add(const UserStartedTyping());
            },
          ),
        ],
          ),
        ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppDateUtils.formatFullDate(date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  /// 메시지 수정/삭제 가능 시간(5분)이 지났는지 확인
  bool get _isEditTimeExpired {
    return DateTime.now().difference(message.createdAt).inMinutes >= 5;
  }

  /// 파일 타입에 맞는 아이콘 반환
  IconData _getFileIcon(String? contentType) {
    if (contentType == null) return Icons.insert_drive_file;
    if (contentType.startsWith('image/')) return Icons.image;
    if (contentType.startsWith('video/')) return Icons.videocam;
    if (contentType.startsWith('audio/')) return Icons.audiotrack;
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    }
    if (contentType.contains('sheet') || contentType.contains('excel')) {
      return Icons.table_chart;
    }
    if (contentType.contains('presentation') || contentType.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (contentType.contains('zip') || contentType.contains('rar') || contentType.contains('tar')) {
      return Icons.folder_zip;
    }
    return Icons.insert_drive_file;
  }

  /// 파일 크기를 읽기 쉬운 형식으로 변환
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 이미지 전체 화면 보기
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 파일 다운로드 (브라우저에서 열기)
  Future<void> _downloadFile(BuildContext context, String fileUrl, String? fileName) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('파일을 열 수 없습니다: ${fileName ?? fileUrl}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  void _showMessageOptions(BuildContext context) {
    // 삭제된 메시지는 옵션 표시 안함
    if (message.isDeleted) return;
    // 내 메시지만 수정/삭제 가능
    if (!isMe) return;
    // 5분 지난 메시지는 수정/삭제 불가
    if (_isEditTimeExpired) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('수정'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메시지 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '메시지를 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                context.read<ChatRoomBloc>().add(MessageUpdateRequested(
                  messageId: message.id,
                  content: newContent,
                ));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatRoomBloc>().add(MessageDeleted(message.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 메시지는 중앙 정렬로 표시
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // 시간 및 읽음 표시 위젯
    Widget timeWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMe && message.unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '${message.unreadCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
        Text(
          AppDateUtils.formatMessageTime(message.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );

    // 메시지 버블
    Widget bubbleWidget;

    // 이미지 메시지
    if (message.type == MessageType.image && message.fileUrl != null) {
      bubbleWidget = GestureDetector(
        onTap: () => _showFullScreenImage(context, message.fileUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
              maxHeight: 250,
            ),
            child: Image.network(
              message.fileUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 150,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '이미지를 불러올 수 없습니다',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    // 파일 메시지
    else if (message.type == MessageType.file && message.fileUrl != null) {
      bubbleWidget = GestureDetector(
        onTap: () => _downloadFile(context, message.fileUrl!, message.fileName),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.myMessageBubble : AppColors.otherMessageBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(message.fileContentType),
                  color: isMe ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? '파일',
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.fileSize != null)
                          Text(
                            _formatFileSize(message.fileSize!),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.download,
                          size: 14,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 텍스트 메시지 (기본)
    else {
      bubbleWidget = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.myMessageBubble : AppColors.otherMessageBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          message.displayContent,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
            letterSpacing: 0.1,
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: isMe ? () => _showMessageOptions(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 상대방 메시지: 아바타 + 닉네임 + 버블 + 시간
            if (!isMe) ...[
              GestureDetector(
                onTap: () => context.push(AppRoutes.profileViewPath(message.senderId)),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: message.senderAvatarUrl != null
                      ? NetworkImage(message.senderAvatarUrl!)
                      : null,
                  child: message.senderAvatarUrl == null
                      ? Text(
                          message.senderNickname?.isNotEmpty == true
                              ? message.senderNickname![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상대방 닉네임 표시 (탭하면 프로필로 이동)
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profileViewPath(message.senderId)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          message.senderNickname ?? '알 수 없음',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // 버블 + 시간 (카카오톡 스타일: 시간이 버블 오른쪽)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: bubbleWidget),
                        const SizedBox(width: 6),
                        timeWidget,
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // 내 메시지: 시간 + 버블 (카카오톡 스타일: 시간이 버블 왼쪽)
            if (isMe) ...[
              timeWidget,
              const SizedBox(width: 6),
              Flexible(child: bubbleWidget),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onChanged;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onChanged,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 텍스트 변경을 감지하기 위해 리스너 추가
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // 상태 업데이트로 리빌드 트리거
    });
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  void _handleSend() {
    if (_hasText) {
      widget.onSend();
    }
  }

  /// 첨부 옵션 바텀시트를 표시합니다.
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('갤러리에서 선택'),
                subtitle: const Text('사진 또는 동영상을 선택합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('카메라'),
                subtitle: const Text('사진을 촬영합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.orange),
                ),
                title: const Text('파일'),
                subtitle: const Text('문서, PDF 등의 파일을 선택합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 갤러리에서 이미지를 선택합니다.
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        context.read<ChatRoomBloc>().add(FileAttachmentRequested(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 선택할 수 없습니다: $e')),
        );
      }
    }
  }

  /// 카메라로 사진을 촬영합니다.
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        context.read<ChatRoomBloc>().add(FileAttachmentRequested(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라를 사용할 수 없습니다: $e')),
        );
      }
    }
  }

  /// 파일을 선택합니다.
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          context.read<ChatRoomBloc>().add(FileAttachmentRequested(filePath));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일을 선택할 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      buildWhen: (previous, current) =>
          previous.isOtherUserLeft != current.isOtherUserLeft ||
          previous.otherUserNickname != current.otherUserNickname ||
          previous.isUploadingFile != current.isUploadingFile,
      builder: (context, state) {
        // 파일 업로드 중일 때 로딩 표시
        if (state.isUploadingFile) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '파일 업로드 중...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 상대방이 나간 경우 "다시 초대하기" UI 표시
        if (state.isOtherUserLeft) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${state.otherUserNickname ?? "상대방"}님이 채팅방을 나갔습니다',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.isReinviting
                            ? null
                            : () {
                                final otherUserId = state.otherUserId;
                                if (otherUserId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('상대방 정보를 찾을 수 없습니다'),
                                    ),
                                  );
                                  return;
                                }
                                context.read<ChatRoomBloc>().add(
                                      ReinviteUserRequested(inviteeId: otherUserId),
                                    );
                              },
                        icon: state.isReinviting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(state.isReinviting ? '초대 중...' : '다시 초대하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 일반 입력창
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _showAttachmentOptions,
                    tooltip: '첨부',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        decoration: InputDecoration(
                          hintText: '메시지를 입력하세요',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: AppColors.divider,
                              width: 1.5,
                            ),
                          ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      widget.onChanged?.call();
                      // onChanged에서도 상태 업데이트 (리스너가 자동으로 호출되지만 명시적으로)
                    },
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<ChatRoomBloc, ChatRoomState>(
                builder: (context, state) {
                  final canSend = _hasText && !state.isSending;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    child: IconButton(
                      icon: state.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: canSend ? _handleSend : null,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
