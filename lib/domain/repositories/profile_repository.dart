import '../entities/profile_history.dart';
import '../entities/user.dart';

abstract class ProfileRepository {
  /// 사용자 프로필 조회
  Future<User> getUserById(int userId);
  /// 프로필 이력 목록 조회
  Future<List<ProfileHistory>> getProfileHistory(
    int userId, {
    ProfileHistoryType? type,
  });

  /// 프로필 이력 생성
  Future<ProfileHistory> createProfileHistory({
    required int userId,
    required ProfileHistoryType type,
    String? url,
    String? content,
    bool isPrivate = false,
    bool setCurrent = true,
  });

  /// 프로필 이력 수정 (나만보기 토글)
  Future<void> updateProfileHistory(
    int userId,
    int historyId, {
    required bool isPrivate,
  });

  /// 프로필 이력 삭제
  Future<void> deleteProfileHistory(int userId, int historyId);

  /// 현재 프로필로 설정
  Future<void> setCurrentProfile(int userId, int historyId);
}
