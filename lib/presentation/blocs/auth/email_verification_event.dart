import 'package:equatable/equatable.dart';

/// 이메일 인증 이벤트 기본 클래스
abstract class EmailVerificationEvent extends Equatable {
  const EmailVerificationEvent();

  @override
  List<Object?> get props => [];
}

/// 인증 이메일 재발송 요청
class EmailVerificationResendRequested extends EmailVerificationEvent {
  final String email;

  const EmailVerificationResendRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// 이메일 인증 상태 초기화
class EmailVerificationReset extends EmailVerificationEvent {
  const EmailVerificationReset();
}
