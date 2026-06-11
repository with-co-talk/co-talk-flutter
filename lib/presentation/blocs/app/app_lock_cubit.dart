import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../data/datasources/local/security_settings_local_datasource.dart';
import 'app_lock_state.dart';

/// 앱 잠금 Cubit
///
/// 앱이 백그라운드에서 복귀할 때 생체 인증 잠금을 관리합니다.
///
/// 잠금 정책:
/// - 로그인 상태에서만 적용된다(로그아웃/미로그인 시 잠그지 않음).
/// - 생체 인증이 켜져 있어야 한다.
/// - 백그라운드에 [_backgroundGracePeriod]보다 오래 머문 뒤 복귀할 때만 잠근다.
///   (잠깐 앱 전환/알림 확인 등 짧은 이탈에는 잠그지 않는다.)
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  final BiometricService _biometricService;
  final SecuritySettingsLocalDataSource _securitySettings;
  final AuthLocalDataSource _authLocalDataSource;

  /// 앱이 백그라운드로 전환된 시각. 포그라운드 복귀 시 체류 시간 계산에 사용한다.
  DateTime? _backgroundedAt;

  /// 백그라운드 체류 유예 시간. 이 시간 이내에 복귀하면 잠그지 않는다.
  Duration _backgroundGracePeriod = const Duration(seconds: 30);

  /// 유예 시간 재정의(테스트 전용).
  @visibleForTesting
  set backgroundGracePeriod(Duration value) => _backgroundGracePeriod = value;

  AppLockCubit(
    this._biometricService,
    this._securitySettings,
    this._authLocalDataSource,
  ) : super(const AppLockState.unlocked());

  /// 앱이 백그라운드로 전환될 때 호출한다. 체류 시작 시각을 기록한다.
  void onBackgrounded() {
    // 이미 잠겨 있거나 인증 중이면 시각을 덮어쓰지 않는다.
    if (state.status != AppLockStatus.unlocked) return;
    _backgroundedAt = DateTime.now();
  }

  /// 앱 복귀 시 잠금 체크.
  ///
  /// 다음 조건을 모두 만족할 때만 잠근다:
  /// 1) 생체 인증이 켜져 있음
  /// 2) 로그인 상태임
  /// 3) 백그라운드에 유예 시간보다 오래 머물렀음
  Future<void> checkLockOnResume() async {
    // 백그라운드 시각을 소비한다(스퍼리어스 resume이 반복 잠금을 유발하지 않도록).
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    // 백그라운드를 거치지 않은 복귀(예: 콜드 스타트 직후)는 잠그지 않는다.
    if (backgroundedAt == null) return;

    final isEnabled = await _securitySettings.isBiometricEnabled();
    if (!isEnabled) return;

    // 로그인 상태에서만 잠금 적용
    final accessToken = await _authLocalDataSource.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    // 백그라운드에 짧게 머문 경우(유예 이내)는 잠그지 않는다.
    final elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed < _backgroundGracePeriod) return;

    emit(const AppLockState.locked());

    // 잠금 화면이 뜨면 버튼을 누를 필요 없이 즉시 생체 인증을 시작한다.
    // 실패/취소 시에는 잠금 상태로 남고, 사용자가 화면의 버튼으로 재시도할 수 있다.
    await authenticate();
  }

  /// 앱 최초 실행 시 잠금 체크 (grace period 무시)
  Future<void> checkLockOnLaunch() async {
    final isEnabled = await _securitySettings.isBiometricEnabled();
    if (!isEnabled) return;

    emit(const AppLockState.locked());
  }

  /// 생체 인증 시도
  Future<void> authenticate() async {
    emit(const AppLockState.authenticating());

    final success = await _biometricService.authenticate();
    if (success) {
      _backgroundedAt = null;
      emit(const AppLockState.unlocked());
    } else {
      emit(const AppLockState.locked());
    }
  }

  /// 인증 성공으로 잠금 해제 (수동)
  void unlock() {
    _backgroundedAt = null;
    emit(const AppLockState.unlocked());
  }
}
