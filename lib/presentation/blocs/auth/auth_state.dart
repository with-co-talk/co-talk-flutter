import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  signUpSuccess,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? signupEmail;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.signupEmail,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.signUpSuccess(String email)
      : this(status: AuthStatus.signUpSuccess, signupEmail: email);

  const AuthState.failure(String message, {User? user})
      : this(status: AuthStatus.failure, errorMessage: message, user: user);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? signupEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      signupEmail: signupEmail ?? this.signupEmail,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, signupEmail];
}
