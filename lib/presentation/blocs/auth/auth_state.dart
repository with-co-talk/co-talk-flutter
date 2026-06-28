import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';
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

  /// 실패 상태일 때의 인증 에러 타입(구조적 신호).
  /// UI가 표시 메시지를 부분 문자열 매칭하는 대신 이 타입으로 분기한다.
  final AuthErrorType? authErrorType;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.signupEmail,
    this.authErrorType,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.signUpSuccess(String email)
      : this(status: AuthStatus.signUpSuccess, signupEmail: email);

  const AuthState.failure(String message, {User? user, AuthErrorType? errorType})
      : this(
          status: AuthStatus.failure,
          errorMessage: message,
          user: user,
          authErrorType: errorType,
        );

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? signupEmail,
    AuthErrorType? authErrorType,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      signupEmail: signupEmail ?? this.signupEmail,
      authErrorType: authErrorType ?? this.authErrorType,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, errorMessage, signupEmail, authErrorType];
}
