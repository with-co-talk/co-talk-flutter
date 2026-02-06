import 'package:equatable/equatable.dart';

/// 알림 설정 엔티티
class NotificationSettings extends Equatable {
  final bool messageNotification;
  final bool friendRequestNotification;
  final bool groupInviteNotification;
  /// 푸시 알림에 메시지 내용 노출 여부 (false면 "새 메시지"만 표시)
  final bool showMessageContentInNotification;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool doNotDisturbEnabled;
  final String? doNotDisturbStart; // "HH:mm" format
  final String? doNotDisturbEnd;   // "HH:mm" format

  const NotificationSettings({
    this.messageNotification = true,
    this.friendRequestNotification = true,
    this.groupInviteNotification = true,
    this.showMessageContentInNotification = true,
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
    bool? showMessageContentInNotification,
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
      showMessageContentInNotification: showMessageContentInNotification ?? this.showMessageContentInNotification,
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
        showMessageContentInNotification,
        soundEnabled,
        vibrationEnabled,
        doNotDisturbEnabled,
        doNotDisturbStart,
        doNotDisturbEnd,
      ];
}
