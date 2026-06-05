import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/services/biometric_service.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/local/security_settings_local_datasource.dart';
import 'package:co_talk_flutter/presentation/blocs/app/app_lock_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/app/app_lock_state.dart';

class MockBiometricService extends Mock implements BiometricService {}

class MockSecuritySettingsLocalDataSource extends Mock
    implements SecuritySettingsLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockBiometricService mockBiometricService;
  late MockSecuritySettingsLocalDataSource mockSecuritySettings;
  late MockAuthLocalDataSource mockAuthLocalDataSource;

  setUp(() {
    mockBiometricService = MockBiometricService();
    mockSecuritySettings = MockSecuritySettingsLocalDataSource();
    mockAuthLocalDataSource = MockAuthLocalDataSource();
  });

  /// 유예 시간을 주입해 잠금 판정을 결정적으로 테스트한다.
  AppLockCubit buildCubit({Duration grace = Duration.zero}) => AppLockCubit(
        mockBiometricService,
        mockSecuritySettings,
        mockAuthLocalDataSource,
      )..backgroundGracePeriod = grace;

  group('AppLockCubit', () {
    blocTest<AppLockCubit, AppLockState>(
      '생체인식 ON + 로그인 + 백그라운드 체류 시 잠그고 즉시 인증을 시작한다',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'access-token');
        // 잠금 직후 자동 인증 → 성공 시 해제
        when(() => mockBiometricService.authenticate())
            .thenAnswer((_) async => true);
        return buildCubit();
      },
      act: (cubit) {
        cubit.onBackgrounded();
        return cubit.checkLockOnResume();
      },
      expect: () => [
        const AppLockState.locked(),
        const AppLockState.authenticating(),
        const AppLockState.unlocked(),
      ],
      verify: (_) {
        // 버튼 없이 자동으로 생체 인증이 호출돼야 한다.
        verify(() => mockBiometricService.authenticate()).called(1);
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      '백그라운드를 거치지 않은 복귀는 잠그지 않는다',
      build: buildCubit,
      act: (cubit) => cubit.checkLockOnResume(),
      expect: () => [],
    );

    blocTest<AppLockCubit, AppLockState>(
      '생체인식이 꺼져 있으면 잠그지 않는다',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) {
        cubit.onBackgrounded();
        return cubit.checkLockOnResume();
      },
      expect: () => [],
    );

    blocTest<AppLockCubit, AppLockState>(
      '로그인 상태가 아니면 잠그지 않는다',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) {
        cubit.onBackgrounded();
        return cubit.checkLockOnResume();
      },
      expect: () => [],
    );

    blocTest<AppLockCubit, AppLockState>(
      '유예 시간 이내(짧은 이탈)에 복귀하면 잠그지 않는다',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'access-token');
        // 30초 유예: 즉시 복귀하면 잠그지 않아야 한다.
        return buildCubit(grace: const Duration(seconds: 30));
      },
      act: (cubit) {
        cubit.onBackgrounded();
        return cubit.checkLockOnResume();
      },
      expect: () => [],
    );

    blocTest<AppLockCubit, AppLockState>(
      '인증 성공 시 잠금 해제된다',
      build: () {
        when(() => mockBiometricService.authenticate())
            .thenAnswer((_) async => true);
        return buildCubit();
      },
      seed: () => const AppLockState.locked(),
      act: (cubit) => cubit.authenticate(),
      expect: () => [
        const AppLockState.authenticating(),
        const AppLockState.unlocked(),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      '인증 실패 시 잠금 상태를 유지한다',
      build: () {
        when(() => mockBiometricService.authenticate())
            .thenAnswer((_) async => false);
        return buildCubit();
      },
      seed: () => const AppLockState.locked(),
      act: (cubit) => cubit.authenticate(),
      expect: () => [
        const AppLockState.authenticating(),
        const AppLockState.locked(),
      ],
    );
  });
}
