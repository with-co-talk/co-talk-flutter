import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:injectable/injectable.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'certificate_pinning_interceptor.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;
  final AuthInterceptor _authInterceptor;
  final CertificatePinningService _certificatePinningService;

  DioClient(
    this._authInterceptor,
    this._certificatePinningService,
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

    // 인증서 피닝: HttpClientAdapter에 연결해야 badCertificateCallback이 실제
    // TLS 핸드셰이크 검증에 사용된다. (plain Interceptor로 등록하면 콜백이
    // 호출되지 않아 무의미하다.) 피닝이 비활성이면 기본 HttpClient를 사용한다.
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: _certificatePinningService.createPinnedHttpClient,
    );

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
  }) async {
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
  }) async {
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
  }) async {
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
  }) async {
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
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
