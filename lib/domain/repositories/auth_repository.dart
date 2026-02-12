import 'dart:io';
import '../entities/auth_token.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<int> signUp({
    required String email,
    required String password,
    required String nickname,
  });
  Future<AuthToken> login({
    required String email,
    required String password,
  });
  Future<AuthToken> refreshToken();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
  Future<int?> getCurrentUserId();
  Future<void> updateProfile({required int userId, String? nickname, String? statusMessage, String? avatarUrl});
  Future<String> uploadAvatar(File file);
  Future<void> resendVerification({required String email});
}
