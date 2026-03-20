import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/settings_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/notification_settings_model.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late SettingsRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = SettingsRemoteDataSourceImpl(mockDioClient);
  });

  group('SettingsRemoteDataSource', () {
    group('getNotificationSettings', () {
      test('returns NotificationSettingsModel when request succeeds', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageNotification': true,
                'friendRequestNotification': false,
                'groupInviteNotification': true,
                'notificationPreviewMode': 'NAME_ONLY',
                'soundEnabled': true,
                'vibrationEnabled': false,
                'doNotDisturbEnabled': false,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getNotificationSettings();

        expect(result, isA<NotificationSettingsModel>());
        expect(result.messageNotification, true);
        expect(result.friendRequestNotification, false);
        expect(result.groupInviteNotification, true);
        expect(result.notificationPreviewMode, 'NAME_ONLY');
        expect(result.soundEnabled, true);
        expect(result.vibrationEnabled, false);
        verify(() => mockDioClient.get('/notifications/settings')).called(1);
      });

      test('throws AuthException when request fails with 401', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getNotificationSettings(),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws ServerException when request fails with 500', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getNotificationSettings(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException when connection timeout occurs', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.getNotificationSettings(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('updateNotificationSettings', () {
      final settings = NotificationSettingsModel(
        messageNotification: false,
        friendRequestNotification: true,
        groupInviteNotification: false,
        notificationPreviewMode: 'NOTHING',
        soundEnabled: false,
        vibrationEnabled: true,
        doNotDisturbEnabled: true,
        doNotDisturbStart: '22:00',
        doNotDisturbEnd: '08:00',
      );

      test('completes successfully when update succeeds', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.updateNotificationSettings(settings),
          completes,
        );

        verify(() => mockDioClient.put(
              '/notifications/settings',
              data: settings.toJson(),
            )).called(1);
      });

      test('throws ValidationException when update fails with 400', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'message': 'Invalid settings'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.updateNotificationSettings(settings),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws AuthException when update fails with 401', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.updateNotificationSettings(settings),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('deleteAccount', () {
      const userId = 123;
      const password = 'myPassword123';

      test('completes successfully when deletion succeeds', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.deleteAccount(userId, password),
          completes,
        );

        verify(() => mockDioClient.delete(
              '/account',
              data: {'password': password},
            )).called(1);
      });

      test('throws AuthException when deletion fails with 401', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Invalid password'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.deleteAccount(userId, password),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws ValidationException when deletion fails with 400', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'message': 'Invalid request'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.deleteAccount(userId, password),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ServerException when deletion fails with 500', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.deleteAccount(userId, password),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('changePassword', () {
      const currentPassword = 'oldPassword123';
      const newPassword = 'newPassword456';

      test('completes successfully when password change succeeds', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.changePassword(currentPassword, newPassword),
          completes,
        );

        verify(() => mockDioClient.put(
              '/password/change',
              data: {
                'currentPassword': currentPassword,
                'newPassword': newPassword,
              },
            )).called(1);
      });

      test('throws AuthException when password change fails with 401', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Invalid current password'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.changePassword(currentPassword, newPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws ValidationException when password change fails with 400', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'message': 'Password too weak'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.changePassword(currentPassword, newPassword),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws NetworkException when receive timeout occurs', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.changePassword(currentPassword, newPassword),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
