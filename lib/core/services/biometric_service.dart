import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// 생체 인증 서비스
///
/// 디바이스의 생체 인증(지문, Face ID 등) 기능을 래핑합니다.
@lazySingleton
class BiometricService {
  final LocalAuthentication _localAuth;

  BiometricService() : _localAuth = LocalAuthentication();

  /// 디바이스가 생체 인증을 지원하는지 확인
  Future<bool> isSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[BiometricService] isSupported error: $e');
      }
      return false;
    }
  }

  /// 사용 가능한 생체 인증 유형 목록
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      }
      return [];
    }
  }

  /// 생체 인증 요청
  Future<bool> authenticate({String reason = '앱 잠금을 해제하려면 인증해주세요'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[BiometricService] authenticate error: $e');
      }
      return false;
    }
  }
}
