import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/theme/theme_cubit.dart';

/// 설정 페이지
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.chatList);
            }
          },
        ),
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 프로필 섹션
          _SettingsSection(
            title: '프로필',
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return _SettingsTile(
                    icon: Icons.person_outline,
                    title: '내 프로필',
                    subtitle: state.user?.nickname ?? '',
                    onTap: () {
                      final userId = state.user?.id;
                      if (userId != null) {
                        context.push(AppRoutes.profileViewPath(userId));
                      }
                    },
                  );
                },
              ),
            ],
          ),
          // 알림 섹션
          _SettingsSection(
            title: '알림',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '알림 설정',
                subtitle: '메시지, 친구 요청, 그룹 초대 알림',
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          // 채팅 섹션
          _SettingsSection(
            title: '채팅',
            children: [
              _SettingsTile(
                icon: Icons.chat_outlined,
                title: '채팅 설정',
                subtitle: '글꼴 크기, 미디어 자동 다운로드',
                onTap: () => context.push(AppRoutes.chatSettings),
              ),
            ],
          ),
          // 친구 섹션
          _SettingsSection(
            title: '친구',
            children: [
              _SettingsTile(
                icon: Icons.people_outline,
                title: '친구 관리',
                subtitle: '친구 요청, 숨김, 차단 관리',
                onTap: () => context.push(AppRoutes.friendSettings),
              ),
            ],
          ),
          // 일반 섹션
          _SettingsSection(
            title: '일반',
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: '언어',
                subtitle: '한국어',
              ),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = context.read<ThemeCubit>().isDarkMode(context);
                  return _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: '다크 모드',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleDarkMode(value);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          // 계정 섹션
          _SettingsSection(
            title: '계정',
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: '비밀번호 변경',
                subtitle: '준비 중 (서버 API 구현 필요)',
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              _SettingsTile(
                icon: Icons.person_remove_outlined,
                title: '회원 탈퇴',
                titleColor: AppColors.error,
                onTap: () => context.push(AppRoutes.accountDeletion),
              ),
            ],
          ),
          // 정보 섹션
          _SettingsSection(
            title: '정보',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '앱 버전',
                subtitle: _version,
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '이용약관',
                onTap: () => context.push(AppRoutes.terms),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보 처리방침',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _SettingsTile(
                icon: Icons.code,
                title: '오픈소스 라이선스',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Co-Talk',
                  applicationVersion: _version,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 로그아웃 버튼
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
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: titleColor != null
            ? TextStyle(color: titleColor)
            : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
