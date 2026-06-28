import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Security configuration for certificate pinning and other security features
class SecurityConfig {
  SecurityConfig._();

  /// 자리표시자(placeholder) 핀 값. 실제 핀이 설정되지 않았음을 나타낸다.
  /// 이 값이 핀 목록에 남아 있으면 production-ready가 아니다.
  static const String placeholderPin =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Certificate pinning enabled flag
  /// Disabled in development for easier testing
  /// Should be enabled in production
  static bool get certificatePinningEnabled {
    // Disable certificate pinning in development/debug mode
    if (AppConfig.isDevelopment || kDebugMode) {
      return false;
    }
    // Enable in production
    return AppConfig.isProduction;
  }

  /// List of pinned certificate SHA-256 fingerprints (서버 인증서 DER의 SHA-256, hex).
  ///
  /// IMPORTANT: 프로덕션 배포 전에 placeholder 값을 실제 서버 인증서 지문으로 교체해야 한다.
  /// 인증서 로테이션을 지원하기 위해 여러 핀(현재 + 차기 인증서)을 함께 등록할 수 있다.
  ///
  /// 서버 인증서(전체 인증서)의 SHA-256(hex) 지문을 얻는 방법:
  /// ```bash
  /// openssl s_client -connect your-server.com:443 -servername your-server.com \
  ///   </dev/null 2>/dev/null \
  ///   | openssl x509 -outform der \
  ///   | openssl dgst -sha256 -hex
  /// ```
  ///
  /// 참고: 더 견고한 방식은 공개키(SPKI) 핀이지만, Dart의 X509Certificate는
  /// 공개키/SPKI를 직접 노출하지 않아(ASN.1 파싱 필요) 여기서는 인증서 전체
  /// DER의 SHA-256으로 핀을 비교한다. 인증서 로테이션 시 핀도 함께 갱신해야 한다.
  ///
  /// 실제 핀이 정해지면 환경별로 주입하거나 아래 목록을 교체한다.
  static const List<String> pinnedCertificates = [
    // TODO: 실제 서버 인증서 SHA-256(hex) 지문으로 교체. 예:
    // 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890',
    placeholderPin, // Placeholder — 실제 핀이 설정되지 않음
  ];

  /// 실제(비-placeholder) 핀이 하나라도 설정되어 있는지 여부.
  static bool get hasRealPin =>
      pinnedCertificates.any((p) => p.toLowerCase() != placeholderPin);

  /// 인증서 피닝이 실제로 동작 가능한 상태인지 여부.
  /// (피닝이 켜져 있고 실제 핀이 설정된 경우에만 true)
  static bool get isPinningActive => certificatePinningEnabled && hasRealPin;

  /// Validates if the configuration is production-ready.
  ///
  /// 피닝이 활성화(프로덕션)된 경우에는 실제 핀이 설정되어 있어야만 true.
  /// 자리표시자 핀만 있으면 보호가 전혀 없으므로 false(거짓 production-ready 신호 제거).
  static bool get isProductionReady {
    if (!certificatePinningEnabled) {
      // 개발/디버그: 피닝이 의도적으로 비활성화됨.
      return true;
    }
    // 프로덕션: 실제 핀이 설정되어 있을 때에만 production-ready.
    return hasRealPin;
  }

  /// Warning message for production deployment
  static String get productionWarning {
    if (isProductionReady) {
      return 'Security configuration is production-ready';
    }
    return 'WARNING: Certificate pinning is using placeholder certificates. '
        'Replace with actual server certificate fingerprints before production deployment.';
  }
}
