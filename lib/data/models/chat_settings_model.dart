import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/chat_settings.dart';

part 'chat_settings_model.g.dart';

/// 채팅 설정 모델 (SharedPreferences 저장용)
@JsonSerializable()
class ChatSettingsModel {
  final double fontSize;
  final bool autoDownloadImagesOnWifi;
  final bool autoDownloadImagesOnMobile;
  final bool autoDownloadVideosOnWifi;
  final bool autoDownloadVideosOnMobile;

  const ChatSettingsModel({
    this.fontSize = 1.0,
    this.autoDownloadImagesOnWifi = true,
    this.autoDownloadImagesOnMobile = false,
    this.autoDownloadVideosOnWifi = true,
    this.autoDownloadVideosOnMobile = false,
  });

  factory ChatSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSettingsModelToJson(this);

  ChatSettings toEntity() {
    return ChatSettings(
      fontSize: fontSize,
      autoDownloadImagesOnWifi: autoDownloadImagesOnWifi,
      autoDownloadImagesOnMobile: autoDownloadImagesOnMobile,
      autoDownloadVideosOnWifi: autoDownloadVideosOnWifi,
      autoDownloadVideosOnMobile: autoDownloadVideosOnMobile,
    );
  }

  factory ChatSettingsModel.fromEntity(ChatSettings entity) {
    return ChatSettingsModel(
      fontSize: entity.fontSize,
      autoDownloadImagesOnWifi: entity.autoDownloadImagesOnWifi,
      autoDownloadImagesOnMobile: entity.autoDownloadImagesOnMobile,
      autoDownloadVideosOnWifi: entity.autoDownloadVideosOnWifi,
      autoDownloadVideosOnMobile: entity.autoDownloadVideosOnMobile,
    );
  }
}
