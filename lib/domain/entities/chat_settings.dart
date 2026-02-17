import 'package:equatable/equatable.dart';

/// 채팅 설정 엔티티
class ChatSettings extends Equatable {
  final double fontSize; // 0.8 ~ 1.4 (textScaleFactor)
  final bool autoDownloadImagesOnWifi;
  final bool autoDownloadImagesOnMobile;
  final bool autoDownloadVideosOnWifi;
  final bool autoDownloadVideosOnMobile;
  final bool showTypingIndicator; // 입력중 표시 (기본: 꺼짐)

  const ChatSettings({
    this.fontSize = 1.0,
    this.autoDownloadImagesOnWifi = true,
    this.autoDownloadImagesOnMobile = false,
    this.autoDownloadVideosOnWifi = true,
    this.autoDownloadVideosOnMobile = false,
    this.showTypingIndicator = false,
  });

  ChatSettings copyWith({
    double? fontSize,
    bool? autoDownloadImagesOnWifi,
    bool? autoDownloadImagesOnMobile,
    bool? autoDownloadVideosOnWifi,
    bool? autoDownloadVideosOnMobile,
    bool? showTypingIndicator,
  }) {
    return ChatSettings(
      fontSize: fontSize ?? this.fontSize,
      autoDownloadImagesOnWifi: autoDownloadImagesOnWifi ?? this.autoDownloadImagesOnWifi,
      autoDownloadImagesOnMobile: autoDownloadImagesOnMobile ?? this.autoDownloadImagesOnMobile,
      autoDownloadVideosOnWifi: autoDownloadVideosOnWifi ?? this.autoDownloadVideosOnWifi,
      autoDownloadVideosOnMobile: autoDownloadVideosOnMobile ?? this.autoDownloadVideosOnMobile,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
    );
  }

  @override
  List<Object?> get props => [
        fontSize,
        autoDownloadImagesOnWifi,
        autoDownloadImagesOnMobile,
        autoDownloadVideosOnWifi,
        autoDownloadVideosOnMobile,
        showTypingIndicator,
      ];
}
