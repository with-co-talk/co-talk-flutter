// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettingsModel _$NotificationSettingsModelFromJson(
  Map<String, dynamic> json,
) => NotificationSettingsModel(
  messageNotification: json['messageNotification'] as bool? ?? true,
  friendRequestNotification: json['friendRequestNotification'] as bool? ?? true,
  groupInviteNotification: json['groupInviteNotification'] as bool? ?? true,
  showMessageContentInNotification: json['showMessageContentInNotification'] as bool? ?? true,
  soundEnabled: json['soundEnabled'] as bool? ?? true,
  vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
  doNotDisturbEnabled: json['doNotDisturbEnabled'] as bool? ?? false,
  doNotDisturbStart: json['doNotDisturbStart'] as String?,
  doNotDisturbEnd: json['doNotDisturbEnd'] as String?,
);

Map<String, dynamic> _$NotificationSettingsModelToJson(
  NotificationSettingsModel instance,
) => <String, dynamic>{
  'messageNotification': instance.messageNotification,
  'friendRequestNotification': instance.friendRequestNotification,
  'groupInviteNotification': instance.groupInviteNotification,
  'showMessageContentInNotification': instance.showMessageContentInNotification,
  'soundEnabled': instance.soundEnabled,
  'vibrationEnabled': instance.vibrationEnabled,
  'doNotDisturbEnabled': instance.doNotDisturbEnabled,
  'doNotDisturbStart': instance.doNotDisturbStart,
  'doNotDisturbEnd': instance.doNotDisturbEnd,
};
