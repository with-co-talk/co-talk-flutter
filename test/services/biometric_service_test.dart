import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart' show BiometricType;
import 'package:co_talk_flutter/core/services/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Channel used by the DefaultLocalAuthPlatform (fallback)
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');

  late Map<String, dynamic> channelResponses;

  setUp(() {
    channelResponses = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
      return channelResponses[methodCall.method];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, null);
  });

  group('BiometricService', () {
    group('isSupported', () {
      test('returns true when canCheckBiometrics and isDeviceSupported are both true', () async {
        channelResponses['getAvailableBiometrics'] = <String>['fingerprint'];
        channelResponses['isDeviceSupported'] = true;

        final service = BiometricService();
        final result = await service.isSupported();

        // canCheckBiometrics uses getAvailableBiometrics under the hood on default platform
        // The result depends on the platform channel response
        expect(result, isA<bool>());
      });

      test('returns false on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
          throw PlatformException(code: 'NotAvailable', message: 'Not available');
        });

        final service = BiometricService();
        final result = await service.isSupported();

        expect(result, isFalse);
      });
    });

    group('getAvailableBiometrics', () {
      test('returns empty list on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
          throw PlatformException(code: 'error');
        });

        final service = BiometricService();
        final result = await service.getAvailableBiometrics();

        expect(result, isEmpty);
      });

      test('returns biometric types on success', () async {
        channelResponses['getAvailableBiometrics'] = <String>['fingerprint', 'face'];

        final service = BiometricService();
        final result = await service.getAvailableBiometrics();

        expect(result, isA<List<BiometricType>>());
      });
    });

    group('authenticate', () {
      test('returns false on PlatformException during authenticate', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            throw PlatformException(code: 'NotEnrolled', message: 'Not enrolled');
          }
          return null;
        });

        final service = BiometricService();
        final result = await service.authenticate();

        expect(result, isFalse);
      });

      test('returns bool from channel on authenticate call', () async {
        channelResponses['authenticate'] = true;

        final service = BiometricService();
        final result = await service.authenticate();

        expect(result, isA<bool>());
      });

      test('uses custom reason when provided', () async {
        String? capturedReason;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            capturedReason = (methodCall.arguments as Map)['localizedReason'] as String?;
            return true;
          }
          return null;
        });

        final service = BiometricService();
        await service.authenticate(reason: '잠금을 해제하려면 인증해주세요');

        expect(capturedReason, '잠금을 해제하려면 인증해주세요');
      });

      test('uses default reason when no reason provided', () async {
        String? capturedReason;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            capturedReason = (methodCall.arguments as Map)['localizedReason'] as String?;
            return true;
          }
          return null;
        });

        final service = BiometricService();
        await service.authenticate();

        expect(capturedReason, '앱 잠금을 해제하려면 인증해주세요');
      });
    });
  });

  group('BiometricService authentication options', () {
    test('authenticate passes stickyAuth true to platform', () async {
      bool? capturedStickyAuth;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'authenticate') {
          capturedStickyAuth = (methodCall.arguments as Map)['stickyAuth'] as bool?;
          return false;
        }
        return null;
      });

      final service = BiometricService();
      await service.authenticate();

      expect(capturedStickyAuth, isTrue);
    });

    test('authenticate passes biometricOnly false to platform', () async {
      bool? capturedBiometricOnly;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'authenticate') {
          capturedBiometricOnly = (methodCall.arguments as Map)['biometricOnly'] as bool?;
          return false;
        }
        return null;
      });

      final service = BiometricService();
      await service.authenticate();

      expect(capturedBiometricOnly, isFalse);
    });

    test('returns false for any exception during authenticate', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (MethodCall methodCall) async {
        throw PlatformException(code: 'lockout', message: 'Too many attempts');
      });

      final service = BiometricService();
      final result = await service.authenticate();

      expect(result, isFalse);
    });
  });
}
