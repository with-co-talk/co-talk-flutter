import 'dart:convert';
import 'dart:typed_data';

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

/// Refresh token rotation(1회용)을 흉내내는 가짜 서버 어댑터.
///
/// - `/auth/refresh` 요청의 본문에 들어있는 refreshToken이 현재 유효한
///   토큰과 일치하면 새 토큰 쌍을 발급하고, 옛 토큰을 즉시 무효화한다.
/// - 이미 무효화된(rotated) refresh token으로 다시 갱신을 시도하면
///   서버처럼 401을 반환한다.
/// - 그 외(보호된 리소스 재시도) 요청은 항상 200을 반환한다.
class RotatingRefreshAdapter implements HttpClientAdapter {
  RotatingRefreshAdapter({required String initialRefreshToken})
      : _validRefreshToken = initialRefreshToken;

  String? _validRefreshToken;
  int refreshCallCount = 0;
  final List<String> issuedAccessTokens = [];
  int _accessCounter = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/refresh')) {
      refreshCallCount++;
      final body = options.data as Map?;
      final presented = body?['refreshToken'] as String?;

      // rotation: 이미 무효화된(또는 옛) refresh token이면 401
      if (presented == null || presented != _validRefreshToken) {
        return ResponseBody.fromString(
          jsonEncode({'code': 'INVALID_REFRESH_TOKEN'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      // 갱신 성공 → 옛 refresh token 무효화, 새 토큰 쌍 발급
      _accessCounter++;
      final newAccess = 'access_$_accessCounter';
      final newRefresh = 'refresh_$_accessCounter';
      issuedAccessTokens.add(newAccess);
      _validRefreshToken = newRefresh;

      return ResponseBody.fromString(
        jsonEncode({'accessToken': newAccess, 'refreshToken': newRefresh}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    // 보호된 리소스 재시도는 성공으로 처리
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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

    group('concurrent 401 with refresh token rotation', () {
      late RotatingRefreshAdapter adapter;

      // 인메모리 토큰 저장소: 실제 rotation을 반영하기 위해
      // saveTokens / getRefreshToken / getAccessToken을 stateful하게 흉내낸다.
      String? storedAccess = 'access_0';
      String? storedRefresh = 'refresh_0';

      setUp(() {
        storedAccess = 'access_0';
        storedRefresh = 'refresh_0';

        adapter = RotatingRefreshAdapter(initialRefreshToken: 'refresh_0');
        interceptor.refreshDio.httpClientAdapter = adapter;

        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => storedAccess);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => storedRefresh);
        when(() => mockLocalDataSource.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((invocation) async {
          // 저장 지연을 흉내내 race 가능성을 노출시킨다.
          await Future<void>.delayed(const Duration(milliseconds: 10));
          storedAccess =
              invocation.namedArguments[#accessToken] as String?;
          storedRefresh =
              invocation.namedArguments[#refreshToken] as String?;
        });
        when(() => mockLocalDataSource.clearTokens()).thenAnswer((_) async {
          storedAccess = null;
          storedRefresh = null;
        });
      });

      test(
          'two concurrent 401s trigger refresh ONCE, both retry with new token, no logout',
          () async {
        final errorA = DioException(
          requestOptions: RequestOptions(
            path: '/users/me',
            headers: {'Authorization': 'Bearer access_0'},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 401,
          ),
        );
        final errorB = DioException(
          requestOptions: RequestOptions(
            path: '/chat/rooms',
            headers: {'Authorization': 'Bearer access_0'},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/rooms'),
            statusCode: 401,
          ),
        );

        final handlerA = MockErrorInterceptorHandler();
        final handlerB = MockErrorInterceptorHandler();
        Response? resolvedA;
        Response? resolvedB;
        when(() => handlerA.resolve(any())).thenAnswer((inv) {
          resolvedA = inv.positionalArguments[0] as Response;
        });
        when(() => handlerB.resolve(any())).thenAnswer((inv) {
          resolvedB = inv.positionalArguments[0] as Response;
        });
        when(() => handlerA.next(any())).thenReturn(null);
        when(() => handlerB.next(any())).thenReturn(null);

        // 동시에 두 개의 401을 발생시킨다.
        interceptor.onError(errorA, handlerA);
        interceptor.onError(errorB, handlerB);

        await Future.delayed(const Duration(milliseconds: 500));

        // refresh는 정확히 1회만 호출되어야 한다 (single-flight).
        expect(adapter.refreshCallCount, 1,
            reason: 'refresh must be performed exactly once (single-flight)');

        // 두 요청 모두 성공적으로 resolve 되어야 한다.
        expect(resolvedA, isNotNull,
            reason: 'request A should be retried and resolved');
        expect(resolvedB, isNotNull,
            reason: 'request B should be retried and resolved');

        // 두 요청 모두 새 access token으로 재시도되어야 한다.
        expect(errorA.requestOptions.headers['Authorization'],
            'Bearer access_1');
        expect(errorB.requestOptions.headers['Authorization'],
            'Bearer access_1');

        // 강제 로그아웃이 발생하면 안 된다.
        verifyNever(() => mockLocalDataSource.clearTokens());
        verifyNever(() => handlerA.next(any()));
        verifyNever(() => handlerB.next(any()));
      });

      test('genuine refresh failure (revoked/expired) still forces logout',
          () async {
        // 저장된 refresh token이 서버가 모르는(이미 무효화된) 값이도록 설정
        storedRefresh = 'already_revoked';

        final error = DioException(
          requestOptions: RequestOptions(
            path: '/users/me',
            headers: {'Authorization': 'Bearer access_0'},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 401,
          ),
        );
        final handler = MockErrorInterceptorHandler();
        when(() => handler.next(any())).thenReturn(null);
        when(() => handler.resolve(any())).thenReturn(null);

        interceptor.onError(error, handler);

        await Future.delayed(const Duration(milliseconds: 300));

        // 진짜 만료/무효 → 강제 로그아웃 유지
        verify(() => mockLocalDataSource.clearTokens()).called(1);
        verify(() => handler.next(any())).called(1);
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
