import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../blocs/chat/chat_room_bloc.dart';
import '../../../blocs/chat/chat_room_state.dart';
import 'date_separator.dart';
import 'message_bubble.dart';

/// Widget that displays the list of messages with date separators and typing indicator.
class MessageList extends StatelessWidget {
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
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
                  color: context.textSecondaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '메시지가 없습니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '대화를 시작해보세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textSecondaryColor.withValues(alpha: 0.7),
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
                controller: scrollController,
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
                      if (showDateSeparator) DateSeparator(date: message.createdAt),
                      MessageBubble(message: message, isMe: isMe),
                    ],
                  );
                },
              ),
            ),
            // Typing indicator
            if (state.isAnyoneTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.typingIndicatorText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
