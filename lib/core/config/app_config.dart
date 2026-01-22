import 'package:flutter/foundation.dart';

/// 앱 환경 설정
class AppConfig {
  AppConfig._();

  /// 현재 환경 (dev, staging, prod)
  static const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  /// 프로덕션 환경 여부
  static bool get isProduction => environment == 'prod';

  /// 개발 환경 여부
  static bool get isDevelopment => environment == 'dev';

  /// 스테이징 환경 여부
  static bool get isStaging => environment == 'staging';

  /// 디버그 모드 여부 (kDebugMode + 개발 환경)
  static bool get isDebugMode => kDebugMode && !isProduction;

  /// 상세 로깅 활성화 여부
  static bool get enableVerboseLogging => isDebugMode;

  /// 네트워크 요청/응답 바디 로깅 여부
  static bool get enableNetworkBodyLogging => isDebugMode;
}
