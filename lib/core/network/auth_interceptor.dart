import 'package:dio/dio.dart';
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
      // Token expired, try to refresh
      final refreshToken = await _authLocalDataSource.getRefreshToken();
      if (refreshToken != null) {
        try {
          final newTokens = await _refreshToken(refreshToken);
          if (newTokens != null) {
            // Save new tokens
            await _authLocalDataSource.saveTokens(
              accessToken: newTokens['accessToken']!,
              refreshToken: newTokens['refreshToken']!,
            );

            // Retry the original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer ${newTokens['accessToken']}';

            // Use refresh Dio instance to retry (avoids circular dependency)
            final response = await _refreshDio.fetch(options);
            return handler.resolve(response);
          }
        } catch (e) {
          // Refresh failed, clear tokens and logout
          await _forceLogout();
        }
      } else {
        // Refresh token이 없는 경우도 로그아웃 처리
        await _forceLogout();
      }
    }

    handler.next(err);
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
