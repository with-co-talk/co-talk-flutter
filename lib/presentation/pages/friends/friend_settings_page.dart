import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

class FriendSettingsPage extends StatelessWidget {
  const FriendSettingsPage({super.key});

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
        title: const Text(
          '친구 관리',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          _FriendSettingsSection(
            title: '친구 요청',
            children: [
              _FriendSettingsTile(
                icon: Icons.inbox,
                title: '받은 친구 요청',
                subtitle: '수락 대기 중인 요청을 확인하세요',
                onTap: () => context.push(AppRoutes.receivedRequests),
              ),
              _FriendSettingsTile(
                icon: Icons.send,
                title: '보낸 친구 요청',
                subtitle: '보낸 요청을 확인하세요',
                onTap: () => context.push(AppRoutes.sentRequests),
              ),
            ],
          ),
          _FriendSettingsSection(
            title: '친구 관리',
            children: [
              _FriendSettingsTile(
                icon: Icons.visibility_off,
                title: '숨김 친구 관리',
                subtitle: '숨긴 친구를 확인하세요',
                onTap: () => context.push(AppRoutes.hiddenFriends),
              ),
              _FriendSettingsTile(
                icon: Icons.block,
                title: '차단 사용자 관리',
                subtitle: '차단한 사용자를 관리하세요',
                onTap: () => context.push(AppRoutes.blockedUsers),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendSettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FriendSettingsSection({
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

class _FriendSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _FriendSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryColor,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: context.textSecondaryColor,
      ),
      onTap: onTap,
    );
  }
}
