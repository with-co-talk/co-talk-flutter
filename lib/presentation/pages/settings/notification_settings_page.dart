import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.settingsNotificationSettings),
      ),
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
                    state.errorMessage ?? AppLocalizations.of(context)!.settingsErrorOccurred,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationSettingsCubit>().loadSettings();
                    },
                    child: Text(AppLocalizations.of(context)!.commonRetry),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              _buildSection(
                title: AppLocalizations.of(context)!.settingsNotificationType,
                children: [
                  _buildSwitchTile(
                    icon: Icons.message_outlined,
                    title: AppLocalizations.of(context)!.settingsMessageNotification,
                    subtitle: AppLocalizations.of(context)!.settingsMessageNotificationDesc,
                    value: state.settings.messageNotification,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setMessageNotification(value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.person_add_outlined,
                    title: AppLocalizations.of(context)!.settingsFriendRequestNotification,
                    subtitle: AppLocalizations.of(context)!.settingsFriendRequestNotificationDesc,
                    value: state.settings.friendRequestNotification,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .setFriendRequestNotification(value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.group_add_outlined,
                    title: AppLocalizations.of(context)!.settingsGroupInviteNotification,
                    subtitle: AppLocalizations.of(context)!.settingsGroupInviteNotificationDesc,
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
                title: AppLocalizations.of(context)!.settingsNotificationMethod,
                children: [
                  _buildPreviewModeSelector(state),
                  _buildSwitchTile(
                    icon: Icons.volume_up_outlined,
                    title: AppLocalizations.of(context)!.settingsSound,
                    subtitle: AppLocalizations.of(context)!.settingsSoundDesc,
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
                      title: AppLocalizations.of(context)!.settingsVibration,
                      subtitle: AppLocalizations.of(context)!.settingsVibrationDesc,
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
                title: AppLocalizations.of(context)!.settingsDoNotDisturb,
                children: [
                  _buildSwitchTile(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: AppLocalizations.of(context)!.settingsDoNotDisturbMode,
                    subtitle: AppLocalizations.of(context)!.settingsDoNotDisturbDesc,
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
                      title: AppLocalizations.of(context)!.settingsStartTime,
                      time: state.settings.doNotDisturbStart ?? '22:00',
                      onTap: () => _selectTime(context, true, state),
                    ),
                    _buildTimeTile(
                      icon: Icons.access_time_filled,
                      title: AppLocalizations.of(context)!.settingsEndTime,
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

  Widget _buildPreviewModeSelector(NotificationSettingsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.settingsNotificationPreview,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.settingsNotificationPreviewDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          RadioGroup<NotificationPreviewMode>(
            groupValue: state.settings.notificationPreviewMode,
            onChanged: (newValue) {
              if (newValue != null) {
                context
                    .read<NotificationSettingsCubit>()
                    .setNotificationPreviewMode(newValue);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadioOption(
                  title: AppLocalizations.of(context)!.settingsPreviewNameAndMessage,
                  subtitle: AppLocalizations.of(context)!.settingsPreviewNameAndMessageDesc,
                  value: NotificationPreviewMode.nameAndMessage,
                ),
                _buildRadioOption(
                  title: AppLocalizations.of(context)!.settingsPreviewNameOnly,
                  subtitle: AppLocalizations.of(context)!.settingsPreviewNameOnlyDesc,
                  value: NotificationPreviewMode.nameOnly,
                ),
                _buildRadioOption(
                  title: AppLocalizations.of(context)!.settingsPreviewNothing,
                  subtitle: AppLocalizations.of(context)!.settingsPreviewNothingDesc,
                  value: NotificationPreviewMode.nothing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required NotificationPreviewMode value,
  }) {
    return RadioListTile<NotificationPreviewMode>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
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
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
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
