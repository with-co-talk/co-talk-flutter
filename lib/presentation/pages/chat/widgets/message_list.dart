import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/app_localizations.dart';
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
                    if (state.firstTypingNickname != null)
                      Flexible(
                        child: Text(
                          state.typingCount == 1
                              ? AppLocalizations.of(context)!
                                  .chatTypingSingle(state.firstTypingNickname!)
                              : AppLocalizations.of(context)!
                                  .chatTypingMultiple(state.typingCount),
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
///
/// 빈 대화방으로 진입하면 빈 집합으로 시드되므로(시드할 메시지 없음),
/// 첫 말풍선도 "새 메시지"로 판정돼 진입 애니메이션이 재생된다.
/// 따라서 빈/비어있지 않음 전환과 무관하게 이 뷰가 마운트를 유지하도록
/// 빈 상태 플레이스홀더도 여기서 렌더링한다.
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

    if (messages.isEmpty) {
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
              AppLocalizations.of(context)!.chatNoMessages,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.chatStartConversation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondaryColor.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

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
