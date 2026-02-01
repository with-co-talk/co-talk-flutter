import 'package:equatable/equatable.dart';

/// 회원 탈퇴 이벤트 기본 클래스
abstract class AccountDeletionEvent extends Equatable {
  const AccountDeletionEvent();

  @override
  List<Object?> get props => [];
}

/// 비밀번호 입력 이벤트
class AccountDeletionPasswordEntered extends AccountDeletionEvent {
  final String password;

  const AccountDeletionPasswordEntered(this.password);

  @override
  List<Object?> get props => [password];
}

/// 확인 텍스트 입력 이벤트
class AccountDeletionConfirmationEntered extends AccountDeletionEvent {
  final String confirmationText;

  const AccountDeletionConfirmationEntered(this.confirmationText);

  @override
  List<Object?> get props => [confirmationText];
}

/// 탈퇴 요청 이벤트
class AccountDeletionRequested extends AccountDeletionEvent {
  const AccountDeletionRequested();
}

/// 탈퇴 프로세스 초기화 이벤트
class AccountDeletionReset extends AccountDeletionEvent {
  const AccountDeletionReset();
}
