import 'package:injectable/injectable.dart';
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

    await _localDataSource.saveUserEmail(email);

    return response.toEntity();
  }

  @override
  Future<AuthToken> refreshToken() async {
    final currentRefreshToken = await _localDataSource.getRefreshToken();
    if (currentRefreshToken == null) {
      throw Exception('No refresh token found');
    }

    final response = await _remoteDataSource.refreshToken(currentRefreshToken);

    await _localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    return response.toEntity();
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
      return null;
    }
  }

  @override
  Future<int?> getCurrentUserId() async {
    return _localDataSource.getUserId();
  }
}
