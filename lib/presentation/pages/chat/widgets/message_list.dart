import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/message.dart';
import '../../../blocs/chat/chat_room_bloc.dart';
import '../../../blocs/chat/chat_room_state.dart';
import '../../../widgets/entry_animation.dart';
import 'animated_typing_dots.dart';
import 'date_separator.dart';
import 'message_bubble.dart';
import 'message_entry_tracker.dart';

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
              child: _MessageListView(
                messages: state.messages,
                currentUserId: state.currentUserId,
                scrollController: scrollController,
              ),
            ),
            // Typing indicator — animated bouncing dots
            if (state.isAnyoneTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AnimatedTypingDots(),
                    const SizedBox(width: 8),
                    if (state.typingIndicatorText.isNotEmpty)
                      Flexible(
                        child: Text(
                          state.typingIndicatorText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.textSecondaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 메시지 리스트 뷰. 새로 도착한 메시지에만 1회 진입 애니메이션을 적용한다.
///
/// 최초 빌드 시 현재 메시지들을 모두 "본 것"으로 시드하므로 초기 로드분은
/// 애니메이션되지 않고, 이후 도착하는 메시지만 [EntryAnimation] 으로 등장한다.
/// 스크롤로 항목이 재생성돼도 이미 본 id 는 다시 애니메이션되지 않는다.
class _MessageListView extends StatefulWidget {
  final List<Message> messages;
  final int? currentUserId;
  final ScrollController scrollController;

  const _MessageListView({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  State<_MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<_MessageListView> {
  final MessageEntryTracker _tracker = MessageEntryTracker();

  /// 낙관적 메시지는 localId 가, 확정 메시지는 서버 id 가 안정적 키.
  String _keyOf(Message m) => m.localId ?? 'id_${m.id}';

  @override
  void initState() {
    super.initState();
    // 최초 빌드 시 이미 보이는 메시지들을 시드 — build() 밖에서 1회만 실행
    _tracker.seedIfNeeded(widget.messages.map(_keyOf));
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == widget.currentUserId;

        final showDateSeparator = index == messages.length - 1 ||
            !AppDateUtils.isSameDay(
              message.createdAt,
              messages[index + 1].createdAt,
            );

        final key = _keyOf(message);
        final isNew = _tracker.registerAndCheckNew(key);

        return Column(
          key: ValueKey(key),
          children: [
            if (showDateSeparator) DateSeparator(date: message.createdAt),
            EntryAnimation(
              animate: isNew,
              child: MessageBubble(message: message, isMe: isMe),
            ),
          ],
        );
      },
    );
  }
}
