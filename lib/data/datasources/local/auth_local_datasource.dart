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
    final value = await _secureStorage.read(key: AppConstants.userIdKey);
    return value != null ? int.tryParse(value) : null;
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
