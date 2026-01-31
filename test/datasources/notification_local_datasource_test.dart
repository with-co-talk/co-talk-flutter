import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:co_talk_flutter/data/datasources/local/notification_local_datasource.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late NotificationLocalDataSourceImpl dataSource;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = NotificationLocalDataSourceImpl(mockSecureStorage);
  });

  group('NotificationLocalDataSource', () {
    group('saveFcmToken', () {
      test('saves FCM token to secure storage', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.saveFcmToken('test_fcm_token');

        verify(() => mockSecureStorage.write(
              key: 'fcm_token',
              value: 'test_fcm_token',
            )).called(1);
      });
    });

    group('getFcmToken', () {
      test('returns FCM token when exists', () async {
        when(() => mockSecureStorage.read(key: 'fcm_token'))
            .thenAnswer((_) async => 'stored_fcm_token');

        final result = await dataSource.getFcmToken();

        expect(result, 'stored_fcm_token');
      });

      test('returns null when FCM token does not exist', () async {
        when(() => mockSecureStorage.read(key: 'fcm_token'))
            .thenAnswer((_) async => null);

        final result = await dataSource.getFcmToken();

        expect(result, isNull);
      });
    });

    group('clearFcmToken', () {
      test('deletes FCM token from secure storage', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await dataSource.clearFcmToken();

        verify(() => mockSecureStorage.delete(key: 'fcm_token')).called(1);
      });
    });

    group('saveDeviceId', () {
      test('saves device ID to secure storage', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.saveDeviceId('device_123');

        verify(() => mockSecureStorage.write(
              key: 'device_id',
              value: 'device_123',
            )).called(1);
      });
    });

    group('getDeviceId', () {
      test('returns device ID when exists', () async {
        when(() => mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => 'stored_device_id');

        final result = await dataSource.getDeviceId();

        expect(result, 'stored_device_id');
      });

      test('returns null when device ID does not exist', () async {
        when(() => mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => null);

        final result = await dataSource.getDeviceId();

        expect(result, isNull);
      });
    });
  });
}
