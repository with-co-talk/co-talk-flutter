import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/fcm_service.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local/notification_local_datasource.dart';
import '../datasources/remote/notification_remote_datasource.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource _localDataSource;
  final NotificationRemoteDataSource _remoteDataSource;
  final FcmService _fcmService;

  StreamSubscription<String>? _tokenRefreshSubscription;

  NotificationRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._fcmService,
  );

  @override
  Future<void> registerToken({required String platform}) async {
    // FCM에서 토큰 발급
    final token = await _fcmService.getToken();
    if (token == null) {
      // ignore: avoid_print
      print('[NotificationRepository] FCM token is null, skipping registration');
      return;
    }

    // 디바이스 ID 확인 또는 생성
    var deviceId = await _localDataSource.getDeviceId();
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _localDataSource.saveDeviceId(deviceId);
    }

    // 로컬에 토큰 저장
    await _localDataSource.saveFcmToken(token);

    // 서버에 토큰 등록
    try {
      await _remoteDataSource.registerFcmToken(
        token: token,
        platform: platform,
        deviceId: deviceId,
      );
      // ignore: avoid_print
      print('[NotificationRepository] FCM token registered successfully');
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationRepository] Failed to register FCM token: $e');
      // 서버 등록 실패해도 로컬에는 저장됨
    }
  }

  @override
  Future<void> refreshToken({
    required String newToken,
    required String platform,
  }) async {
    // 디바이스 ID 확인
    var deviceId = await _localDataSource.getDeviceId();
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _localDataSource.saveDeviceId(deviceId);
    }

    // 로컬에 새 토큰 저장
    await _localDataSource.saveFcmToken(newToken);

    // 서버에 새 토큰 등록
    try {
      await _remoteDataSource.registerFcmToken(
        token: newToken,
        platform: platform,
        deviceId: deviceId,
      );
      // ignore: avoid_print
      print('[NotificationRepository] FCM token refreshed and registered');
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationRepository] Failed to refresh FCM token: $e');
    }
  }

  @override
  Future<void> unregisterToken() async {
    final deviceId = await _localDataSource.getDeviceId();

    // 서버에서 토큰 삭제 시도
    if (deviceId != null) {
      try {
        await _remoteDataSource.unregisterFcmToken(deviceId: deviceId);
        // ignore: avoid_print
        print('[NotificationRepository] FCM token unregistered from server');
      } catch (e) {
        // ignore: avoid_print
        print('[NotificationRepository] Failed to unregister FCM token: $e');
        // 서버 삭제 실패해도 로컬은 정리
      }
    }

    // 로컬 토큰 삭제
    await _localDataSource.clearFcmToken();

    // FCM 토큰 삭제
    await _fcmService.deleteToken();
  }

  @override
  void setupTokenRefreshListener({required String platform}) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcmService.onTokenRefresh.listen((newToken) {
      refreshToken(newToken: newToken, platform: platform);
    });
  }

  @override
  void disposeTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
