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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(AppRoutes.editProfile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.profileViewPath(user.id));
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: user.avatarUrl != null
                              ? CachedNetworkImageProvider(
                                  user.avatarUrl!,
                                  maxWidth: 400,
                                )
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.nickname.isNotEmpty
                                      ? user.nickname[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user.nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                ),
                if (user.statusMessage != null && user.statusMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      user.statusMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _ProfileInfoCard(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.badge,
                      label: AppLocalizations.of(context)!.profileStatusLabel,
                      value: _getStatusText(context, user.status),
                    ),
                    const Divider(),
                    _ProfileInfoRow(
                      icon: Icons.circle,
                      label: AppLocalizations.of(context)!.profileOnlineStatusLabel,
                      value: _getOnlineStatusText(context, user.onlineStatus),
                      valueColor: _getOnlineStatusColor(user.onlineStatus),
                    ),
                    const Divider(),
                    _ProfileInfoRow(
                      icon: Icons.calendar_today,
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

class _ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileInfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.textSecondaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: context.textSecondaryColor),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
