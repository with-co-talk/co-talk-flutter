import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/auth_models.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<SignUpResponse> signUp(SignUpRequest request);
  Future<AuthTokenResponse> login(LoginRequest request);
  Future<AuthTokenResponse> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<UserModel> getCurrentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<SignUpResponse> signUp(SignUpRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.signUp,
        data: request.toJson(),
      );
      return SignUpResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthTokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      return AuthTokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthTokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.refresh,
        data: TokenRefreshRequest(refreshToken: refreshToken).toJson(),
      );
      return AuthTokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get('/users/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] ?? 'Unknown error';

      if (statusCode == 401) {
        return AuthException(
          message: message,
          type: AuthErrorType.invalidCredentials,
        );
      }

      return ServerException(
        message: message,
        statusCode: statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException(message: '네트워크 연결 시간이 초과되었습니다');
    }

    return const NetworkException(message: '네트워크 오류가 발생했습니다');
  }
}
