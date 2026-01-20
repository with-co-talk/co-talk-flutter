import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
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
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
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
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                _ProfileInfoCard(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.badge,
                      label: '상태',
                      value: _getStatusText(user.status),
                    ),
                    const Divider(),
                    _ProfileInfoRow(
                      icon: Icons.circle,
                      label: '온라인 상태',
                      value: _getOnlineStatusText(user.onlineStatus),
                      valueColor: _getOnlineStatusColor(user.onlineStatus),
                    ),
                    const Divider(),
                    _ProfileInfoRow(
                      icon: Icons.calendar_today,
                      label: '가입일',
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

  String _getStatusText(status) {
    switch (status.toString()) {
      case 'UserStatus.active':
        return '활성';
      case 'UserStatus.inactive':
        return '비활성';
      case 'UserStatus.suspended':
        return '정지됨';
      default:
        return '알 수 없음';
    }
  }

  String _getOnlineStatusText(onlineStatus) {
    switch (onlineStatus.toString()) {
      case 'OnlineStatus.online':
        return '온라인';
      case 'OnlineStatus.away':
        return '자리 비움';
      default:
        return '오프라인';
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

  String _formatDate(DateTime date) {
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
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
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
