import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Floating action button that appears when scrolled up in chat room.
/// Shows badge with unread count when new messages arrive while scrolled.
class ScrollToBottomFab extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;
  final bool visible;

  const ScrollToBottomFab({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
