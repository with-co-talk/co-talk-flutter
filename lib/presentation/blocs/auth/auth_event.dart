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
