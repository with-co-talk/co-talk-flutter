import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/app_haptics.dart';
import '../../domain/entities/message.dart';

/// Displays reactions under a message bubble.
/// Groups reactions by emoji and shows count.
class ReactionDisplay extends StatelessWidget {
  final List<MessageReaction> reactions;
  final int currentUserId;
  final bool isMe;
  final void Function(String emoji) onReactionTap;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.isMe,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final grouped = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Padding(
        padding: EdgeInsets.only(
          top: 4,
          left: isMe ? 0 : 44, // Align with message bubble (after avatar)
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
          children: grouped.entries.map((entry) {
            final emoji = entry.key;
            final reactionList = entry.value;
            final count = reactionList.length;
            final hasMyReaction = reactionList.any(
              (r) => r.userId == currentUserId,
            );

            return GestureDetector(
              onTap: () {
                AppHaptics.selection();
                onReactionTap(emoji);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: hasMyReaction
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasMyReaction
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : context.dividerColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    if (count > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasMyReaction
                              ? AppColors.primary
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
