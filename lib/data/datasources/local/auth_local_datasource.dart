import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    await _writeWithRetry(AppConstants.accessTokenKey, accessToken);
    await _writeWithRetry(AppConstants.refreshTokenKey, refreshToken);
  }

  /// macOS/iOS Keychain 중복 키 에러(-25299) 처리
  /// 에러 발생 시 삭제 후 재시도, 그래도 실패 시 전체 삭제 후 재시도
  Future<void> _writeWithRetry(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      // -25299: errSecDuplicateItem (이미 존재하는 항목)
      if (e.code == 'Unexpected security result code' ||
          e.message?.contains('-25299') == true) {
        try {
          await _secureStorage.delete(key: key);
          await _secureStorage.write(key: key, value: value);
        } on PlatformException {
          // 그래도 실패 시 전체 키체인 초기화 후 재시도
          if (kDebugMode) {
            debugPrint('[AuthLocalDataSource] Keychain error - clearing all and retrying');
          }
          await _secureStorage.deleteAll();
          await _secureStorage.write(key: key, value: value);
        }
      } else {
        rethrow;
      }
    }
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
