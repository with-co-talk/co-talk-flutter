import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// FCM 토큰 로컬 저장소 인터페이스
abstract class NotificationLocalDataSource {
  /// FCM 토큰 저장
  Future<void> saveFcmToken(String token);

  /// FCM 토큰 조회
  Future<String?> getFcmToken();

  /// FCM 토큰 삭제
  Future<void> clearFcmToken();

  /// 디바이스 ID 저장
  Future<void> saveDeviceId(String deviceId);

  /// 디바이스 ID 조회
  Future<String?> getDeviceId();
}

@LazySingleton(as: NotificationLocalDataSource)
class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  static const String _fcmTokenKey = 'fcm_token';
  static const String _deviceIdKey = 'device_id';

  NotificationLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveFcmToken(String token) async {
    await _secureStorage.write(key: _fcmTokenKey, value: token);
  }

  @override
  Future<String?> getFcmToken() async {
    return _secureStorage.read(key: _fcmTokenKey);
  }

  @override
  Future<void> clearFcmToken() async {
    await _secureStorage.delete(key: _fcmTokenKey);
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    return _secureStorage.read(key: _deviceIdKey);
  }
}
