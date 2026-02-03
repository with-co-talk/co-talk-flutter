import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../core/window/window_focus_tracker.dart';
import '../data/datasources/local/database/app_database.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

// 환경 상수 (fcm_service.dart와 동일)
const mobileEnv = 'mobile';
const desktopEnv = 'desktop';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // 플랫폼에 따라 환경 결정
  final environment = _determineEnvironment();

  // 모바일 환경에서는 FirebaseMessaging을 먼저 수동으로 등록
  // (Firebase.initializeApp()이 완료된 후에 호출되므로 안전함)
  if (environment == mobileEnv) {
    getIt.registerLazySingleton<FirebaseMessaging>(
      () => FirebaseMessaging.instance,
    );
  }

  getIt.init(environment: environment);
}

String _determineEnvironment() {
  if (kIsWeb) {
    return desktopEnv; // 웹은 FCM 미지원으로 desktop 환경 사용
  }
  // Android 및 iOS는 FCM 지원 (mobile 환경)
  if (Platform.isAndroid || Platform.isIOS) {
    return mobileEnv;
  }
  return desktopEnv; // iOS, macOS, Windows, Linux
}

@module
abstract class RegisterModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        // macOS: 명시적 accountName 설정으로 중복 키 에러 방지
        mOptions: MacOsOptions(
          accountName: 'co_talk_flutter',
          accessibility: KeychainAccessibility.unlocked,
        ),
      );

  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      FlutterLocalNotificationsPlugin();

  // FirebaseMessaging은 configureDependencies()에서 수동으로 등록됨
  // (Firebase.initializeApp() 이후에 안전하게 등록하기 위함)

  @lazySingleton
  WindowFocusTracker get windowFocusTracker => WindowFocusTracker.platform();
}
