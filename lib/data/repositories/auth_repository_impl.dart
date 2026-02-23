import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/jwt_utils.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_models.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<int> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _remoteDataSource.signUp(
      SignUpRequest(email: email, password: password, nickname: nickname),
    );
    return response.userId;
  }

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );

    await _localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // userId는 서버 JWT의 subject(sub)에 들어있으므로, 토큰 저장 직후 동기화한다.
    // (사용자 정보 조회(getCurrentUser)가 실패해도 구독/웹소켓 채널은 올바른 userId로 설정되어야 함)
    final userId = JwtUtils.extractUserIdFromSubject(response.accessToken);
    if (userId != null && userId > 0) {
      await _localDataSource.saveUserId(userId);
    }

    await _localDataSource.saveUserEmail(email);

    return response.toEntity();
  }

  @override
  Future<AuthToken> refreshToken() async {
    final currentRefreshToken = await _localDataSource.getRefreshToken();
    if (currentRefreshToken == null) {
      throw const AuthException(
        message: '리프레시 토큰을 찾을 수 없습니다',
        type: AuthErrorType.tokenInvalid,
      );
    }

    try {
      final response = await _remoteDataSource.refreshToken(currentRefreshToken);

      await _localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return response.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _remoteDataSource.logout(refreshToken);
      } catch (_) {
        // Ignore logout errors
      }
    }
    await _localDataSource.clearTokens();
  }

  @override
  Future<bool> isLoggedIn() async {
    final accessToken = await _localDataSource.getAccessToken();
    return accessToken != null;
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveUserId(userModel.id);
      return userModel.toEntity();
    } catch (e) {
      // 사용자 정보를 가져오지 못한 경우 null 반환
      // 로그인은 성공했지만 사용자 정보 조회 실패는 치명적이지 않음
      return null;
    }
  }

  @override
  Future<int?> getCurrentUserId() async {
    return _localDataSource.getUserId();
  }

  @override
  Future<void> updateProfile({
    required int userId,
    String? nickname,
    String? statusMessage,
    String? avatarUrl,
  }) async {
    await _remoteDataSource.updateProfile(
      userId,
      nickname: nickname,
      statusMessage: statusMessage,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<String> uploadAvatar(File file) async {
    return await _remoteDataSource.uploadFile(file);
  }

  @override
  Future<void> resendVerification({required String email}) async {
    await _remoteDataSource.resendVerification(email);
  }

  @override
  Future<Map<String, dynamic>> findEmail({
    required String nickname,
    required String phoneNumber,
  }) async {
    return await _remoteDataSource.findEmail(nickname, phoneNumber);
  }

  @override
  Future<void> requestPasswordResetCode({required String email}) async {
    await _remoteDataSource.requestPasswordResetCode(email);
  }

  @override
  Future<bool> verifyPasswordResetCode({required String email, required String code}) async {
    return await _remoteDataSource.verifyPasswordResetCode(email, code);
  }

  @override
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _remoteDataSource.resetPasswordWithCode(email, code, newPassword);
  }
}
