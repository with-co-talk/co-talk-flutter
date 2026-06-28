import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class FriendSettingsPage extends StatelessWidget {
  const FriendSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
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
        title: Text(
          AppLocalizations.of(context)!.friendSettingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.4,
          ),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _FriendSettingsSection(
            title: AppLocalizations.of(context)!.friendSettingsRequestSection,
            children: [
              _FriendSettingsTile(
                icon: Icons.inbox_rounded,
                title: AppLocalizations.of(context)!.friendSettingsReceivedRequests,
                subtitle: AppLocalizations.of(context)!.friendSettingsReceivedRequestsDesc,
                onTap: () => context.push(AppRoutes.receivedRequests),
              ),
              _FriendSettingsTile(
                icon: Icons.send_rounded,
                title: AppLocalizations.of(context)!.friendSettingsSentRequests,
                subtitle: AppLocalizations.of(context)!.friendSettingsSentRequestsDesc,
                onTap: () => context.push(AppRoutes.sentRequests),
              ),
            ],
          ),
          _FriendSettingsSection(
            title: AppLocalizations.of(context)!.friendSettingsManageSection,
            children: [
              _FriendSettingsTile(
                icon: Icons.visibility_off_rounded,
                title: AppLocalizations.of(context)!.friendSettingsHiddenFriends,
                subtitle: AppLocalizations.of(context)!.friendSettingsHiddenFriendsDesc,
                onTap: () => context.push(AppRoutes.hiddenFriends),
              ),
              _FriendSettingsTile(
                icon: Icons.block_rounded,
                title: AppLocalizations.of(context)!.friendSettingsBlockedUsers,
                subtitle: AppLocalizations.of(context)!.friendSettingsBlockedUsersDesc,
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
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: context.textSecondaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: context.dividerColor,
                    ),
                  ),
                children[i],
              ],
            ],
          ),
        ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.textSecondaryColor,
      ),
      onTap: onTap,
    );
  }
}
