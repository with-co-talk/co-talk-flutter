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

      test('throws NetworkException on connection timeout', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        await expectLater(dataSource.signUp(request), throwsA(isA<NetworkException>()));
      });

      test('throws ServerException when signUp fails with 500', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'error': 'Internal Server Error'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(dataSource.signUp(request), throwsA(isA<ServerException>()));
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

      test('logout does not send refresh token in body (uses Authorization header only)',
          () async {
        when(() => mockDioClient.post(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await dataSource.logout('any_token');

        // Verify called without data parameter (no body)
        verify(() => mockDioClient.post(any())).called(1);
        verifyNever(() => mockDioClient.post(any(), data: any(named: 'data')));
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

    group('updateProfile', () {
      test('completes when update with all fields succeeds', () async {
        when(() => mockDioClient.put(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.updateProfile(
            1,
            nickname: 'NewNick',
            statusMessage: 'Hello!',
            avatarUrl: 'https://example.com/avatar.jpg',
          ),
          completes,
        );

        verify(() => mockDioClient.put(any(), data: any(named: 'data'))).called(1);
      });

      test('sends only provided fields', () async {
        when(() => mockDioClient.put(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await dataSource.updateProfile(1, nickname: 'OnlyNick');

        final captured =
            verify(() => mockDioClient.put(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data.containsKey('nickname'), isTrue);
        expect(data.containsKey('statusMessage'), isFalse);
        expect(data.containsKey('avatarUrl'), isFalse);
      });

      test('sends empty map when no fields provided', () async {
        when(() => mockDioClient.put(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await dataSource.updateProfile(1);

        final captured =
            verify(() => mockDioClient.put(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data, isEmpty);
      });

      test('throws ServerException on 500', () async {
        when(() => mockDioClient.put(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'error': 'Server error'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          dataSource.updateProfile(1, nickname: 'Nick'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 401', () async {
        when(() => mockDioClient.put(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 401,
              data: {'error': 'Unauthorized'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          dataSource.updateProfile(1, nickname: 'Nick'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('resendVerification', () {
      test('completes when resend verification succeeds', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.resendVerification('test@example.com'),
          completes,
        );
      });

      test('sends email in body', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await dataSource.resendVerification('user@test.com');

        final captured =
            verify(() => mockDioClient.post(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['email'], 'user@test.com');
      });

      test('throws NetworkException on send timeout', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.sendTimeout,
          ),
        );

        await expectLater(
          dataSource.resendVerification('test@example.com'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('findEmail', () {
      test('returns map with email data on success', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {'email': 'found@example.com'},
            statusCode: 200,
          ),
        );

        final result = await dataSource.findEmail('TestUser', '010-1234-5678');

        expect(result['email'], 'found@example.com');
      });

      test('sends nickname and phoneNumber in body', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {'email': 'found@example.com'},
            statusCode: 200,
          ),
        );

        await dataSource.findEmail('MyNick', '010-9876-5432');

        final captured =
            verify(() => mockDioClient.post(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['nickname'], 'MyNick');
        expect(data['phoneNumber'], '010-9876-5432');
      });

      test('throws ValidationException on 400', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {'message': 'User not found'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          dataSource.findEmail('unknown', '000'),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('requestPasswordResetCode', () {
      test('completes when request succeeds', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.requestPasswordResetCode('user@example.com'),
          completes,
        );
      });

      test('sends email in body', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await dataSource.requestPasswordResetCode('reset@example.com');

        final captured =
            verify(() => mockDioClient.post(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['email'], 'reset@example.com');
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.unknown,
          ),
        );

        await expectLater(
          dataSource.requestPasswordResetCode('test@example.com'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('verifyPasswordResetCode', () {
      test('completes when code is valid', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {'valid': true},
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.verifyPasswordResetCode('user@example.com', '123456'),
          completes,
        );
      });

      test('completes when code is invalid but server responds 200', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {'valid': false},
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.verifyPasswordResetCode('user@example.com', 'wrong'),
          completes,
        );
      });

      test('completes when valid key is absent but server responds 200', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: <String, dynamic>{},
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.verifyPasswordResetCode('user@example.com', '000000'),
          completes,
        );
      });

      test('sends email and code in body', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {'valid': true},
            statusCode: 200,
          ),
        );

        await dataSource.verifyPasswordResetCode('test@example.com', 'ABC123');

        final captured =
            verify(() => mockDioClient.post(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['email'], 'test@example.com');
        expect(data['code'], 'ABC123');
      });

      test('throws AuthException on 401', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 401,
              data: {'error': 'Unauthorized'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          dataSource.verifyPasswordResetCode('test@example.com', 'bad'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('resetPasswordWithCode', () {
      test('completes when password reset succeeds', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.resetPasswordWithCode('user@example.com', '123456', 'NewPass1!'),
          completes,
        );
      });

      test('sends email, code, and newPassword in body', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ),
        );

        await dataSource.resetPasswordWithCode('test@example.com', 'CODE1', 'newPwd!2');

        final captured =
            verify(() => mockDioClient.post(any(), data: captureAny(named: 'data'))).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['email'], 'test@example.com');
        expect(data['code'], 'CODE1');
        expect(data['newPassword'], 'newPwd!2');
      });

      test('throws ValidationException on 400', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {'message': 'Invalid code'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          dataSource.resetPasswordWithCode('test@example.com', 'bad', 'pwd'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws NetworkException on receive timeout', () async {
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        await expectLater(
          dataSource.resetPasswordWithCode('test@example.com', '123', 'pwd'),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
