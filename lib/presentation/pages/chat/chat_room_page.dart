import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_room_bloc.dart';
import '../../blocs/chat/chat_room_event.dart';
import '../../blocs/chat/chat_room_state.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;

  const ChatRoomPage({super.key, required this.roomId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatRoomBloc _chatRoomBloc;

  @override
  void initState() {
    super.initState();
    _chatRoomBloc = context.read<ChatRoomBloc>();
    _chatRoomBloc.add(ChatRoomOpened(widget.roomId));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (!_chatRoomBloc.isClosed) {
      _chatRoomBloc.add(const ChatRoomClosed());
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
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id;

    return BlocListener<ChatRoomBloc, ChatRoomState>(
      // 채팅방이 성공적으로 열리면 즉시 읽음 처리 완료 이벤트 발생 (실시간 업데이트)
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ChatRoomStatus.success &&
          current.roomId != null,
      listener: (context, state) {
        // ignore: avoid_print
        print('[ChatRoomPage] Chat room opened successfully, marking as read in ChatListBloc: roomId=${state.roomId}');
        context.read<ChatListBloc>().add(ChatRoomReadCompleted(state.roomId!));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('채팅'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show chat room options
              },
            ),
          ],
        ),
        body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
              builder: (context, state) {
                if (state.status == ChatRoomStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text('메시지가 없습니다\n대화를 시작해보세요'),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                message.senderNickname?.isNotEmpty == true
                    ? message.senderNickname![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isMe) ...[
            if (message.unreadCount > 0)
              Text(
                '${message.unreadCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            const SizedBox(width: 4),
            Text(
              AppDateUtils.formatMessageTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.myMessageBubble
                    : AppColors.otherMessageBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.displayContent,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (!isMe) ...[
            Text(
              AppDateUtils.formatMessageTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (message.unreadCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${message.unreadCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onChanged;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // TODO: Show attachment options
              },
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (_) => onChanged?.call(),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ChatRoomBloc, ChatRoomState>(
              builder: (context, state) {
                return IconButton.filled(
                  icon: state.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: state.isSending ? null : onSend,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
