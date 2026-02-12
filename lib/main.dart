import 'dart:io';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/desktop_notification_bridge.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_click_handler.dart';
import 'core/services/notification_service.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Release 모드에서도 에러를 캐치하기 위한 글로벌 에러 핸들러
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log to console but don't crash
      debugPrint('Flutter error: ${details.exception}');
    }
  };

  // Catch non-Flutter errors (e.g., async errors outside Flutter framework)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error');
    return true;
  };

  try {
    // Initialize date formatting for Korean locale
    await initializeDateFormatting('ko_KR', null);

    // Initialize Firebase (Android and iOS)
    // iOS 설정 필요사항:
    // 1. Apple Developer Program 유료 가입
    // 2. Xcode에서 Push Notifications capability 추가
    // 3. Xcode에서 Background Modes > Remote notifications 추가
    // 4. APNs 인증 키 발급 후 Firebase Console에 업로드
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Firebase.initializeApp();

      // Firebase App Check 활성화 (앱 위변조 방지)
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );

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
  } catch (e, stackTrace) {
    debugPrint('App initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // 에러 발생 시에도 앱을 표시하여 사용자가 문제를 인지할 수 있도록 함
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App initialization failed:\n$e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
  }
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

  // 알림 클릭 핸들러 초기화 (모든 플랫폼)
  // 알림 클릭 시 해당 채팅방으로 네비게이션
  final notificationClickHandler = getIt<NotificationClickHandler>();
  notificationClickHandler.startListening();

  // 딥링크 서비스 초기화 (모바일에서만 - 데스크톱은 딥링크 불필요)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final deepLinkService = getIt<DeepLinkService>();
    await deepLinkService.init();
  }

  // FCM 서비스 초기화 (Android 및 iOS)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final fcmService = getIt<FcmService>();
    await fcmService.initialize();

    // FCM 알림 클릭 시 채팅방으로 네비게이션
    fcmService.onNotificationClick.listen((payload) {
      if (payload != null) {
        notificationClickHandler.handleFcmNotificationClick(payload);
      }
    });
  }

  // 데스크톱 알림 브릿지 초기화 (WebSocket → 로컬 알림)
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    final desktopNotificationBridge = getIt<DesktopNotificationBridge>();
    desktopNotificationBridge.startListening();
  }
}
