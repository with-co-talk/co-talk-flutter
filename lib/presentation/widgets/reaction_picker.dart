import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Quick reaction picker shown on long press.
/// Shows common emojis for quick selection.
class ReactionPicker extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback onMorePressed;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onMorePressed,
  });

  static const List<String> quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...quickEmojis.map((emoji) => _EmojiButton(
                emoji: emoji,
                onTap: () => onEmojiSelected(emoji),
              )),
          const SizedBox(width: 4),
          _MoreButton(onTap: onMorePressed),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            size: 20,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
