import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUserId(int userId);
  Future<int?> getUserId();
  Future<void> saveUserEmail(String email);
  Future<String?> getUserEmail();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      ),
      _secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.accessTokenKey),
      _secureStorage.delete(key: AppConstants.refreshTokenKey),
      _secureStorage.delete(key: AppConstants.userIdKey),
      _secureStorage.delete(key: AppConstants.userEmailKey),
    ]);
  }

  @override
  Future<void> saveUserId(int userId) async {
    await _secureStorage.write(
      key: AppConstants.userIdKey,
      value: userId.toString(),
    );
  }

  @override
  Future<int?> getUserId() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.userIdKey);
      if (value == null) {
        return null;
      }
      
      final userId = int.tryParse(value);
      if (userId == null) {
        // 잘못된 형식의 데이터가 저장된 경우 로깅 (향후 로깅 시스템 도입 시)
        // logger.w('Invalid userId format stored: $value');
        // 잘못된 데이터 삭제
        await _secureStorage.delete(key: AppConstants.userIdKey);
        return null;
      }
      
      return userId;
    } catch (e) {
      // 저장소 읽기 실패 시 null 반환
      return null;
    }
  }

  @override
  Future<void> saveUserEmail(String email) async {
    await _secureStorage.write(
      key: AppConstants.userEmailKey,
      value: email,
    );
  }

  @override
  Future<String?> getUserEmail() async {
    return _secureStorage.read(key: AppConstants.userEmailKey);
  }
}
