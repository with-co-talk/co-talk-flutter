import 'package:equatable/equatable.dart';

/// 채팅 설정 엔티티
class ChatSettings extends Equatable {
  final double fontSize; // 0.8 ~ 1.4 (textScaleFactor)
  final bool autoDownloadImagesOnWifi;
  final bool autoDownloadImagesOnMobile;
  final bool autoDownloadVideosOnWifi;
  final bool autoDownloadVideosOnMobile;

  const ChatSettings({
    this.fontSize = 1.0,
    this.autoDownloadImagesOnWifi = true,
    this.autoDownloadImagesOnMobile = false,
    this.autoDownloadVideosOnWifi = true,
    this.autoDownloadVideosOnMobile = false,
  });

  ChatSettings copyWith({
    double? fontSize,
    bool? autoDownloadImagesOnWifi,
    bool? autoDownloadImagesOnMobile,
    bool? autoDownloadVideosOnWifi,
    bool? autoDownloadVideosOnMobile,
  }) {
    return ChatSettings(
      fontSize: fontSize ?? this.fontSize,
      autoDownloadImagesOnWifi: autoDownloadImagesOnWifi ?? this.autoDownloadImagesOnWifi,
      autoDownloadImagesOnMobile: autoDownloadImagesOnMobile ?? this.autoDownloadImagesOnMobile,
      autoDownloadVideosOnWifi: autoDownloadVideosOnWifi ?? this.autoDownloadVideosOnWifi,
      autoDownloadVideosOnMobile: autoDownloadVideosOnMobile ?? this.autoDownloadVideosOnMobile,
    );
  }

  @override
  List<Object?> get props => [
        fontSize,
        autoDownloadImagesOnWifi,
        autoDownloadImagesOnMobile,
        autoDownloadVideosOnWifi,
        autoDownloadVideosOnMobile,
      ];
}
