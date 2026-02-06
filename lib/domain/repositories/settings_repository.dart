import '../entities/notification_settings.dart';
import '../entities/chat_settings.dart';

/// 설정 관련 레포지토리 인터페이스
abstract class SettingsRepository {
  /// 알림 설정 조회
  Future<NotificationSettings> getNotificationSettings();

  /// 알림 설정 조회 (캐시 우선, 토글 직후 알림에 즉시 반영용)
  Future<NotificationSettings> getNotificationSettingsCached();

  /// 알림 설정 수정
  Future<void> updateNotificationSettings(NotificationSettings settings);

  /// 채팅 설정 조회
  Future<ChatSettings> getChatSettings();

  /// 채팅 설정 저장
  Future<void> saveChatSettings(ChatSettings settings);

  /// 캐시 삭제
  Future<void> clearCache();

  /// 회원 탈퇴
  Future<void> deleteAccount(int userId, String password);
}
