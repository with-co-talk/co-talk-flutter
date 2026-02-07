import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

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
  int? _currentUserId;
  String? _currentDeviceType;

  NotificationRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._fcmService,
  );

  @override
  Future<void> registerToken({
    required int userId,
    required String deviceType,
  }) async {
    // FCM에서 토큰 발급
    final token = await _fcmService.getToken();
    if (token == null) {
      if (kDebugMode) {
        debugPrint('[NotificationRepository] FCM token is null, skipping registration');
      }
      return;
    }

    // 로컬에 토큰 저장
    await _localDataSource.saveFcmToken(token);

    // 서버에 토큰 등록 (userId는 JWT에서 추출)
    try {
      await _remoteDataSource.registerFcmToken(
        token: token,
        deviceType: deviceType,
      );
      if (kDebugMode) {
        debugPrint('[NotificationRepository] FCM token registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationRepository] Failed to register FCM token: $e');
      }
      // 서버 등록 실패해도 로컬에는 저장됨
    }
  }

  @override
  Future<void> refreshToken({
    required int userId,
    required String newToken,
    required String deviceType,
  }) async {
    // 로컬에 새 토큰 저장
    await _localDataSource.saveFcmToken(newToken);

    // 서버에 새 토큰 등록 (userId는 JWT에서 추출)
    try {
      await _remoteDataSource.registerFcmToken(
        token: newToken,
        deviceType: deviceType,
      );
      if (kDebugMode) {
        debugPrint('[NotificationRepository] FCM token refreshed and registered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationRepository] Failed to refresh FCM token: $e');
      }
    }
  }

  @override
  Future<void> unregisterToken() async {
    final token = await _localDataSource.getFcmToken();

    // 서버에서 토큰 삭제 시도
    if (token != null) {
      try {
        await _remoteDataSource.unregisterFcmToken(token: token);
        if (kDebugMode) {
          debugPrint('[NotificationRepository] FCM token unregistered from server');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[NotificationRepository] Failed to unregister FCM token: $e');
        }
        // 서버 삭제 실패해도 로컬은 정리
      }
    }

    // 로컬 토큰 삭제
    await _localDataSource.clearFcmToken();

    // FCM 토큰 삭제
    await _fcmService.deleteToken();
  }

  @override
  void setupTokenRefreshListener({
    required int userId,
    required String deviceType,
  }) {
    _currentUserId = userId;
    _currentDeviceType = deviceType;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcmService.onTokenRefresh.listen((newToken) {
      if (_currentUserId != null && _currentDeviceType != null) {
        refreshToken(
          userId: _currentUserId!,
          newToken: newToken,
          deviceType: _currentDeviceType!,
        );
      }
    });
  }

  @override
  void disposeTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _currentUserId = null;
    _currentDeviceType = null;
  }
}
