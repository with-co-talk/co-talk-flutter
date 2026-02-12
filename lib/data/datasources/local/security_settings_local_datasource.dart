import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// 보안 설정 로컬 데이터소스
///
/// 생체 인증 ON/OFF 상태를 SecureStorage에 저장합니다.
@lazySingleton
class SecuritySettingsLocalDataSource {
  static const _biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _secureStorage;

  SecuritySettingsLocalDataSource(this._secureStorage);

  /// 생체 인증 활성화 여부 조회
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// 생체 인증 활성화 여부 저장
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }
}
