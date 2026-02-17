import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart' hide NotificationSettings;
import 'package:firebase_messaging/firebase_messaging.dart' as fcm show NotificationSettings;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'active_room_tracker.dart';
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
  /// FCM 알림 클릭 이벤트 스트림 (payload)
  Stream<String?> get onNotificationClick;
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
  Stream<String?> get onNotificationClick => const Stream.empty();

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
  final SettingsRepository _settingsRepository;
  final ActiveRoomTracker _activeRoomTracker;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  final StreamController<String?> _notificationClickController = StreamController<String?>.broadcast();

  FcmServiceImpl({
    required FirebaseMessaging messaging,
    required NotificationService notificationService,
    required SettingsRepository settingsRepository,
    required ActiveRoomTracker activeRoomTracker,
  })  : _messaging = messaging,
        _notificationService = notificationService,
        _settingsRepository = settingsRepository,
        _activeRoomTracker = activeRoomTracker;

  /// FCM 서비스 초기화
  ///
  /// 1. 알림 권한 요청
  /// 2. 초기 FCM 토큰 발급
  /// 3. 포그라운드 메시지 핸들러 설정
  /// 4. 알림 탭 핸들러 설정 (백그라운드/종료 상태)
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

    // 알림 탭 핸들러 설정 (백그라운드/종료 상태에서 알림 클릭 시)
    _setupNotificationTapHandlers();
  }

  /// 알림 권한 요청
  Future<fcm.NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    }
    return settings;
  }

  /// FCM 토큰 발급
  ///
  /// 발급된 토큰은 서버에 등록하여 푸시 알림을 수신할 수 있습니다.
  @override
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      // Do not log token - sensitive data
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Failed to get token: $e');
      }
      return null;
    }
  }

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출하여 토큰을 무효화합니다.
  @override
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    if (kDebugMode) {
      debugPrint('[FCM] Token deleted');
    }
  }

  /// 토큰 갱신 스트림
  ///
  /// 토큰이 갱신될 때마다 새 토큰을 emit합니다.
  /// 토큰 갱신 시 서버에 새 토큰을 등록해야 합니다.
  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// FCM 알림 클릭 이벤트 스트림
  @override
  Stream<String?> get onNotificationClick => _notificationClickController.stream;

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
  /// 설정에서 '푸시 메시지 내용 표시'가 꺼져 있으면 본문은 '새 메시지'로 표시합니다.
  void handleForegroundMessage(RemoteMessage message) {
    _handleForegroundMessageAsync(message);
  }

  Future<void> _handleForegroundMessageAsync(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
    }

    // Suppress notification if the user is currently viewing this chat room
    final chatRoomIdStr = message.data['chatRoomId'];
    if (chatRoomIdStr != null) {
      final chatRoomId = int.tryParse(chatRoomIdStr);
      final activeRoom = _activeRoomTracker.activeRoomId;
      if (kDebugMode) {
        debugPrint('[FCM] Foreground message: chatRoomId=$chatRoomId, activeRoomId=$activeRoom');
      }
      if (chatRoomId != null && chatRoomId == activeRoom) {
        if (kDebugMode) {
          debugPrint('[FCM] Suppressing notification for active room: $chatRoomId');
        }
        return;
      }
    }

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    NotificationPreviewMode previewMode = NotificationPreviewMode.nameAndMessage;
    bool soundEnabled = true;
    bool vibrationEnabled = true;
    try {
      final settings = await _settingsRepository.getNotificationSettingsCached();
      previewMode = settings.notificationPreviewMode;
      soundEnabled = settings.soundEnabled;
      vibrationEnabled = settings.vibrationEnabled;
    } catch (_) {}

    String title;
    String body;
    switch (previewMode) {
      case NotificationPreviewMode.nameAndMessage:
        title = notification.title ?? '새 메시지';
        body = notification.body ?? '';
      case NotificationPreviewMode.nameOnly:
        title = notification.title ?? '새 메시지';
        body = '새 메시지';
      case NotificationPreviewMode.nothing:
        title = '새 메시지';
        body = '새 메시지가 도착했습니다';
    }

    // 알림 탭 시 해당 채팅방으로 이동할 수 있도록 payload 형식: 'chatRoom:roomId'
    String? payload;
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null) {
      payload = 'chatRoom:$chatRoomId';
    } else if (message.data.isNotEmpty) {
      payload = jsonEncode(message.data);
    }

    // FCM data에서 발신자 아바타 URL 추출
    final avatarUrl = message.data['avatarUrl'];

    await _notificationService.showNotification(
      title: title,
      body: body,
      payload: payload,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      avatarUrl: avatarUrl,
    );
  }

  /// 알림 탭 핸들러 설정
  ///
  /// 백그라운드/종료 상태에서 FCM 알림을 탭했을 때 처리합니다.
  void _setupNotificationTapHandlers() {
    // 앱이 종료 상태에서 알림으로 실행된 경우
    _messaging.getInitialMessage().then(_handleNotificationTap);

    // 앱이 백그라운드에서 알림을 탭한 경우
    _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// 알림 탭 처리
  ///
  /// FCM 메시지 데이터에서 chatRoomId를 추출하여 네비게이션 payload로 변환합니다.
  void _handleNotificationTap(RemoteMessage? message) {
    if (message == null) return;

    if (kDebugMode) {
      debugPrint('[FCM] Notification tapped: ${message.messageId}');
      debugPrint('[FCM] Data: ${message.data}');
    }

    // 채팅방 ID 추출 (서버에서 보내는 data 형식에 맞춤)
    final chatRoomIdStr = message.data['chatRoomId'];
    if (chatRoomIdStr != null) {
      final chatRoomId = int.tryParse(chatRoomIdStr);
      if (chatRoomId != null) {
        // NotificationClickHandler와 동일한 payload 형식 사용
        _notificationClickController.add('chatRoom:$chatRoomId');
      }
    }
  }

  /// 리소스 해제
  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    _notificationClickController.close();
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
  if (kDebugMode) {
    debugPrint('[FCM] Background message received: ${message.messageId}');
  }
  // 백그라운드 메시지는 시스템이 자동으로 알림을 표시합니다.
  // 추가적인 데이터 처리가 필요한 경우 여기에 로직을 추가합니다.
}

// 환경 상수
const _mobileEnv = 'mobile';
const _desktopEnv = 'desktop';
