import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/window/window_focus_tracker.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_room_bloc.dart';
import '../../blocs/chat/chat_room_event.dart';
import '../../blocs/chat/chat_room_state.dart';

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
  bool get _isDesktop => switch (defaultTargetPlatform) {
        TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux => true,
        _ => false,
      };

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
      // 데스크탑에서 blur/focus를 "읽음 처리 여부"의 기준으로 사용한다.
      // 같은 값 연속 방출은 무시한다.
      if (_lastWindowFocused == focused) return;
      _lastWindowFocused = focused;
      if (_chatRoomBloc.isClosed) return;
      _chatRoomBloc.add(focused
          ? const ChatRoomForegrounded()
          : const ChatRoomBackgrounded());
    });

    // 방 진입은 즉시 수행하되, "읽음"은 foreground 이벤트(또는 모바일 초기 foreground)에 맡긴다.
    _chatRoomBloc.add(ChatRoomOpened(widget.roomId));

    // 모바일은 페이지 진입 자체가 '보고 있음'이므로 초기 foreground를 한 번 보낸다.
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _chatRoomBloc.isClosed) return;
        _chatRoomBloc.add(const ChatRoomForegrounded());
        // 입력창에 자동 포커스 (약간의 딜레이로 키보드가 부드럽게 올라오도록)
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      });
    } else {
      // 데스크탑은 앱 생명주기(resumed)만으로는 포커스를 알 수 없다.
      // 초기 포커스 상태를 한 번 조회해 foreground/background를 동기화한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDesktopFocusOnce();
        // 데스크탑에서도 입력창에 자동 포커스
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted && !_messageFocusNode.hasFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      });
    }
  }

  Future<void> _syncDesktopFocusOnce() async {
    if (!_isDesktop) return;
    if (_chatRoomBloc.isClosed) return;
    final focused = await _windowFocusTracker.currentFocus();
    if (_chatRoomBloc.isClosed) return;
    if (focused == null) return;
    if (_lastWindowFocused == focused) return;
    _lastWindowFocused = focused;
    _chatRoomBloc.add(focused
        ? const ChatRoomForegrounded()
        : const ChatRoomBackgrounded());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 데스크탑에서는 창 포커스가 빠지는 경우 inactive로 올 수 있어 읽음 방지 위해 background 처리.
    // 모바일에서는 incoming call/시스템 UI 등 transient 상황에서도 inactive가 발생할 수 있어 과한 구독 해제를 피한다.
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    if (_chatRoomBloc.isClosed) return;

    switch (state) {
      case AppLifecycleState.inactive:
        // 데스크탑은 window focus 이벤트가 더 정확하다.
        // inactive는 transient하게 발생할 수 있어(IME/시스템 UI 등) 여기서는 읽음 상태를 바꾸지 않는다.
        if (_isDesktop) return;
        if (!_hasResumedOnce) return;
        break;
      case AppLifecycleState.paused:
        if (!_hasResumedOnce) return;
        _chatRoomBloc.add(const ChatRoomBackgrounded());
        break;
      case AppLifecycleState.resumed:
        _hasResumedOnce = true;
        // 데스크탑은 resumed만으로는 포커스가 보장되지 않는다. 실제 포커스 상태를 기준으로 동기화한다.
        if (_isDesktop) {
          _syncDesktopFocusOnce();
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id;

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
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show chat room options
              },
            ),
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
          ],
          child: Column(
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
                          final isMe = message.senderId == currentUserId;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                message.senderNickname?.isNotEmpty == true
                    ? message.senderNickname![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.myMessageBubble
                        : AppColors.otherMessageBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
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
                      fontSize: 15.5,
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMe) ...[
                      if (message.unreadCount > 0)
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
                    ] else ...[
                      Text(
                        AppDateUtils.formatMessageTime(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
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

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  // TODO: Show attachment options
                },
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
  }
}
