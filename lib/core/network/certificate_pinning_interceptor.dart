import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../config/security_config.dart';

/// 인증서 피닝 서비스.
///
/// SSL/TLS 인증서를 설정된 핀(서버 인증서 DER의 SHA-256 지문) 목록과 비교해
/// 중간자(MITM) 공격을 방지한다.
///
/// 사용 방식: [createPinnedHttpClient]가 반환하는 [HttpClient]를 Dio의
/// `IOHttpClientAdapter(createHttpClient: ...)`에 연결한다. 이렇게 해야
/// [HttpClient.badCertificateCallback]이 실제 TLS 핸드셰이크 검증에 사용된다.
/// (과거 구현은 Dio의 plain Interceptor로 등록되어 콜백이 호출되지 않는
/// 보안상 무의미한 코드였다.)
///
/// [SecurityConfig.isPinningActive]가 true일 때에만 실제 핀 검증을 수행한다.
@lazySingleton
class CertificatePinningService {
  const CertificatePinningService();

  /// 인증서 DER 바이트의 SHA-256 지문(소문자 hex)을 계산한다.
  static String sha256OfDer(List<int> der) {
    return sha256.convert(der).toString();
  }

  /// [cert]가 설정된 핀 중 하나와 일치하는지 검증한다.
  ///
  /// 피닝이 비활성(개발/디버그)이면 모든 인증서를 허용한다.
  /// 핀이 설정되지 않았으면(실제 핀 없음) 보호가 없으므로 거부한다.
  static bool isCertificateValid(X509Certificate cert) {
    if (!SecurityConfig.certificatePinningEnabled) {
      return true; // 개발/디버그: 핀 검증을 수행하지 않음
    }

    if (!SecurityConfig.hasRealPin) {
      if (kDebugMode) {
        debugPrint(
          'WARNING: Certificate pinning is enabled but no real pin is configured',
        );
      }
      return false;
    }

    final fingerprint = sha256OfDer(cert.der).toLowerCase();
    final isValid = SecurityConfig.pinnedCertificates
        .any((pin) => pin.toLowerCase() == fingerprint);

    if (!isValid && kDebugMode) {
      debugPrint('Certificate pinning failed for: ${cert.subject}');
      debugPrint('Presented SHA-256: $fingerprint');
    }

    return isValid;
  }

  /// 피닝이 적용된 [HttpClient]를 생성한다.
  ///
  /// [SecurityConfig.isPinningActive]가 true일 때에만
  /// [HttpClient.badCertificateCallback]을 설정해 핀 검증을 수행한다.
  /// 피닝이 비활성이면 기본 동작(시스템 신뢰 저장소)을 그대로 사용한다.
  HttpClient createPinnedHttpClient([HttpClient? client]) {
    final httpClient = client ?? HttpClient();
    if (SecurityConfig.isPinningActive) {
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return isCertificateValid(cert);
      };
    }
    return httpClient;
  }
}
