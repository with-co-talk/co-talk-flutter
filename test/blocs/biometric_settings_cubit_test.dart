import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/services/biometric_service.dart';
import 'package:co_talk_flutter/data/datasources/local/security_settings_local_datasource.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/biometric_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/biometric_settings_state.dart';

class MockBiometricService extends Mock implements BiometricService {}
class MockSecuritySettingsLocalDataSource extends Mock implements SecuritySettingsLocalDataSource {}

void main() {
  late BiometricSettingsCubit cubit;
  late MockBiometricService mockBiometricService;
  late MockSecuritySettingsLocalDataSource mockSecuritySettings;

  setUp(() {
    mockBiometricService = MockBiometricService();
    mockSecuritySettings = MockSecuritySettingsLocalDataSource();
    cubit = BiometricSettingsCubit(mockBiometricService, mockSecuritySettings);
  });

  tearDown(() => cubit.close());

  group('BiometricSettingsCubit', () {
    blocTest<BiometricSettingsCubit, BiometricSettingsState>(
      'should load supported and enabled state',
      build: () {
        when(() => mockBiometricService.isSupported()).thenAnswer((_) async => true);
        when(() => mockSecuritySettings.isBiometricEnabled()).thenAnswer((_) async => true);
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const BiometricSettingsState(status: BiometricSettingsStatus.loading),
        const BiometricSettingsState(
          isSupported: true,
          isEnabled: true,
          status: BiometricSettingsStatus.loaded,
        ),
      ],
    );

    blocTest<BiometricSettingsCubit, BiometricSettingsState>(
      'should toggle on with authentication',
      build: () {
        when(() => mockBiometricService.isSupported()).thenAnswer((_) async => true);
        when(() => mockSecuritySettings.isBiometricEnabled()).thenAnswer((_) async => false);
        when(() => mockBiometricService.authenticate(reason: any(named: 'reason')))
            .thenAnswer((_) async => true);
        when(() => mockSecuritySettings.setBiometricEnabled(true))
            .thenAnswer((_) async {});
        return cubit;
      },
      seed: () => const BiometricSettingsState(
        isSupported: true,
        isEnabled: false,
        status: BiometricSettingsStatus.loaded,
      ),
      act: (cubit) => cubit.toggle(),
      expect: () => [
        const BiometricSettingsState(
          isSupported: true,
          isEnabled: true,
          status: BiometricSettingsStatus.loaded,
        ),
      ],
    );

    blocTest<BiometricSettingsCubit, BiometricSettingsState>(
      'should toggle off without authentication',
      build: () {
        when(() => mockSecuritySettings.setBiometricEnabled(false))
            .thenAnswer((_) async {});
        return cubit;
      },
      seed: () => const BiometricSettingsState(
        isSupported: true,
        isEnabled: true,
        status: BiometricSettingsStatus.loaded,
      ),
      act: (cubit) => cubit.toggle(),
      expect: () => [
        const BiometricSettingsState(
          isSupported: true,
          isEnabled: false,
          status: BiometricSettingsStatus.loaded,
        ),
      ],
    );
  });
}
