import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/desktop_notification_bridge.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Korean locale
  await initializeDateFormatting('ko_KR', null);

  // Initialize Firebase (Android only for now)
  // TODO: iOS 푸시 알림 활성화 시 Platform.isIOS 조건 추가 필요
  // iOS 설정 필요사항:
  // 1. Apple Developer Program 유료 가입
  // 2. Xcode에서 Push Notifications capability 추가
  // 3. Xcode에서 Background Modes > Remote notifications 추가
  // 4. APNs 인증 키 발급 후 Firebase Console에 업로드
  if (!kIsWeb && Platform.isAndroid) {
    await Firebase.initializeApp();
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize dependency injection
  await configureDependencies();

  // Initialize notification services
  await _initializeNotifications();

  // Desktop window configuration
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
      minimumSize: Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConstants.appName,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const CoTalkApp());
}

/// 알림 서비스 초기화
///
/// - 모든 플랫폼: 로컬 알림 서비스 초기화
/// - 모바일(Android): FCM 서비스 초기화
/// - 데스크톱: WebSocket 메시지 → 로컬 알림 브릿지 초기화
Future<void> _initializeNotifications() async {
  // 로컬 알림 서비스 초기화 (모든 플랫폼)
  final notificationService = getIt<NotificationService>();
  await notificationService.initialize();

  // FCM 서비스 초기화 (Android만 - iOS는 Apple Developer 유료 가입 후 활성화)
  // TODO: iOS 푸시 알림 활성화 시 Platform.isIOS 조건 추가
  if (!kIsWeb && Platform.isAndroid) {
    final fcmService = getIt<FcmService>();
    await fcmService.initialize();
  }

  // 데스크톱 알림 브릿지 초기화 (WebSocket → 로컬 알림)
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    final desktopNotificationBridge = getIt<DesktopNotificationBridge>();
    desktopNotificationBridge.startListening();
  }
}
