import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/app_config.dart';
import '../config/security_config.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'certificate_pinning_interceptor.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;
  final AuthInterceptor _authInterceptor;
  final CertificatePinningInterceptor _certificatePinningInterceptor;

  DioClient(
    this._authInterceptor,
    this._certificatePinningInterceptor,
  ) {
    _dio = Dio(
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

    // Add certificate pinning interceptor first for security
    if (SecurityConfig.certificatePinningEnabled) {
      _dio.interceptors.add(_certificatePinningInterceptor);
    }

    _dio.interceptors.add(_authInterceptor);

    // 프로덕션 환경에서는 민감한 정보 로깅 비활성화
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: AppConfig.enableNetworkBodyLogging,
        responseBody: AppConfig.enableNetworkBodyLogging,
        requestHeader: AppConfig.enableVerboseLogging,
        responseHeader: false,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
