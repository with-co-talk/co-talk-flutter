import 'package:equatable/equatable.dart';

/// 알림 미리보기 모드
enum NotificationPreviewMode {
  /// 이름과 메시지 내용 모두 표시
  nameAndMessage,
  /// 이름만 표시
  nameOnly,
  /// 이름과 메시지 모두 숨김
  nothing,
}

/// 알림 설정 엔티티
class NotificationSettings extends Equatable {
  final bool messageNotification;
  final bool friendRequestNotification;
  final bool groupInviteNotification;
  /// 알림 미리보기 모드 (이름+메시지, 이름만, 표시 안함)
  final NotificationPreviewMode notificationPreviewMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool doNotDisturbEnabled;
  final String? doNotDisturbStart; // "HH:mm" format
  final String? doNotDisturbEnd;   // "HH:mm" format

  const NotificationSettings({
    this.messageNotification = true,
    this.friendRequestNotification = true,
    this.groupInviteNotification = true,
    this.notificationPreviewMode = NotificationPreviewMode.nameAndMessage,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  NotificationSettings copyWith({
    bool? messageNotification,
    bool? friendRequestNotification,
    bool? groupInviteNotification,
    NotificationPreviewMode? notificationPreviewMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? doNotDisturbEnabled,
    String? doNotDisturbStart,
    String? doNotDisturbEnd,
  }) {
    return NotificationSettings(
      messageNotification: messageNotification ?? this.messageNotification,
      friendRequestNotification: friendRequestNotification ?? this.friendRequestNotification,
      groupInviteNotification: groupInviteNotification ?? this.groupInviteNotification,
      notificationPreviewMode: notificationPreviewMode ?? this.notificationPreviewMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
    );
  }

  @override
  List<Object?> get props => [
        messageNotification,
        friendRequestNotification,
        groupInviteNotification,
        notificationPreviewMode,
        soundEnabled,
        vibrationEnabled,
        doNotDisturbEnabled,
        doNotDisturbStart,
        doNotDisturbEnd,
      ];
}
