// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSettingsModel _$ChatSettingsModelFromJson(
  Map<String, dynamic> json,
) => ChatSettingsModel(
  fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
  autoDownloadImagesOnWifi: json['autoDownloadImagesOnWifi'] as bool? ?? true,
  autoDownloadImagesOnMobile:
      json['autoDownloadImagesOnMobile'] as bool? ?? false,
  autoDownloadVideosOnWifi: json['autoDownloadVideosOnWifi'] as bool? ?? true,
  autoDownloadVideosOnMobile:
      json['autoDownloadVideosOnMobile'] as bool? ?? false,
);

Map<String, dynamic> _$ChatSettingsModelToJson(ChatSettingsModel instance) =>
    <String, dynamic>{
      'fontSize': instance.fontSize,
      'autoDownloadImagesOnWifi': instance.autoDownloadImagesOnWifi,
      'autoDownloadImagesOnMobile': instance.autoDownloadImagesOnMobile,
      'autoDownloadVideosOnWifi': instance.autoDownloadVideosOnWifi,
      'autoDownloadVideosOnMobile': instance.autoDownloadVideosOnMobile,
    };
