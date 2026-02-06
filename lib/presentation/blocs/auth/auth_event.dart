import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String nickname;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.nickname,
  });

  @override
  List<Object?> get props => [email, password, nickname];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? nickname;
  final String? statusMessage;
  final String? avatarUrl;
  final String? backgroundUrl;

  const AuthProfileUpdateRequested({
    this.nickname,
    this.statusMessage,
    this.avatarUrl,
    this.backgroundUrl,
  });

  @override
  List<Object?> get props => [nickname, statusMessage, avatarUrl, backgroundUrl];
}

class AuthAvatarUploadRequested extends AuthEvent {
  final File imageFile;

  const AuthAvatarUploadRequested({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

/// 로컬에서 user 상태만 업데이트 (서버에 이미 저장된 경우)
class AuthUserLocalUpdated extends AuthEvent {
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? statusMessage;
  /// true면 avatarUrl을 null로 설정 (기본 이미지로 변경)
  final bool clearAvatar;

  const AuthUserLocalUpdated({
    this.avatarUrl,
    this.backgroundUrl,
    this.statusMessage,
    this.clearAvatar = false,
  });

  @override
  List<Object?> get props => [avatarUrl, backgroundUrl, statusMessage, clearAvatar];
}
