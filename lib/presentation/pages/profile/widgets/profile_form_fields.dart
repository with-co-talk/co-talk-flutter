import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../handlers/profile_submit_handler.dart';

class ProfileFormFields extends StatelessWidget {
  final TextEditingController nicknameController;
  final TextEditingController statusMessageController;
  final String email;

  const ProfileFormFields({
    super.key,
    required this.nicknameController,
    required this.statusMessageController,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nickname card
        _buildEditCard(
          context: context,
          icon: Icons.person,
          label: '닉네임',
          child: TextFormField(
            controller: nicknameController,
            decoration: InputDecoration(
              hintText: '닉네임을 입력하세요',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              isDense: false,
              errorStyle: const TextStyle(
                fontSize: 12,
                height: 1.0,
              ),
              errorMaxLines: 2,
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: context.textPrimaryColor,
            ),
            validator: ProfileSubmitHandler.validateNickname,
          ),
        ),

        const SizedBox(height: 12),

        // Status message card
        _buildEditCard(
          context: context,
          icon: Icons.chat_bubble_outline,
          label: '상태메시지',
          child: TextFormField(
            controller: statusMessageController,
            decoration: InputDecoration(
              hintText: '상태메시지를 입력하세요 (선택)',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              isDense: false,
              counterText: '',
            ),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: context.textPrimaryColor,
            ),
            maxLength: 60,
            maxLines: 2,
            minLines: 1,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusMessageController.text.length > 50
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${statusMessageController.text.length}/60',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusMessageController.text.length > 50
                    ? AppColors.warning
                    : AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Account info section
        Text(
          '계정 정보',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Email (read-only)
        _buildInfoCard(
          context: context,
          icon: Icons.email,
          label: '이메일',
          value: email,
        ),
      ],
    );
  }

  Widget _buildEditCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.dividerColor,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.dividerColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: context.textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.dividerColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 12, color: context.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  '수정불가',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
