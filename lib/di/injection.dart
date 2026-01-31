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
  getIt.init(environment: environment);
}

String _determineEnvironment() {
  if (kIsWeb) {
    return desktopEnv; // 웹은 FCM 미지원으로 desktop 환경 사용
  }
  // Android만 FCM 지원 (iOS는 APNs 설정 필요)
  // TODO: iOS APNs 설정 완료 후 Platform.isIOS 추가
  if (Platform.isAndroid) {
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
        mOptions: MacOsOptions(),
      );

  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      FlutterLocalNotificationsPlugin();

  // FirebaseMessaging은 모바일 환경에서만 등록 (FcmServiceImpl이 직접 사용)
  @lazySingleton
  @Environment(mobileEnv)
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @lazySingleton
  WindowFocusTracker get windowFocusTracker => WindowFocusTracker.platform();
}
