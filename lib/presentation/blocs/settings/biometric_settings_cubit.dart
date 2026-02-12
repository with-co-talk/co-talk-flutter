import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/datasources/local/security_settings_local_datasource.dart';
import 'biometric_settings_state.dart';

/// 생체 인증 설정 Cubit
@injectable
class BiometricSettingsCubit extends Cubit<BiometricSettingsState> {
  final BiometricService _biometricService;
  final SecuritySettingsLocalDataSource _securitySettings;

  BiometricSettingsCubit(
    this._biometricService,
    this._securitySettings,
  ) : super(const BiometricSettingsState());

  /// 초기 상태 로드
  Future<void> load() async {
    emit(state.copyWith(status: BiometricSettingsStatus.loading));
    try {
      final isSupported = await _biometricService.isSupported();
      final isEnabled = await _securitySettings.isBiometricEnabled();
      emit(state.copyWith(
        isSupported: isSupported,
        isEnabled: isEnabled,
        status: BiometricSettingsStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BiometricSettingsStatus.error,
        errorMessage: '생체 인증 설정을 불러오는데 실패했습니다.',
      ));
    }
  }

  /// 생체 인증 토글
  Future<void> toggle() async {
    if (!state.isSupported) return;

    if (state.isEnabled) {
      // 비활성화
      await _securitySettings.setBiometricEnabled(false);
      emit(state.copyWith(isEnabled: false));
    } else {
      // 활성화 전 인증 확인
      final authenticated = await _biometricService.authenticate(
        reason: '생체 인증을 활성화하려면 인증해주세요',
      );
      if (authenticated) {
        await _securitySettings.setBiometricEnabled(true);
        emit(state.copyWith(isEnabled: true));
      }
    }
  }
}
