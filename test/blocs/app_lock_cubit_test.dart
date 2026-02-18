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

    group('checkLockOnLaunch', () {
      blocTest<AppLockCubit, AppLockState>(
        'should lock on launch when biometric is enabled (bypasses grace period)',
        build: () {
          when(() => mockSecuritySettings.isBiometricEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBiometricService.authenticate())
              .thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) async {
          // Simulate: authenticate first to set _lastAuthenticatedAt
          await cubit.authenticate();
          // Then immediately call checkLockOnLaunch
          // It should lock even within grace period
          await cubit.checkLockOnLaunch();
        },
        expect: () => [
          const AppLockState.authenticating(),
          const AppLockState.unlocked(),
          const AppLockState.locked(),
        ],
      );

      blocTest<AppLockCubit, AppLockState>(
        'should not lock on launch when biometric is disabled',
        build: () {
          when(() => mockSecuritySettings.isBiometricEnabled())
              .thenAnswer((_) async => false);
          return cubit;
        },
        act: (cubit) => cubit.checkLockOnLaunch(),
        expect: () => [],
      );

      blocTest<AppLockCubit, AppLockState>(
        'should lock on launch even without prior authentication',
        build: () {
          when(() => mockSecuritySettings.isBiometricEnabled())
              .thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) => cubit.checkLockOnLaunch(),
        expect: () => [const AppLockState.locked()],
      );
    });

    group('checkLockOnResume grace period', () {
      blocTest<AppLockCubit, AppLockState>(
        'should NOT lock on resume when within grace period after authentication',
        build: () {
          when(() => mockSecuritySettings.isBiometricEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBiometricService.authenticate())
              .thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) async {
          // Authenticate first, then immediately check resume
          await cubit.authenticate();
          await cubit.checkLockOnResume();
        },
        expect: () => [
          // authenticate() emits authenticating + unlocked
          const AppLockState.authenticating(),
          const AppLockState.unlocked(),
          // checkLockOnResume() within grace period -> no additional emit
        ],
      );
    });

    group('biometric cache', () {
      test('should use cached value on subsequent checkLockOnResume calls', () async {
        when(() => mockSecuritySettings.isBiometricEnabled())
            .thenAnswer((_) async => true);

        // First call: reads from SecureStorage and caches
        await cubit.checkLockOnResume();
        expect(cubit.state.status, AppLockStatus.locked);
        verify(() => mockSecuritySettings.isBiometricEnabled()).called(1);

        // Second call on a new cubit instance: cache is preloaded
        final cubit2 = AppLockCubit(mockBiometricService, mockSecuritySettings);
        cubit2.updateBiometricEnabledCache(true);
        await cubit2.checkLockOnResume();
        expect(cubit2.state.status, AppLockStatus.locked);
        // isBiometricEnabled should NOT be called again (used cached value)
        verifyNever(() => mockSecuritySettings.isBiometricEnabled());
        cubit2.close();
      });

      test('updateBiometricEnabledCache should update cached state', () {
        cubit.updateBiometricEnabledCache(true);
        expect(cubit.isBiometricEnabled, true);

        cubit.updateBiometricEnabledCache(false);
        expect(cubit.isBiometricEnabled, false);
      });
    });
  });
}
