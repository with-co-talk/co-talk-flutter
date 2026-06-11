import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/auth_interceptor.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockResponse extends Mock implements Response {}

void main() {
  late MockAuthLocalDataSource mockLocalDataSource;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
    registerFallbackValue(Response(requestOptions: RequestOptions(path: '')));
  });

  setUp(() {
    mockLocalDataSource = MockAuthLocalDataSource();
    interceptor = AuthInterceptor(mockLocalDataSource);
  });

  group('AuthInterceptor', () {
    test('creates interceptor successfully', () {
      expect(interceptor, isA<AuthInterceptor>());
    });

    group('onRequest', () {
      test('adds Authorization header for non-auth endpoints', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'test_access_token');

        final options = RequestOptions(path: '/users/me');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == 'Bearer test_access_token',
              ),
            ))).called(1);
      });

      test('skips Authorization header for login endpoint', () async {
        final options = RequestOptions(path: '/auth/login');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == null,
              ),
            ))).called(1);
        verifyNever(() => mockLocalDataSource.getAccessToken());
      });

      test('skips Authorization header for signup endpoint', () async {
        final options = RequestOptions(path: '/auth/signup');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == null,
              ),
            ))).called(1);
      });

      test('skips Authorization header for refresh endpoint', () async {
        final options = RequestOptions(path: '/auth/refresh');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == null,
              ),
            ))).called(1);
      });

      test('does not add Authorization when no token', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);

        final options = RequestOptions(path: '/users/me');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == null,
              ),
            ))).called(1);
      });

      test('adds token for friend endpoints', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'friend_token');

        final options = RequestOptions(path: '/friends');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == 'Bearer friend_token',
              ),
            ))).called(1);
      });

      test('adds token for chat endpoints', () async {
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => 'chat_token');

        final options = RequestOptions(path: '/chat/rooms');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onRequest(options, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(any(
              that: predicate<RequestOptions>(
                (o) => o.headers['Authorization'] == 'Bearer chat_token',
              ),
            ))).called(1);
      });
    });

    group('onError', () {
      test('passes through non-401 errors', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 500,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(error)).called(1);
      });

      test('passes through 403 errors without refresh attempt', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 403,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(error)).called(1);
        verifyNever(() => mockLocalDataSource.getRefreshToken());
      });

      test('passes through 400 errors without refresh attempt', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 400,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(error)).called(1);
        verifyNever(() => mockLocalDataSource.getRefreshToken());
      });

      test('passes through errors with null response', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: null,
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(error)).called(1);
      });

      test('attempts refresh on 401 with refresh token', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'valid_refresh_token');
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 401,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 500));

        verify(() => mockLocalDataSource.getRefreshToken()).called(1);
      });

      test('passes error when refresh token is null on 401', () async {
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 401,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => handler.next(error)).called(1);
      });
    });

    group('dispose', () {
      test('should dispose refreshDio without errors', () {
        // Act
        expect(() => interceptor.dispose(), returnsNormally);
      });

      test('should not retry requests after dispose', () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'refresh_token');
        when(() => mockLocalDataSource.clearTokens())
            .thenAnswer((_) async {});

        final error = DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 401,
          ),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        // Act - dispose first
        interceptor.dispose();

        // Then try to handle error
        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - should pass through error without refresh attempt
        verify(() => handler.next(error)).called(1);
        verifyNever(() => mockLocalDataSource.getRefreshToken());
      });

      test('should allow multiple dispose calls', () {
        // Act & Assert
        expect(() {
          interceptor.dispose();
          interceptor.dispose();
          interceptor.dispose();
        }, returnsNormally);
      });
    });
  });
}
