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
                color: Colors.grey[400],
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
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
                color: Colors.grey[400],
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
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            maxLength: 60,
            maxLines: 2,
            minLines: 1,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusMessageController.text.length > 50
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${statusMessageController.text.length}/60',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: statusMessageController.text.length > 50
                    ? Colors.orange[700]
                    : Colors.grey[500],
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
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey[200]!,
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[500]),
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
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '수정불가',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
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
