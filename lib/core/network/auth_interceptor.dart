import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';

@lazySingleton
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _authLocalDataSource;
  final AuthRemoteDataSource _authRemoteDataSource;
  
  // 토큰 갱신 전용 Dio 인스턴스 (순환 참조 방지)
  late final Dio _refreshDio;

  AuthInterceptor(
    this._authLocalDataSource,
    this._authRemoteDataSource,
  ) {
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
  void onRequest(
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
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
      final tokenResponse = await _authRemoteDataSource.refreshToken(refreshToken);
      
      return {
        'accessToken': tokenResponse.accessToken,
        'refreshToken': tokenResponse.refreshToken,
      };
    } catch (e) {
      // Refresh failed - tokens will be cleared in onError handler
      return null;
    }
  }
}
