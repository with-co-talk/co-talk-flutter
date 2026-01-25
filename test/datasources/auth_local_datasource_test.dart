import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/core/constants/app_constants.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = AuthLocalDataSourceImpl(mockSecureStorage);
  });

  group('AuthLocalDataSource', () {
    group('saveTokens', () {
      test('saves access token and refresh token', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.saveTokens(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
        );

        verify(() => mockSecureStorage.write(
              key: AppConstants.accessTokenKey,
              value: 'test_access_token',
            )).called(1);
        verify(() => mockSecureStorage.write(
              key: AppConstants.refreshTokenKey,
              value: 'test_refresh_token',
            )).called(1);
      });
    });

    group('getAccessToken', () {
      test('returns access token when exists', () async {
        when(() => mockSecureStorage.read(key: AppConstants.accessTokenKey))
            .thenAnswer((_) async => 'stored_access_token');

        final result = await dataSource.getAccessToken();

        expect(result, 'stored_access_token');
      });

      test('returns null when access token does not exist', () async {
        when(() => mockSecureStorage.read(key: AppConstants.accessTokenKey))
            .thenAnswer((_) async => null);

        final result = await dataSource.getAccessToken();

        expect(result, isNull);
      });
    });

    group('getRefreshToken', () {
      test('returns refresh token when exists', () async {
        when(() => mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => 'stored_refresh_token');

        final result = await dataSource.getRefreshToken();

        expect(result, 'stored_refresh_token');
      });

      test('returns null when refresh token does not exist', () async {
        when(() => mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => null);

        final result = await dataSource.getRefreshToken();

        expect(result, isNull);
      });
    });

    group('clearTokens', () {
      test('clears all tokens and user data', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await dataSource.clearTokens();

        verify(() => mockSecureStorage.delete(key: AppConstants.accessTokenKey))
            .called(1);
        verify(
                () => mockSecureStorage.delete(key: AppConstants.refreshTokenKey))
            .called(1);
        verify(() => mockSecureStorage.delete(key: AppConstants.userIdKey))
            .called(1);
        verify(() => mockSecureStorage.delete(key: AppConstants.userEmailKey))
            .called(1);
      });
    });

    group('saveUserId', () {
      test('saves user id as string', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.saveUserId(123);

        verify(() => mockSecureStorage.write(
              key: AppConstants.userIdKey,
              value: '123',
            )).called(1);
      });
    });

    group('getUserId', () {
      test('returns user id when valid integer string exists', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userIdKey))
            .thenAnswer((_) async => '456');

        final result = await dataSource.getUserId();

        expect(result, 456);
      });

      test('returns null when user id does not exist', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userIdKey))
            .thenAnswer((_) async => null);

        final result = await dataSource.getUserId();

        expect(result, isNull);
      });

      test('returns null and deletes invalid format', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userIdKey))
            .thenAnswer((_) async => 'invalid_number');
        when(() => mockSecureStorage.delete(key: AppConstants.userIdKey))
            .thenAnswer((_) async {});

        final result = await dataSource.getUserId();

        expect(result, isNull);
        verify(() => mockSecureStorage.delete(key: AppConstants.userIdKey))
            .called(1);
      });

      test('returns null when storage read throws exception', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userIdKey))
            .thenThrow(Exception('Storage error'));

        final result = await dataSource.getUserId();

        expect(result, isNull);
      });
    });

    group('saveUserEmail', () {
      test('saves user email', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await dataSource.saveUserEmail('test@example.com');

        verify(() => mockSecureStorage.write(
              key: AppConstants.userEmailKey,
              value: 'test@example.com',
            )).called(1);
      });
    });

    group('getUserEmail', () {
      test('returns user email when exists', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userEmailKey))
            .thenAnswer((_) async => 'stored@example.com');

        final result = await dataSource.getUserEmail();

        expect(result, 'stored@example.com');
      });

      test('returns null when user email does not exist', () async {
        when(() => mockSecureStorage.read(key: AppConstants.userEmailKey))
            .thenAnswer((_) async => null);

        final result = await dataSource.getUserEmail();

        expect(result, isNull);
      });
    });
  });
}
