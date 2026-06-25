import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
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
              context.go(AppRoutes.friends);
            }
          },
        ),
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      body: ListView(
        children: [
          // 프로필 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsProfile,
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return _SettingsTile(
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(context)!.settingsMyProfile,
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
            title: AppLocalizations.of(context)!.settingsNotification,
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: AppLocalizations.of(context)!.settingsNotificationSettings,
                subtitle: AppLocalizations.of(context)!.settingsNotificationDesc,
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          // 채팅 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsChat,
            children: [
              _SettingsTile(
                icon: Icons.chat_outlined,
                title: AppLocalizations.of(context)!.settingsChatSettings,
                subtitle: AppLocalizations.of(context)!.settingsChatDesc,
                onTap: () => context.push(AppRoutes.chatSettings),
              ),
            ],
          ),
          // 친구 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsFriends,
            children: [
              _SettingsTile(
                icon: Icons.people_outline,
                title: AppLocalizations.of(context)!.settingsFriendManagement,
                subtitle: AppLocalizations.of(context)!.settingsFriendManagementDesc,
                onTap: () => context.push(AppRoutes.friendSettings),
              ),
            ],
          ),
          // 일반 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsGeneral,
            children: [
              // 언어 설정: 현재 한국어만 지원하므로 설정 변경 불가
              _SettingsTile(
                icon: Icons.language,
                title: AppLocalizations.of(context)!.settingsLanguage,
                subtitle: AppLocalizations.of(context)!.settingsLanguageKorean,
              ),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = context.read<ThemeCubit>().isDarkMode(context);
                  return _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: AppLocalizations.of(context)!.settingsDarkMode,
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        AppHaptics.selection();
                        context.read<ThemeCubit>().toggleDarkMode(value);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          // 보안 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsSecurity,
            children: [
              _SettingsTile(
                icon: Icons.fingerprint,
                title: AppLocalizations.of(context)!.settingsBiometric,
                subtitle: AppLocalizations.of(context)!.settingsBiometricDesc,
                onTap: () => context.push(AppRoutes.securitySettings),
              ),
            ],
          ),
          // 계정 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsAccount,
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: AppLocalizations.of(context)!.settingsChangePassword,
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              _SettingsTile(
                icon: Icons.person_remove_outlined,
                title: AppLocalizations.of(context)!.settingsAccountDeletion,
                titleColor: AppColors.error,
                onTap: () => context.push(AppRoutes.accountDeletion),
              ),
            ],
          ),
          // 정보 섹션
          _SettingsSection(
            title: AppLocalizations.of(context)!.settingsInfo,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: AppLocalizations.of(context)!.settingsAppVersion,
                subtitle: _version,
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context)!.settingsTerms,
                onTap: () => context.push(AppRoutes.terms),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: AppLocalizations.of(context)!.settingsPrivacyPolicy,
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _SettingsTile(
                icon: Icons.code,
                title: AppLocalizations.of(context)!.settingsOpenSourceLicense,
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
              child: Text(AppLocalizations.of(context)!.settingsLogout),
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
        title: Text(AppLocalizations.of(context)!.settingsLogout),
        content: Text(AppLocalizations.of(context)!.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.settingsLogout),
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
