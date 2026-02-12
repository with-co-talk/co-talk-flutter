import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/notification_settings.dart';

part 'notification_settings_model.g.dart';

/// 알림 설정 모델 (API 응답/요청용)
@JsonSerializable()
class NotificationSettingsModel {
  final bool messageNotification;
  final bool friendRequestNotification;
  final bool groupInviteNotification;
  @JsonKey(name: 'notificationPreviewMode')
  final String notificationPreviewMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool doNotDisturbEnabled;
  final String? doNotDisturbStart;
  final String? doNotDisturbEnd;

  const NotificationSettingsModel({
    this.messageNotification = true,
    this.friendRequestNotification = true,
    this.groupInviteNotification = true,
    this.notificationPreviewMode = 'NAME_AND_MESSAGE',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsModelToJson(this);

  NotificationSettings toEntity() {
    return NotificationSettings(
      messageNotification: messageNotification,
      friendRequestNotification: friendRequestNotification,
      groupInviteNotification: groupInviteNotification,
      notificationPreviewMode: _parsePreviewMode(notificationPreviewMode),
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      doNotDisturbEnabled: doNotDisturbEnabled,
      doNotDisturbStart: doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd,
    );
  }

  factory NotificationSettingsModel.fromEntity(NotificationSettings entity) {
    return NotificationSettingsModel(
      messageNotification: entity.messageNotification,
      friendRequestNotification: entity.friendRequestNotification,
      groupInviteNotification: entity.groupInviteNotification,
      notificationPreviewMode: _previewModeToString(entity.notificationPreviewMode),
      soundEnabled: entity.soundEnabled,
      vibrationEnabled: entity.vibrationEnabled,
      doNotDisturbEnabled: entity.doNotDisturbEnabled,
      doNotDisturbStart: entity.doNotDisturbStart,
      doNotDisturbEnd: entity.doNotDisturbEnd,
    );
  }

  static NotificationPreviewMode _parsePreviewMode(String mode) {
    switch (mode) {
      case 'NAME_ONLY':
        return NotificationPreviewMode.nameOnly;
      case 'NOTHING':
        return NotificationPreviewMode.nothing;
      default:
        return NotificationPreviewMode.nameAndMessage;
    }
  }

  static String _previewModeToString(NotificationPreviewMode mode) {
    switch (mode) {
      case NotificationPreviewMode.nameOnly:
        return 'NAME_ONLY';
      case NotificationPreviewMode.nothing:
        return 'NOTHING';
      case NotificationPreviewMode.nameAndMessage:
        return 'NAME_AND_MESSAGE';
    }
  }
}
