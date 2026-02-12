import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/services/biometric_service.dart';
import 'package:co_talk_flutter/data/datasources/local/security_settings_local_datasource.dart';
import 'package:co_talk_flutter/presentation/blocs/app/app_lock_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/app/app_lock_state.dart';

class MockBiometricService extends Mock implements BiometricService {}
class MockSecuritySettingsLocalDataSource extends Mock implements SecuritySettingsLocalDataSource {}

void main() {
  late AppLockCubit cubit;
  late MockBiometricService mockBiometricService;
  late MockSecuritySettingsLocalDataSource mockSecuritySettings;

  setUp(() {
    mockBiometricService = MockBiometricService();
    mockSecuritySettings = MockSecuritySettingsLocalDataSource();
    cubit = AppLockCubit(mockBiometricService, mockSecuritySettings);
  });

  tearDown(() => cubit.close());

  group('AppLockCubit', () {
    blocTest<AppLockCubit, AppLockState>(
      'should lock when biometric is enabled and grace period expired',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => true);
        return cubit;
      },
      act: (cubit) => cubit.checkLockOnResume(),
      expect: () => [const AppLockState.locked()],
    );

    blocTest<AppLockCubit, AppLockState>(
      'should not lock when biometric is disabled',
      build: () {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.checkLockOnResume(),
      expect: () => [],
    );

    blocTest<AppLockCubit, AppLockState>(
      'should unlock on successful authentication',
      build: () {
        when(() => mockBiometricService.authenticate())
            .thenAnswer((_) async => true);
        return cubit;
      },
      seed: () => const AppLockState.locked(),
      act: (cubit) => cubit.authenticate(),
      expect: () => [
        const AppLockState.authenticating(),
        const AppLockState.unlocked(),
      ],
    );
  });
}
