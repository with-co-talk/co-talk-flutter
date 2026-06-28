import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context)!.profileEditTitle,
            onPressed: () {
              context.push(AppRoutes.editProfile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              children: [
                // ── 그라데이션 히어로 헤더 ──
                _ProfileHeader(
                  nickname: user.nickname,
                  email: user.email,
                  avatarUrl: user.avatarUrl,
                  statusMessage: user.statusMessage,
                  onTapAvatar: () =>
                      context.push(AppRoutes.profileViewPath(user.id)),
                ),
                const SizedBox(height: 24),
                // ── 정보 카드 ──
                _ProfileInfoCard(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      label: AppLocalizations.of(context)!.profileStatusLabel,
                      value: _getStatusText(context, user.status),
                    ),
                    const _RowDivider(),
                    _ProfileInfoRow(
                      icon: Icons.circle,
                      label: AppLocalizations.of(context)!
                          .profileOnlineStatusLabel,
                      value: _getOnlineStatusText(context, user.onlineStatus),
                      valueColor: _getOnlineStatusColor(user.onlineStatus),
                      iconColor: _getOnlineStatusColor(user.onlineStatus),
                    ),
                    const _RowDivider(),
                    _ProfileInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppLocalizations.of(context)!.profileJoinDateLabel,
                      value: _formatDate(user.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(BuildContext context, status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toString()) {
      case 'UserStatus.active':
        return l10n.profileStatusActive;
      case 'UserStatus.inactive':
        return l10n.profileStatusInactive;
      case 'UserStatus.suspended':
        return l10n.profileStatusSuspended;
      default:
        return l10n.profileStatusUnknown;
    }
  }

  String _getOnlineStatusText(BuildContext context, onlineStatus) {
    final l10n = AppLocalizations.of(context)!;
    switch (onlineStatus.toString()) {
      case 'OnlineStatus.online':
        return l10n.profileOnlineStatusOnline;
      case 'OnlineStatus.away':
        return l10n.profileOnlineStatusAway;
      default:
        return l10n.profileOnlineStatusOffline;
    }
  }

  Color _getOnlineStatusColor(onlineStatus) {
    switch (onlineStatus.toString()) {
      case 'OnlineStatus.online':
        return AppColors.online;
      case 'OnlineStatus.away':
        return AppColors.away;
      default:
        return AppColors.offline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

/// 그라데이션 틴트가 은은하게 깔린 프로필 히어로 헤더.
/// 큰 원형 아바타(브랜드 글로우) + 이름 + 이메일 + 상태메시지.
class _ProfileHeader extends StatelessWidget {
  final String nickname;
  final String email;
  final String? avatarUrl;
  final String? statusMessage;
  final VoidCallback onTapAvatar;

  const _ProfileHeader({
    required this.nickname,
    required this.email,
    required this.avatarUrl,
    required this.statusMessage,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            AppColors.primaryLight.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(
                            avatarUrl!,
                            maxWidth: 400,
                          )
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            nickname.isNotEmpty
                                ? nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.brandGradient,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.surfaceColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            nickname,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: context.textPrimaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              statusMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileInfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.dividerColor.withValues(alpha: 0.6),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.textPrimaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
