/// 알림 저장소 인터페이스
///
/// FCM 토큰 생명주기 관리를 담당합니다:
/// - 토큰 등록 (로그인 시)
/// - 토큰 갱신 (FCM에서 갱신 시)
/// - 토큰 삭제 (로그아웃 시)
abstract class NotificationRepository {
  /// FCM 토큰 등록
  ///
  /// 1. FCM에서 토큰 발급
  /// 2. 로컬 저장소에 토큰 저장
  /// 3. 서버에 토큰 등록
  ///
  /// [userId] 사용자 ID
  /// [deviceType] 'ANDROID' 또는 'IOS'
  Future<void> registerToken({
    required int userId,
    required String deviceType,
  });

  /// FCM 토큰 갱신
  ///
  /// 토큰이 갱신되면 서버에 새 토큰을 등록합니다.
  ///
  /// [userId] 사용자 ID
  /// [newToken] 새로 발급된 FCM 토큰
  /// [deviceType] 'ANDROID' 또는 'IOS'
  Future<void> refreshToken({
    required int userId,
    required String newToken,
    required String deviceType,
  });

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출하여 토큰을 무효화합니다.
  /// 1. 서버에서 토큰 삭제
  /// 2. 로컬 저장소에서 토큰 삭제
  /// 3. FCM 토큰 삭제
  Future<void> unregisterToken();

  /// 토큰 갱신 리스너 설정
  ///
  /// FCM 토큰이 갱신될 때 자동으로 서버에 재등록합니다.
  ///
  /// [userId] 사용자 ID
  /// [deviceType] 'ANDROID' 또는 'IOS'
  void setupTokenRefreshListener({
    required int userId,
    required String deviceType,
  });

  /// 토큰 갱신 리스너 해제
  void disposeTokenRefreshListener();
}
