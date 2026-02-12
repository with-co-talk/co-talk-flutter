import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/datasources/local/security_settings_local_datasource.dart';
import 'app_lock_state.dart';

/// 앱 잠금 Cubit
///
/// 앱이 백그라운드에서 복귀할 때 생체 인증 잠금을 관리합니다.
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  final BiometricService _biometricService;
  final SecuritySettingsLocalDataSource _securitySettings;

  DateTime? _lastAuthenticatedAt;

  /// 인증 유효 시간 (30초)
  static const _authGracePeriod = Duration(seconds: 30);

  AppLockCubit(
    this._biometricService,
    this._securitySettings,
  ) : super(const AppLockState.unlocked());

  /// 앱 복귀 시 잠금 체크
  Future<void> checkLockOnResume() async {
    final isEnabled = await _securitySettings.isBiometricEnabled();
    if (!isEnabled) return;

    // 마지막 인증 후 30초 이내면 잠금 안 함
    if (_lastAuthenticatedAt != null) {
      final elapsed = DateTime.now().difference(_lastAuthenticatedAt!);
      if (elapsed < _authGracePeriod) return;
    }

    emit(const AppLockState.locked());
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
}
