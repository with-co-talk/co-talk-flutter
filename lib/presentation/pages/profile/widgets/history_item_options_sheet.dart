import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/profile_history.dart';

/// 프로필 이력 항목 옵션 시트
/// 길게 눌렀을 때 표시되는 옵션들 (현재 프로필로 설정, 나만보기 토글, 삭제)
class HistoryItemOptionsSheet extends StatelessWidget {
  final ProfileHistory history;
  final bool isMyProfile;
  final VoidCallback? onSetCurrent;
  final VoidCallback? onTogglePrivacy;
  final VoidCallback? onDelete;

  const HistoryItemOptionsSheet({
    super.key,
    required this.history,
    required this.isMyProfile,
    this.onSetCurrent,
    this.onTogglePrivacy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

            // 날짜 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _formatDate(history.createdAt),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 현재 프로필로 설정 (현재 프로필이 아닐 때만)
            if (isMyProfile && !history.isCurrent)
              _OptionTile(
                icon: Icons.check_circle_outline,
                label: '현재 프로필로 설정',
                onTap: () {
                  Navigator.pop(context);
                  onSetCurrent?.call();
                },
              ),

            // 나만보기 토글
            if (isMyProfile)
              _OptionTile(
                icon: history.isPrivate ? Icons.visibility : Icons.visibility_off,
                label: history.isPrivate ? '공개로 변경' : '나만보기',
                onTap: () {
                  Navigator.pop(context);
                  onTogglePrivacy?.call();
                },
              ),

            // 삭제
            if (isMyProfile)
              _OptionTile(
                icon: Icons.delete_outline,
                label: '삭제',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text(
          history.isCurrent
              ? '현재 프로필로 사용 중입니다.\n삭제하면 이전 이력으로 변경됩니다.'
              : '이 이력을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}
