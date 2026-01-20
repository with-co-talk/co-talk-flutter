import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: '알림',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '알림 설정',
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '일반',
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: '언어',
                subtitle: '한국어',
                onTap: () {
                  // TODO: Language selection
                },
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '다크 모드',
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    // TODO: Implement theme switching
                  },
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: '계정',
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: '비밀번호 변경',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              _SettingsTile(
                icon: Icons.block,
                title: '차단 관리',
                onTap: () {
                  // TODO: Navigate to block management
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '정보',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '앱 버전',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '이용약관',
                onTap: () {
                  // TODO: Navigate to terms
                },
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보 처리방침',
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('로그아웃'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
