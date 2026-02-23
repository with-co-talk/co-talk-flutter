import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/file_mime_resolver.dart';
import '../../models/auth_models.dart';
import '../../models/user_model.dart';
import '../base_remote_datasource.dart';

abstract class AuthRemoteDataSource {
  Future<SignUpResponse> signUp(SignUpRequest request);
  Future<AuthTokenResponse> login(LoginRequest request);
  Future<AuthTokenResponse> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<UserModel> getCurrentUser();
  Future<void> updateProfile(int userId, {String? nickname, String? statusMessage, String? avatarUrl});
  Future<String> uploadFile(File file);
  Future<void> resendVerification(String email);
  Future<Map<String, dynamic>> findEmail(String nickname, String phoneNumber);
  Future<void> requestPasswordResetCode(String email);
  Future<bool> verifyPasswordResetCode(String email, String code);
  Future<void> resetPasswordWithCode(String email, String code, String newPassword);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl extends BaseRemoteDataSource
    implements AuthRemoteDataSource {
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
      throw handleDioError(e);
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
      throw handleDioError(e);
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
      throw handleDioError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      // API 스펙: 로그아웃은 Authorization 헤더만 사용, body 없음
      await _dioClient.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get('/users/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> updateProfile(int userId, {String? nickname, String? statusMessage, String? avatarUrl}) async {
    try {
      await _dioClient.put(
        ApiConstants.userProfile(userId),
        data: {
          if (nickname != null) 'nickname': nickname,
          if (statusMessage != null) 'statusMessage': statusMessage,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<String> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final mime = await FileMimeResolver.resolveFromFile(file);
      final contentType = http_parser.MediaType.parse(mime);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: contentType,
        ),
      });

      final response = await _dioClient.post(
        ApiConstants.fileUpload,
        data: formData,
      );

      return response.data['fileUrl'] as String;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> resendVerification(String email) async {
    try {
      await _dioClient.post(
        ApiConstants.resendVerification,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> findEmail(String nickname, String phoneNumber) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.findEmail,
        data: {
          'nickname': nickname,
          'phoneNumber': phoneNumber,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> requestPasswordResetCode(String email) async {
    try {
      await _dioClient.post(
        ApiConstants.resetRequestCode,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.verifyCode,
        data: {'email': email, 'code': code},
      );
      return response.data['valid'] as bool? ?? false;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> resetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      await _dioClient.post(
        ApiConstants.resetWithCode,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
