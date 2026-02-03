import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/settings/notification_settings_cubit.dart';
import '../../blocs/settings/notification_settings_state.dart';

/// 알림 설정 페이지
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  /// 모바일 플랫폼 여부
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    context.read<NotificationSettingsCubit>().loadSettings();
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
              context.go(AppRoutes.settings);
            }
          },
        ),
        title: const Text('알림 설정'),
      ),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          if (state.status == NotificationSettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NotificationSettingsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? '오류가 발생했습니다',
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationSettingsCubit>().loadSettings();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              _buildSection(
                title: '알림 유형',
                children: [
                  _buildSwitchTile(
                    icon: Icons.message_outlined,
                    title: '메시지 알림',
                    subtitle: '새 메시지를 받을 때 알림',
                    value: state.settings.messageNotification,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setMessageNotification(value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.person_add_outlined,
                    title: '친구 요청 알림',
                    subtitle: '새 친구 요청을 받을 때 알림',
                    value: state.settings.friendRequestNotification,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setFriendRequestNotification(value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.group_add_outlined,
                    title: '그룹 초대 알림',
                    subtitle: '그룹 채팅에 초대받을 때 알림',
                    value: state.settings.groupInviteNotification,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setGroupInviteNotification(value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: '알림 방식',
                children: [
                  _buildSwitchTile(
                    icon: Icons.volume_up_outlined,
                    title: '소리',
                    subtitle: '알림 소리 재생',
                    value: state.settings.soundEnabled,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setSoundEnabled(value);
                    },
                  ),
                  // 진동 설정은 모바일에서만 표시
                  if (_isMobile)
                    _buildSwitchTile(
                      icon: Icons.vibration,
                      title: '진동',
                      subtitle: '알림 시 진동',
                      value: state.settings.vibrationEnabled,
                      onChanged: (value) {
                        context
                            .read<NotificationSettingsCubit>()
                            .setVibrationEnabled(value);
                      },
                    ),
                ],
              ),
              _buildSection(
                title: '방해 금지',
                children: [
                  _buildSwitchTile(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: '방해 금지 모드',
                    subtitle: '설정된 시간 동안 알림 무음',
                    value: state.settings.doNotDisturbEnabled,
                    onChanged: (value) {
                      context.read<NotificationSettingsCubit>().setDoNotDisturb(
                            enabled: value,
                          );
                    },
                  ),
                  if (state.settings.doNotDisturbEnabled) ...[
                    _buildTimeTile(
                      icon: Icons.access_time,
                      title: '시작 시간',
                      time: state.settings.doNotDisturbStart ?? '22:00',
                      onTap: () => _selectTime(context, true, state),
                    ),
                    _buildTimeTile(
                      icon: Icons.access_time_filled,
                      title: '종료 시간',
                      time: state.settings.doNotDisturbEnd ?? '07:00',
                      onTap: () => _selectTime(context, false, state),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    bool isStartTime,
    NotificationSettingsState state,
  ) async {
    final cubit = context.read<NotificationSettingsCubit>();
    final initialTime = _parseTime(
      isStartTime
          ? state.settings.doNotDisturbStart ?? '22:00'
          : state.settings.doNotDisturbEnd ?? '07:00',
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && mounted) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      if (isStartTime) {
        cubit.setDoNotDisturb(startTime: timeString);
      } else {
        cubit.setDoNotDisturb(endTime: timeString);
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
