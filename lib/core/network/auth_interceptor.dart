import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import 'websocket_service.dart';

@lazySingleton
class AuthInterceptor extends QueuedInterceptor {
  final AuthLocalDataSource _authLocalDataSource;
  AuthBloc? _authBloc;
  WebSocketService? _webSocketService;

  // 토큰 갱신 전용 Dio 인스턴스 (순환 참조 방지)
  late final Dio _refreshDio;

  // Dispose flag to prevent operations after disposal
  bool _isDisposed = false;

  // Single-flight refresh: 동시 401 발생 시 refresh를 1회만 수행하고
  // 나머지 대기 요청들은 진행 중인 refresh의 결과(Future)를 공유한다.
  // 서버가 refresh token rotation(1회용)을 사용하므로, 큐의 후속 요청이
  // 이미 무효화된(revoked) refresh token으로 재갱신을 시도해 강제 로그아웃되는
  // 결함을 방지한다.
  Future<Map<String, String>?>? _inFlightRefresh;

  /// 테스트 전용: refresh 요청을 가로채기 위해 _refreshDio를 노출한다.
  @visibleForTesting
  Dio get refreshDio => _refreshDio;

  AuthInterceptor(this._authLocalDataSource) {
    // 토큰 갱신 전용 클라이언트 생성 (인터셉터 없이)
    // TODO: When real certificate pinning is enabled (non-placeholder certificates),
    // add CertificatePinningInterceptor to _refreshDio to prevent MITM attacks
    // during token refresh requests
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// AuthBloc과 WebSocketService를 설정 (순환 참조 방지를 위해 나중에 설정)
  void setAuthBloc(AuthBloc authBloc) {
    _authBloc = authBloc;
  }

  void setWebSocketService(WebSocketService webSocketService) {
    _webSocketService = webSocketService;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/signup') ||
        options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/find-email') ||
        options.path.contains('/password/reset-request') ||
        options.path.contains('/password/verify-code') ||
        options.path.contains('/password/reset-with-code') ||
        options.path.contains('/password/reset');

    if (!isAuthEndpoint) {
      final accessToken = await _authLocalDataSource.getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Early return if disposed
    if (_isDisposed) {
      handler.next(err);
      return;
    }

    // Auth 엔드포인트는 토큰 갱신 로직 제외
    final isAuthEndpoint = err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/signup') ||
        err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/find-email') ||
        err.requestOptions.path.contains('/password/reset-request') ||
        err.requestOptions.path.contains('/password/verify-code') ||
        err.requestOptions.path.contains('/password/reset-with-code') ||
        err.requestOptions.path.contains('/password/reset');

    // USER_NOT_FOUND 에러 체크 (404 + USER_NOT_FOUND 코드)
    // 토큰은 유효하지만 사용자가 DB에 없는 경우 (삭제됨, DB 초기화 등)
    if (err.response?.statusCode == 404 && !isAuthEndpoint) {
      final responseData = err.response?.data;
      final errorCode = responseData is Map ? responseData['code'] : null;

      if (errorCode == 'USER_NOT_FOUND') {
        await _forceLogout();
        handler.next(err);
        return;
      }
    }

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      // 동시 401 처리: refresh는 single-flight로 1회만 수행한다.
      // 이미 진행 중인 refresh가 있으면 그 결과(Future)를 공유하고,
      // 없으면 새 refresh를 시작한다. 큐의 후속 요청이 옛(이미 회전된)
      // refresh token으로 다시 갱신을 시도하지 않도록 보장한다.
      Map<String, String>? newTokens;
      try {
        newTokens = await _ensureRefreshed();
      } catch (_) {
        newTokens = null;
      }

      if (newTokens != null) {
        // Retry the original request with the new access token.
        // 큐에 대기하던 요청도 항상 최신 access token으로 헤더를 교체한다.
        final options = err.requestOptions;
        options.headers['Authorization'] =
            'Bearer ${newTokens['accessToken']}';

        try {
          // Use refresh Dio instance to retry (avoids circular dependency)
          final response = await _refreshDio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          // 재시도 자체가 실패하면 원본 에러를 전파한다.
          // (refresh는 성공했으므로 강제 로그아웃하지 않는다)
          if (e is DioException) {
            return handler.next(e);
          }
          return handler.next(err);
        }
      }

      // 여기 도달 = refresh가 진짜로 실패(만료/무효/토큰 없음)한 경우에만
      // 강제 로그아웃한다. 한 번의 rotation으로 인한 후속 401은
      // single-flight 공유 결과로 흡수되므로 여기까지 오지 않는다.
      await _forceLogout();
    }

    handler.next(err);
  }

  /// Single-flight refresh.
  ///
  /// 진행 중인 refresh가 있으면 그 Future를 그대로 반환하고,
  /// 없으면 새 refresh를 1회 시작한다. 성공 시 새 토큰을 저장한 뒤
  /// 토큰 맵을 반환하고, 실패(만료/무효/토큰 없음) 시 null을 반환한다.
  Future<Map<String, String>?> _ensureRefreshed() {
    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<Map<String, String>?> _performRefresh() async {
    final refreshToken = await _authLocalDataSource.getRefreshToken();
    if (refreshToken == null) {
      return null;
    }

    final newTokens = await _refreshToken(refreshToken);
    if (newTokens == null) {
      return null;
    }

    // Save new tokens (rotation: 옛 refresh token은 서버에서 이미 무효화됨)
    await _authLocalDataSource.saveTokens(
      accessToken: newTokens['accessToken']!,
      refreshToken: newTokens['refreshToken']!,
    );

    return newTokens;
  }

  /// 강제 로그아웃 처리
  Future<void> _forceLogout() async {
    await _authLocalDataSource.clearTokens();
    _webSocketService?.disconnect();
    _authBloc?.add(const AuthLogoutRequested());
  }

  Future<Map<String, String>?> _refreshToken(String refreshToken) async {
    try {
      // 순환 참조 방지를 위해 직접 Dio로 토큰 갱신 요청
      final response = await _refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      return {
        'accessToken': data['accessToken'] as String,
        'refreshToken': data['refreshToken'] as String,
      };
    } catch (e) {
      // Refresh failed - tokens will be cleared in onError handler
      return null;
    }
  }

  /// Disposes resources used by the interceptor
  /// Should be called when the interceptor is no longer needed
  void dispose() {
    if (_isDisposed) {
      return; // Already disposed
    }

    _isDisposed = true;
    _refreshDio.close(force: true);
  }
}
