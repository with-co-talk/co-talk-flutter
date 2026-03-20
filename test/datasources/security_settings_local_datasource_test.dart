import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:co_talk_flutter/data/datasources/local/security_settings_local_datasource.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late SecuritySettingsLocalDataSource dataSource;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = SecuritySettingsLocalDataSource(mockSecureStorage);
  });

  group('SecuritySettingsLocalDataSource', () {
    group('isBiometricEnabled', () {
      test('returns true when stored value is "true"', () async {
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');

        final result = await dataSource.isBiometricEnabled();

        expect(result, isTrue);
      });

      test('returns false when stored value is "false"', () async {
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'false');

        final result = await dataSource.isBiometricEnabled();

        expect(result, isFalse);
      });

      test('returns false when stored value is null (not set)', () async {
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => null);

        final result = await dataSource.isBiometricEnabled();

        expect(result, isFalse);
      });

      test('returns false for any non-"true" string value', () async {
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'yes');

        final result = await dataSource.isBiometricEnabled();

        expect(result, isFalse);
      });

      test('calls read with correct key', () async {
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => null);

        await dataSource.isBiometricEnabled();

        verify(() => mockSecureStorage.read(key: 'biometric_enabled')).called(1);
      });
    });

    group('setBiometricEnabled', () {
      test('writes "true" when enabled is true', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.setBiometricEnabled(true);

        verify(() => mockSecureStorage.write(
              key: 'biometric_enabled',
              value: 'true',
            )).called(1);
      });

      test('writes "false" when enabled is false', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.setBiometricEnabled(false);

        verify(() => mockSecureStorage.write(
              key: 'biometric_enabled',
              value: 'false',
            )).called(1);
      });
    });

    group('round-trip', () {
      test('enable biometric and read it back as true', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');

        await dataSource.setBiometricEnabled(true);
        final result = await dataSource.isBiometricEnabled();

        expect(result, isTrue);
      });

      test('disable biometric and read it back as false', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'false');

        await dataSource.setBiometricEnabled(false);
        final result = await dataSource.isBiometricEnabled();

        expect(result, isFalse);
      });
    });
  });
}
