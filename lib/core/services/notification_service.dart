import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// 로컬 알림 서비스
///
/// 모든 플랫폼(Android/iOS/macOS/Windows/Linux)에서 로컬 알림을 표시합니다.
/// 데스크톱에서는 WebSocket 메시지 수신 시 로컬 알림으로 표시하고,
/// 모바일에서는 FCM 포그라운드 메시지를 로컬 알림으로 표시합니다.
@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  /// 알림 클릭 시 콜백
  final StreamController<String?> _notificationClickController =
      StreamController<String?>.broadcast();

  /// 알림 클릭 이벤트 스트림
  Stream<String?> get onNotificationClick => _notificationClickController.stream;

  // 알림 ID 카운터
  int _notificationIdCounter = 0;

  // Android 알림 채널 설정
  static const String _channelId = 'chat_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription = 'Notifications for new chat messages';

  NotificationService({required FlutterLocalNotificationsPlugin plugin})
      : _plugin = plugin;

  /// 알림 서비스 초기화
  ///
  /// 플랫폼별 초기화 설정을 수행합니다:
  /// - Android: 알림 채널 생성
  /// - iOS/macOS: 알림 권한 요청
  /// - Windows/Linux: 기본 설정
  Future<void> initialize() async {
    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux 설정
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Android 알림 채널 생성
    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // iOS/macOS 권한 요청
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _requestIOSPermissions();
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createAndroidNotificationChannel() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// iOS/macOS 알림 권한 요청
  Future<void> _requestIOSPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isMacOS) {
      final macOSPlugin =
          _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

      await macOSPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 알림 응답 핸들러
  void _onNotificationResponse(NotificationResponse response) {
    _notificationClickController.add(response.payload);
  }

  /// 알림 표시
  ///
  /// [title] 알림 제목
  /// [body] 알림 내용
  /// [payload] 알림 클릭 시 전달할 데이터
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final notificationId = _generateNotificationId();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const linuxDetails = LinuxNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// 고유한 알림 ID 생성
  int _generateNotificationId() {
    return _notificationIdCounter++;
  }

  /// 리소스 해제
  void dispose() {
    _notificationClickController.close();
  }
}
