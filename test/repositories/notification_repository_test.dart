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
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              deviceType: any(named: 'deviceType'),
            )).thenAnswer((_) async {});

        await repository.registerToken(userId: 1, deviceType: 'ANDROID');

        verify(() => mockFcmService.getToken()).called(1);
        verify(() => mockLocalDataSource.saveFcmToken('test_fcm_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'test_fcm_token',
              deviceType: 'ANDROID',
            )).called(1);
      });

      test('registers token successfully when FCM token is available', () async {
        when(() => mockFcmService.getToken())
            .thenAnswer((_) async => 'test_fcm_token');
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              deviceType: any(named: 'deviceType'),
            )).thenAnswer((_) async {});

        await repository.registerToken(userId: 1, deviceType: 'IOS');

        verify(() => mockLocalDataSource.saveFcmToken('test_fcm_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'test_fcm_token',
              deviceType: 'IOS',
            )).called(1);
      });

      test('does nothing when token is null', () async {
        when(() => mockFcmService.getToken()).thenAnswer((_) async => null);

        await repository.registerToken(userId: 1, deviceType: 'ANDROID');

        verifyNever(() => mockLocalDataSource.saveFcmToken(any()));
        verifyNever(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              deviceType: any(named: 'deviceType'),
            ));
      });
    });

    group('refreshToken', () {
      test('re-registers token when refreshed', () async {
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              deviceType: any(named: 'deviceType'),
            )).thenAnswer((_) async {});

        await repository.refreshToken(
          userId: 1,
          newToken: 'new_fcm_token',
          deviceType: 'IOS',
        );

        verify(() => mockLocalDataSource.saveFcmToken('new_fcm_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'new_fcm_token',
              deviceType: 'IOS',
            )).called(1);
      });
    });

    group('unregisterToken', () {
      test('deletes token from server and clears local storage', () async {
        when(() => mockLocalDataSource.getFcmToken())
            .thenAnswer((_) async => 'test_fcm_token');
        when(() => mockRemoteDataSource.unregisterFcmToken(
              token: any(named: 'token'),
            )).thenAnswer((_) async {});
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verify(() => mockRemoteDataSource.unregisterFcmToken(token: 'test_fcm_token'))
            .called(1);
        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
        verify(() => mockFcmService.deleteToken()).called(1);
      });

      test('clears local token even if server unregistration fails', () async {
        when(() => mockLocalDataSource.getFcmToken())
            .thenAnswer((_) async => 'test_fcm_token');
        when(() => mockRemoteDataSource.unregisterFcmToken(
              token: any(named: 'token'),
            )).thenThrow(Exception('Server error'));
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
        verify(() => mockFcmService.deleteToken()).called(1);
      });

      test('skips server unregistration when token is null', () async {
        when(() => mockLocalDataSource.getFcmToken())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.clearFcmToken())
            .thenAnswer((_) async {});
        when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

        await repository.unregisterToken();

        verifyNever(() => mockRemoteDataSource.unregisterFcmToken(
              token: any(named: 'token'),
            ));
        verify(() => mockLocalDataSource.clearFcmToken()).called(1);
      });
    });

    group('setupTokenRefreshListener', () {
      test('listens to token refresh and re-registers', () async {
        final tokenController = StreamController<String>();

        when(() => mockFcmService.onTokenRefresh)
            .thenAnswer((_) => tokenController.stream);
        when(() => mockLocalDataSource.saveFcmToken(any()))
            .thenAnswer((_) async {});
        when(() => mockRemoteDataSource.registerFcmToken(
              token: any(named: 'token'),
              deviceType: any(named: 'deviceType'),
            )).thenAnswer((_) async {});

        repository.setupTokenRefreshListener(userId: 1, deviceType: 'ANDROID');

        // Emit a new token
        tokenController.add('refreshed_token');

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockLocalDataSource.saveFcmToken('refreshed_token')).called(1);
        verify(() => mockRemoteDataSource.registerFcmToken(
              token: 'refreshed_token',
              deviceType: 'ANDROID',
            )).called(1);

        await tokenController.close();
      });
    });
  });
}
