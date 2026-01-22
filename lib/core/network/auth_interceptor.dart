import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

@lazySingleton
class AuthInterceptor extends QueuedInterceptor {
  final AuthLocalDataSource _authLocalDataSource;

  // 토큰 갱신 전용 Dio 인스턴스 (순환 참조 방지)
  late final Dio _refreshDio;

  AuthInterceptor(this._authLocalDataSource) {
    // 토큰 갱신 전용 클라이언트 생성 (인터셉터 없이)
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

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/signup') ||
        options.path.contains('/auth/refresh');

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
    // Auth 엔드포인트는 토큰 갱신 로직 제외
    final isAuthEndpoint = err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/signup') ||
        err.requestOptions.path.contains('/auth/refresh');

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
          // Refresh failed, clear tokens and redirect to login
          await _authLocalDataSource.clearTokens();
        }
      }
    }

    handler.next(err);
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
}
