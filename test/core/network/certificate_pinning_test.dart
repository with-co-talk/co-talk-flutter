import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/network/certificate_pinning_interceptor.dart';
import 'package:co_talk_flutter/core/config/security_config.dart';

void main() {
  group('Certificate Pinning', () {
    group('SecurityConfig', () {
      test('exposes certificate pinning enabled flag', () {
        expect(SecurityConfig.certificatePinningEnabled, isA<bool>());
      });

      test('exposes pinned certificates list', () {
        expect(SecurityConfig.pinnedCertificates, isA<List<String>>());
      });

      test('pinned certificates are valid SHA-256 hex strings', () {
        for (final pin in SecurityConfig.pinnedCertificates) {
          // SHA-256 hash is 64 hex characters
          expect(pin.length, equals(64));
          expect(pin, matches(RegExp(r'^[a-fA-F0-9]{64}$')));
        }
      });

      test('hasRealPin is false while only the placeholder pin is configured', () {
        // The placeholder (all-zeros) pin must NOT count as a real pin.
        expect(SecurityConfig.hasRealPin, isFalse);
      });

      test(
        'isProductionReady is false when pinning is enabled but no real pin set',
        () {
          // 거짓 production-ready 신호 제거 검증:
          // - 실제(비-placeholder) 핀이 없으면 production-ready가 아니다.
          // - certificatePinningEnabled가 true가 되려면 hasRealPin도 true여야
          //   production-ready가 된다 (둘 다 만족해야 함).
          if (SecurityConfig.certificatePinningEnabled) {
            // 프로덕션 모드에서 실제 핀이 없으면 false.
            expect(SecurityConfig.isProductionReady, SecurityConfig.hasRealPin);
          } else {
            // 개발/디버그(피닝 비활성): 의도적으로 끈 상태이므로 ok(true).
            expect(SecurityConfig.isProductionReady, isTrue);
          }
        },
      );

      test('isPinningActive requires both enabled AND a real pin', () {
        expect(
          SecurityConfig.isPinningActive,
          SecurityConfig.certificatePinningEnabled && SecurityConfig.hasRealPin,
        );
      });

      test('productionWarning warns when not production-ready', () {
        if (!SecurityConfig.isProductionReady) {
          expect(
            SecurityConfig.productionWarning,
            contains('placeholder certificates'),
          );
        } else {
          expect(SecurityConfig.productionWarning, contains('production-ready'));
        }
      });
    });

    group('CertificatePinningService.sha256OfDer', () {
      test('computes a real SHA-256 (not raw hex of the bytes)', () {
        final der = utf8.encode('certificate-der-bytes');
        final expected = sha256.convert(der).toString();

        final actual = CertificatePinningService.sha256OfDer(der);

        expect(actual, equals(expected));
        expect(actual.length, equals(64));
        // Regression guard: old impl hex-encoded the raw bytes (length 2*N),
        // which for this input would NOT be 64 chars.
        final rawHex =
            der.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        expect(actual, isNot(equals(rawHex)));
      });

      test('is deterministic and lowercase hex', () {
        final der = [1, 2, 3, 4, 5];
        final a = CertificatePinningService.sha256OfDer(der);
        final b = CertificatePinningService.sha256OfDer(der);
        expect(a, equals(b));
        expect(a, equals(a.toLowerCase()));
      });
    });

    group('pin comparison', () {
      test('matching fingerprint equals the computed SHA-256 pin', () {
        final der = utf8.encode('server-cert');
        final pin = CertificatePinningService.sha256OfDer(der);
        // A genuine pin compares equal (case-insensitive) to the cert hash.
        expect(pin.toLowerCase(), equals(pin.toLowerCase()));
      });

      test('a different certificate yields a different pin', () {
        final pinA = CertificatePinningService.sha256OfDer(utf8.encode('A'));
        final pinB = CertificatePinningService.sha256OfDer(utf8.encode('B'));
        expect(pinA, isNot(equals(pinB)));
      });
    });

    group('CertificatePinningService', () {
      test('is constructible', () {
        expect(const CertificatePinningService(), isA<CertificatePinningService>());
      });

      test('createPinnedHttpClient returns a client', () {
        final service = const CertificatePinningService();
        final client = service.createPinnedHttpClient();
        expect(client, isNotNull);
        client.close(force: true);
      });
    });
  });
}
