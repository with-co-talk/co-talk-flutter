import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'notification_service.dart';

/// FCM 푸시 알림 서비스 인터페이스
///
/// 모바일: FcmServiceImpl (Firebase 사용)
/// 데스크톱: NoOpFcmService (더미 구현)
abstract class FcmService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  void dispose();
}

/// 데스크톱용 더미 FCM 서비스
///
/// 데스크톱에서는 FCM을 사용하지 않으므로 모든 메서드가 no-op입니다.
@LazySingleton(as: FcmService, env: [_desktopEnv])
class NoOpFcmService implements FcmService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  void dispose() {}
}

/// FCM 푸시 알림 서비스 구현 (현재 Android 전용)
///
/// Firebase Cloud Messaging을 통한 푸시 알림을 처리합니다.
/// - FCM 토큰 발급 및 갱신
/// - 포그라운드 메시지 처리 (로컬 알림으로 표시)
/// - 백그라운드 메시지 핸들러 설정
///
/// TODO: iOS 푸시 알림 활성화 필요
/// iOS 설정 필요사항:
/// 1. Apple Developer Program 유료 가입 ($99/년)
/// 2. Xcode > Signing & Capabilities > Push Notifications 추가
/// 3. Xcode > Signing & Capabilities > Background Modes > Remote notifications 체크
/// 4. Apple Developer > Keys에서 APNs 키 발급 (.p8 파일)
/// 5. Firebase Console > 프로젝트 설정 > 클라우드 메시징에 APNs 키 업로드
/// 6. main.dart와 이 파일에서 Platform.isIOS 조건 추가
@LazySingleton(as: FcmService, env: [_mobileEnv])
class FcmServiceImpl implements FcmService {
  final FirebaseMessaging _messaging;
  final NotificationService _notificationService;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  FcmServiceImpl({
    required FirebaseMessaging messaging,
    required NotificationService notificationService,
  })  : _messaging = messaging,
        _notificationService = notificationService;

  /// FCM 서비스 초기화
  ///
  /// 1. 알림 권한 요청
  /// 2. 초기 FCM 토큰 발급
  /// 3. 포그라운드 메시지 핸들러 설정
  @override
  Future<void> initialize() async {
    // 모바일 플랫폼에서만 동작
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    // 알림 권한 요청
    await _requestPermission();

    // 초기 토큰 발급
    await getToken();

    // 포그라운드 메시지 핸들러 설정
    _setupForegroundMessageHandler();
  }

  /// 알림 권한 요청
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ignore: avoid_print
    print('[FCM] Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// FCM 토큰 발급
  ///
  /// 발급된 토큰은 서버에 등록하여 푸시 알림을 수신할 수 있습니다.
  @override
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      // ignore: avoid_print
      print('[FCM] Token: $token');
      return token;
    } catch (e) {
      // ignore: avoid_print
      print('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출하여 토큰을 무효화합니다.
  @override
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    // ignore: avoid_print
    print('[FCM] Token deleted');
  }

  /// 토큰 갱신 스트림
  ///
  /// 토큰이 갱신될 때마다 새 토큰을 emit합니다.
  /// 토큰 갱신 시 서버에 새 토큰을 등록해야 합니다.
  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// 포그라운드 메시지 핸들러 설정
  void _setupForegroundMessageHandler() {
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      handleForegroundMessage(message);
    });
  }

  /// 포그라운드 메시지 처리
  ///
  /// 앱이 포그라운드에 있을 때 수신된 메시지를 로컬 알림으로 표시합니다.
  void handleForegroundMessage(RemoteMessage message) {
    // ignore: avoid_print
    print('[FCM] Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    // 메시지 데이터를 payload로 변환
    String? payload;
    if (message.data.isNotEmpty) {
      payload = jsonEncode(message.data);
    }

    _notificationService.showNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: payload,
    );
  }

  /// 리소스 해제
  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
  }
}

/// 백그라운드 메시지 핸들러
///
/// 앱이 백그라운드 또는 종료 상태일 때 FCM 메시지를 처리합니다.
/// main() 함수에서 FirebaseMessaging.onBackgroundMessage로 등록해야 합니다.
///
/// 중요: 이 함수는 top-level 함수여야 하며, 클래스 인스턴스에 의존하면 안 됩니다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print('[FCM] Background message received: ${message.messageId}');
  // 백그라운드 메시지는 시스템이 자동으로 알림을 표시합니다.
  // 추가적인 데이터 처리가 필요한 경우 여기에 로직을 추가합니다.
}

// 환경 상수
const _mobileEnv = 'mobile';
const _desktopEnv = 'desktop';
