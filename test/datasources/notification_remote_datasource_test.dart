import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/data/datasources/remote/notification_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late NotificationRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = NotificationRemoteDataSourceImpl(mockDioClient);
  });

  group('NotificationRemoteDataSource', () {
    group('registerFcmToken', () {
      test('registers FCM token to server successfully', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'success': true,
                'message': 'FCM token registered successfully',
              },
            ));

        await dataSource.registerFcmToken(
          token: 'test_fcm_token',
          platform: 'android',
          deviceId: 'device_123',
        );

        verify(() => mockDioClient.post(
              '/users/fcm-token',
              data: {
                'token': 'test_fcm_token',
                'platform': 'android',
                'deviceId': 'device_123',
              },
            )).called(1);
      });

      test('throws exception when registration fails', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 500,
                data: {'message': 'Server error'},
              ),
            ));

        expect(
          () => dataSource.registerFcmToken(
            token: 'test_fcm_token',
            platform: 'android',
            deviceId: 'device_123',
          ),
          throwsException,
        );
      });
    });

    group('unregisterFcmToken', () {
      test('unregisters FCM token from server successfully', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'success': true,
                'message': 'FCM token deleted successfully',
              },
            ));

        await dataSource.unregisterFcmToken(deviceId: 'device_123');

        verify(() => mockDioClient.delete(
              '/users/fcm-token',
              data: {'deviceId': 'device_123'},
            )).called(1);
      });

      test('throws exception when unregistration fails', () async {
        when(() => mockDioClient.delete(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 500,
                data: {'message': 'Server error'},
              ),
            ));

        expect(
          () => dataSource.unregisterFcmToken(deviceId: 'device_123'),
          throwsException,
        );
      });
    });
  });
}
