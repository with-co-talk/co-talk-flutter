import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/local/notification_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/notification_remote_datasource.dart';
import 'package:co_talk_flutter/data/repositories/notification_repository_impl.dart';
import 'package:co_talk_flutter/core/services/fcm_service.dart';

class MockNotificationLocalDataSource extends Mock
    implements NotificationLocalDataSource {}

class MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  late MockNotificationLocalDataSource mockLocalDataSource;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockFcmService mockFcmService;
  late NotificationRepositoryImpl repository;

  setUp(() {
    mockLocalDataSource = MockNotificationLocalDataSource();
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockFcmService = MockFcmService();
    repository = NotificationRepositoryImpl(
      mockLocalDataSource,
      mockRemoteDataSource,
      mockFcmService,
    );
  });

  group('NotificationRepository', () {
    group('registerToken', () {
      test('saves token locally and registers to server', () async {
        when(() => mockFcmService.getToken())
            .thenAnswer((_) async => 'test_fcm_token');
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => 'device_123');
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              platform: any(named: 'platform'),
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async {});

        await repository.registerToken(platform: 'android');

        verify(() => mockFcmService.getToken()).called(1);
        verify(() => mockLocalDataSource.saveFcmToken('test_fcm_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'test_fcm_token',
              platform: 'android',
              deviceId: 'device_123',
            )).called(1);
      });

      test('generates and saves device ID if not exists', () async {
        when(() => mockFcmService.getToken())
            .thenAnswer((_) async => 'test_fcm_token');
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.saveDeviceId(any()))
            .thenAnswer((_) async {});
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              platform: any(named: 'platform'),
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async {});

        await repository.registerToken(platform: 'android');

        verify(() => mockLocalDataSource.saveDeviceId(any())).called(1);
      });

      test('does nothing when token is null', () async {
        when(() => mockFcmService.getToken()).thenAnswer((_) async => null);

        await repository.registerToken(platform: 'android');

        verifyNever(() => mockLocalDataSource.saveFcmToken(any()));
        verifyNever(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              platform: any(named: 'platform'),
              deviceId: any(named: 'deviceId'),
            ));
      });
    });

    group('refreshToken', () {
      test('re-registers token when refreshed', () async {
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => 'device_123');
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              platform: any(named: 'platform'),
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async {});

        await repository.refreshToken(
          newToken: 'new_fcm_token',
          platform: 'ios',
        );

        verify(() => mockLocalDataSource.saveFcmToken('new_fcm_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'new_fcm_token',
              platform: 'ios',
              deviceId: 'device_123',
            )).called(1);
      });
    });

    group('unregisterToken', () {
      test('deletes token from server and clears local storage', () async {
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => 'device_123');
        when(() => mockRemoteDataSource.unregisterFcmToken(
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async {});
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verify(() => mockRemoteDataSource.unregisterFcmToken(deviceId: 'device_123'))
            .called(1);
        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
        verify(() => mockFcmService.deleteToken()).called(1);
      });

      test('clears local token even if server unregistration fails', () async {
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => 'device_123');
        when(() => mockRemoteDataSource.unregisterFcmToken(
              deviceId: any(named: 'deviceId'),
            )).thenThrow(Exception('Server error'));
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
        verify(() => mockFcmService.deleteToken()).called(1);
      });

      test('skips server unregistration when device ID is null', () async {
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verifyNever(() => mockRemoteDataSource.unregisterFcmToken(
              deviceId: any(named: 'deviceId'),
            ));
        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
      });
    });

    group('setupTokenRefreshListener', () {
      test('listens to token refresh and re-registers', () async {
        final tokenController = StreamController<String>();

        when(() => mockFcmService.onTokenRefresh)
            .thenAnswer((_) => tokenController.stream);
        when(() => mockLocalDataSource.getDeviceId())
            .thenAnswer((_) async => 'device_123');
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              platform: any(named: 'platform'),
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async {});

        repository.setupTokenRefreshListener(platform: 'android');

        // Emit a new token
        tokenController.add('refreshed_token');

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockLocalDataSource.saveFcmToken('refreshed_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'refreshed_token',
              platform: 'android',
              deviceId: 'device_123',
            )).called(1);

        await tokenController.close();
      });
    });
  });
}
