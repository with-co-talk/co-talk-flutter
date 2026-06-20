import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../domain/entities/notification_settings.dart';
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
      backgroundColor: context.backgroundColor,
      body: BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (previous, current) =>
            current.status == NotificationSettingsStatus.error &&
            current.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        },
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
            padding: const EdgeInsets.only(top: 8),
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
                  _buildPreviewModeSelector(state),
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
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          child: Text(
            title,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _leadingChip(IconData icon, {Color? color}) {
    final accent = color ?? AppColors.primary;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }

  Widget _buildPreviewModeSelector(NotificationSettingsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _leadingChip(Icons.notifications_active_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '알림 미리보기',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              '알림에 표시할 내용을 선택합니다',
              style: TextStyle(
                fontSize: 12.5,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildRadioOption(
            title: '이름 + 메시지',
            subtitle: '보낸 사람 이름과 메시지 내용을 표시',
            value: NotificationPreviewMode.nameAndMessage,
            groupValue: state.settings.notificationPreviewMode,
          ),
          _buildRadioOption(
            title: '이름만',
            subtitle: '보낸 사람 이름만 표시',
            value: NotificationPreviewMode.nameOnly,
            groupValue: state.settings.notificationPreviewMode,
          ),
          _buildRadioOption(
            title: '표시 안함',
            subtitle: '이름과 메시지 내용 모두 숨김',
            value: NotificationPreviewMode.nothing,
            groupValue: state.settings.notificationPreviewMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required NotificationPreviewMode value,
    required NotificationPreviewMode groupValue,
  }) {
    return RadioListTile<NotificationPreviewMode>(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: context.textSecondaryColor,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: (newValue) {
        if (newValue != null) {
          context.read<NotificationSettingsCubit>().setNotificationPreviewMode(newValue);
        }
      },
      contentPadding: const EdgeInsets.only(left: 38),
      dense: true,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      secondary: _leadingChip(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: context.textSecondaryColor,
          ),
        ),
      ),
      value: value,
      onChanged: (v) {
        AppHaptics.selection();
        onChanged(v);
      },
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: _leadingChip(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: context.textPrimaryColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textSecondaryColor.withValues(alpha: 0.6),
          ),
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
