import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/auth_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/auth_models.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = AuthRemoteDataSourceImpl(mockDioClient);
  });

  group('AuthRemoteDataSource', () {
    group('signUp', () {
      const request = SignUpRequest(
        email: 'test@example.com',
        password: 'password123',
        nickname: 'TestUser',
      );

      test('returns SignUpResponse when signUp succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'userId': 1, 'message': 'Success'},
              statusCode: 201,
            ));

        final result = await dataSource.signUp(request);

        expect(result.userId, 1);
        expect(result.message, 'Success');
      });

      test('throws ValidationException when signUp fails with 400', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'message': 'Email already exists'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.signUp(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('login', () {
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      test('returns AuthTokenResponse when login succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'accessToken': 'access_token',
                'refreshToken': 'refresh_token',
                'tokenType': 'Bearer',
                'expiresIn': 86400,
              },
              statusCode: 200,
            ));

        final result = await dataSource.login(request);

        expect(result.accessToken, 'access_token');
        expect(result.refreshToken, 'refresh_token');
        expect(result.tokenType, 'Bearer');
        expect(result.expiresIn, 86400);
      });

      test('throws AuthException when login fails with 401', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Invalid credentials'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.login(request),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException when connection timeout', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.login(request),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('refreshToken', () {
      test('returns AuthTokenResponse when refresh succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'accessToken': 'new_access_token',
                'refreshToken': 'new_refresh_token',
                'tokenType': 'Bearer',
                'expiresIn': 86400,
              },
              statusCode: 200,
            ));

        final result = await dataSource.refreshToken('old_refresh_token');

        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
      });

      test('throws AuthException when refresh token is invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Invalid refresh token'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.refreshToken('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('logout', () {
      test('completes successfully when logout succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.logout('refresh_token'),
          completes,
        );
      });

      test('throws ServerException when logout fails', () async {
        when(() => mockDioClient.post(
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
          () => dataSource.logout('refresh_token'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('returns UserModel when getCurrentUser succeeds', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'email': 'test@example.com',
                'nickname': 'TestUser',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 200,
            ));

        final result = await dataSource.getCurrentUser();

        expect(result.id, 1);
        expect(result.email, 'test@example.com');
        expect(result.nickname, 'TestUser');
      });

      test('throws AuthException when getCurrentUser fails with 401', () async {
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
          () => dataSource.getCurrentUser(),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException when receive timeout', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.getCurrentUser(),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
