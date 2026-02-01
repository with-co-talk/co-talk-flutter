import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../core/utils/error_message_mapper.dart';
import 'notification_settings_state.dart';

/// 알림 설정 Cubit
///
/// 알림 설정을 관리하고 백엔드 API와 동기화합니다.
@lazySingleton
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final SettingsRepository _repository;

  NotificationSettingsCubit(this._repository)
      : super(const NotificationSettingsState.initial());

  /// 알림 설정 로드
  Future<void> loadSettings() async {
    emit(const NotificationSettingsState.loading());
    try {
      final settings = await _repository.getNotificationSettings();
      emit(NotificationSettingsState.loaded(settings));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(NotificationSettingsState.error(message));
    }
  }

  /// 메시지 알림 설정 변경
  Future<void> setMessageNotification(bool value) async {
    await _updateSetting(state.settings.copyWith(messageNotification: value));
  }

  /// 친구 요청 알림 설정 변경
  Future<void> setFriendRequestNotification(bool value) async {
    await _updateSetting(state.settings.copyWith(friendRequestNotification: value));
  }

  /// 그룹 초대 알림 설정 변경
  Future<void> setGroupInviteNotification(bool value) async {
    await _updateSetting(state.settings.copyWith(groupInviteNotification: value));
  }

  /// 소리 설정 변경
  Future<void> setSoundEnabled(bool value) async {
    await _updateSetting(state.settings.copyWith(soundEnabled: value));
  }

  /// 진동 설정 변경
  Future<void> setVibrationEnabled(bool value) async {
    await _updateSetting(state.settings.copyWith(vibrationEnabled: value));
  }

  /// 방해 금지 모드 설정 변경
  Future<void> setDoNotDisturb({
    bool? enabled,
    String? startTime,
    String? endTime,
  }) async {
    await _updateSetting(state.settings.copyWith(
      doNotDisturbEnabled: enabled,
      doNotDisturbStart: startTime,
      doNotDisturbEnd: endTime,
    ));
  }

  /// 설정 업데이트 공통 메서드
  Future<void> _updateSetting(NotificationSettings newSettings) async {
    final previousSettings = state.settings;

    // Optimistic update
    emit(state.copyWith(settings: newSettings));

    try {
      await _repository.updateNotificationSettings(newSettings);
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(settings: previousSettings));
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(NotificationSettingsState.error(message));
      // Restore to loaded state with previous settings
      emit(state.copyWith(
        status: NotificationSettingsStatus.loaded,
        settings: previousSettings,
      ));
    }
  }
}
