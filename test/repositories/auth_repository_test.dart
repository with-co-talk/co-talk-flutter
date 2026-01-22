import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/auth_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/auth_models.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/data/repositories/auth_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/auth_token.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  setUpAll(() {
    registerFallbackValue(const SignUpRequest(
      email: 'test@example.com',
      password: 'password',
      nickname: 'test',
    ));
    registerFallbackValue(const LoginRequest(
      email: 'test@example.com',
      password: 'password',
    ));
  });

  group('AuthRepository', () {
    group('signUp', () {
      test('returns userId when signUp succeeds', () async {
        when(() => mockRemoteDataSource.signUp(any()))
            .thenAnswer((_) async => const SignUpResponse(
                  userId: 1,
                  message: 'Success',
                ));

        final result = await repository.signUp(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        );

        expect(result, 1);
        verify(() => mockRemoteDataSource.signUp(any())).called(1);
      });

      test('throws exception when signUp fails', () async {
        when(() => mockRemoteDataSource.signUp(any()))
            .thenThrow(Exception('Email already exists'));

        expect(
          () => repository.signUp(
            email: 'existing@example.com',
            password: 'password123',
            nickname: 'TestUser',
          ),
          throwsException,
        );
      });
    });

    group('login', () {
      const tokenResponse = AuthTokenResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        tokenType: 'Bearer',
        expiresIn: 86400,
      );

      test('returns AuthToken and saves tokens when login succeeds', () async {
        when(() => mockRemoteDataSource.login(any()))
            .thenAnswer((_) async => tokenResponse);
        when(() => mockLocalDataSource.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockLocalDataSource.saveUserEmail(any()))
            .thenAnswer((_) async {});

        final result = await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isA<AuthToken>());
        expect(result.accessToken, 'access_token');
        expect(result.refreshToken, 'refresh_token');
        verify(() => mockLocalDataSource.saveTokens(
              accessToken: 'access_token',
              refreshToken: 'refresh_token',
            )).called(1);
        verify(() => mockLocalDataSource.saveUserEmail('test@example.com'))
            .called(1);
      });

      test('throws exception when login fails', () async {
        when(() => mockRemoteDataSource.login(any()))
            .thenThrow(Exception('Invalid credentials'));

        expect(
          () => repository.login(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsException,
        );
      });
    });

    group('logout', () {
      test('clears tokens on logout', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');
        when(() => mockRemoteDataSource.logout(any()))
            .thenAnswer((_) async {});
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockLocalDataSource.clearTokens()).called(1);
      });

      test('clears tokens even if remote logout fails', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');
        when(() => mockRemoteDataSource.logout(any()))
            .thenThrow(Exception('Server error'));
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockLocalDataSource.clearTokens()).called(1);
      });
    });

    group('isLoggedIn', () {
      test('returns true when access token exists', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'access_token');

        final result = await repository.isLoggedIn();

        expect(result, true);
      });

      test('returns false when access token is null', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);

        final result = await repository.isLoggedIn();

        expect(result, false);
      });
    });

    group('getCurrentUser', () {
      test('returns User and saves userId when getCurrentUser succeeds',
          () async {
        final userModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          createdAt: DateTime(2024, 1, 1),
        );
        when(() => mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => userModel);
        when(() => mockLocalDataSource.saveUserId(any()))
            .thenAnswer((_) async {});

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.email, 'test@example.com');
        verify(() => mockLocalDataSource.saveUserId(1)).called(1);
      });

      test('returns null when getCurrentUser fails', () async {
        when(() => mockRemoteDataSource.getCurrentUser())
            .thenThrow(Exception('Unauthorized'));

        final result = await repository.getCurrentUser();

        expect(result, isNull);
      });
    });

    group('getCurrentUserId', () {
      test('returns userId from local storage', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);

        final result = await repository.getCurrentUserId();

        expect(result, 1);
      });

      test('returns null when no userId stored', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        final result = await repository.getCurrentUserId();

        expect(result, isNull);
      });
    });

    group('refreshToken', () {
      const tokenResponse = AuthTokenResponse(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        tokenType: 'Bearer',
        expiresIn: 86400,
      );

      test('returns new AuthToken and saves tokens when refresh succeeds', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'old_refresh_token');
        when(() => mockRemoteDataSource.refreshToken(any()))
            .thenAnswer((_) async => tokenResponse);
        when(() => mockLocalDataSource.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});

        final result = await repository.refreshToken();

        expect(result, isA<AuthToken>());
        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
        verify(() => mockLocalDataSource.saveTokens(
              accessToken: 'new_access_token',
              refreshToken: 'new_refresh_token',
            )).called(1);
      });

      test('throws AuthException when no refresh token stored', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => null);

        expect(
          () => repository.refreshToken(),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws Failure when refresh fails', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'old_refresh_token');
        when(() => mockRemoteDataSource.refreshToken(any()))
            .thenThrow(const ServerException(message: 'Token expired', statusCode: 401));

        expect(
          () => repository.refreshToken(),
          throwsA(anything),
        );
      });
    });

    group('logout', () {
      test('clears tokens when no refresh token', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockLocalDataSource.clearTokens()).called(1);
        verifyNever(() => mockRemoteDataSource.logout(any()));
      });
    });
  });
}
