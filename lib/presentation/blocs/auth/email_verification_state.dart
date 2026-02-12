import 'package:equatable/equatable.dart';

enum EmailVerificationStatus {
  waiting,
  resending,
  resent,
  error,
}

/// 이메일 인증 상태
class EmailVerificationState extends Equatable {
  final EmailVerificationStatus status;
  final String? errorMessage;

  const EmailVerificationState({
    this.status = EmailVerificationStatus.waiting,
    this.errorMessage,
  });

  const EmailVerificationState.waiting() : this();

  const EmailVerificationState.resending()
      : this(status: EmailVerificationStatus.resending);

  const EmailVerificationState.resent()
      : this(status: EmailVerificationStatus.resent);

  const EmailVerificationState.error(String message)
      : this(status: EmailVerificationStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, errorMessage];
}
