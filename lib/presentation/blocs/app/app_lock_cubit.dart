import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/datasources/local/security_settings_local_datasource.dart';
import 'app_lock_state.dart';

/// 앱 잠금 Cubit
///
/// 앱이 백그라운드에서 복귀할 때 생체 인증 잠금을 관리합니다.
/// 생체 인증 활성화 상태를 캐시하여 resume 시 동기적으로 잠금할 수 있습니다.
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  final BiometricService _biometricService;
  final SecuritySettingsLocalDataSource _securitySettings;

  DateTime? _lastAuthenticatedAt;

  /// 생체 인증 활성화 상태 캐시 (SecureStorage 비동기 읽기 없이 즉시 잠금 가능)
  bool _cachedBiometricEnabled = false;

  /// 캐시가 한 번이라도 로드되었는지 여부
  bool _cacheLoaded = false;

  /// 인증 유효 시간 (30초)
  static const _authGracePeriod = Duration(seconds: 30);

  AppLockCubit(
    this._biometricService,
    this._securitySettings,
  ) : super(const AppLockState.unlocked());

  /// 생체 인증 활성화 여부 (캐시된 값)
  bool get isBiometricEnabled => _cachedBiometricEnabled;

  /// 캐시를 SecureStorage에서 동기화
  Future<void> _refreshCache() async {
    _cachedBiometricEnabled = await _securitySettings.isBiometricEnabled();
    _cacheLoaded = true;
  }

  /// 앱 복귀 시 잠금 체크
  ///
  /// 캐시된 값으로 먼저 동기적으로 잠금하고, 이후 SecureStorage와 동기화합니다.
  /// 이를 통해 키보드 requestFocus보다 잠금이 먼저 실행됩니다.
  Future<void> checkLockOnResume() async {
    // 1단계: 캐시된 값으로 즉시 판단 (동기적)
    if (_cacheLoaded && _cachedBiometricEnabled) {
      if (_isWithinGracePeriod()) return;
      emit(const AppLockState.locked());
      return;
    }

    // 2단계: 캐시가 없으면 SecureStorage에서 읽기 (비동기)
    await _refreshCache();
    if (!_cachedBiometricEnabled) return;

    if (_isWithinGracePeriod()) return;

    emit(const AppLockState.locked());
  }

  /// 앱 최초 실행 시 잠금 체크 (grace period 무시)
  Future<void> checkLockOnLaunch() async {
    await _refreshCache();
    if (!_cachedBiometricEnabled) return;

    emit(const AppLockState.locked());
  }

  /// grace period 내인지 확인
  bool _isWithinGracePeriod() {
    if (_lastAuthenticatedAt != null) {
      final elapsed = DateTime.now().difference(_lastAuthenticatedAt!);
      if (elapsed < _authGracePeriod) return true;
    }
    return false;
  }

  /// 생체 인증 시도
  Future<void> authenticate() async {
    emit(const AppLockState.authenticating());

    final success = await _biometricService.authenticate();
    if (success) {
      _lastAuthenticatedAt = DateTime.now();
      emit(const AppLockState.unlocked());
    } else {
      emit(const AppLockState.locked());
    }
  }

  /// 인증 성공으로 잠금 해제 (수동)
  void unlock() {
    _lastAuthenticatedAt = DateTime.now();
    emit(const AppLockState.unlocked());
  }

  /// 생체 인증 활성화 상태 캐시 업데이트
  ///
  /// 설정 변경 시 호출하여 캐시를 동기화합니다.
  void updateBiometricEnabledCache(bool enabled) {
    _cachedBiometricEnabled = enabled;
    _cacheLoaded = true;
    if (kDebugMode) {
      debugPrint('[AppLockCubit] Biometric cache updated: $enabled');
    }
  }
}
