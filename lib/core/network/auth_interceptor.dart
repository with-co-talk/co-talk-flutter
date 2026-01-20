import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

@lazySingleton
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _authLocalDataSource;

  AuthInterceptor(this._authLocalDataSource);

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

            final dio = Dio();
            final response = await dio.fetch(options);
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
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.apiBaseUrl));
      final response = await dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
        };
      }
    } catch (e) {
      // Refresh failed
    }
    return null;
  }
}
