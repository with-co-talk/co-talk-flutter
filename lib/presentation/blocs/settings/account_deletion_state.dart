import 'package:equatable/equatable.dart';

enum AccountDeletionStatus {
  initial,
  passwordEntered,
  waitingConfirmation,
  deleting,
  deleted,
  error,
}

/// 회원 탈퇴 실패 종류. 표시 문자열은 위젯 레이어에서 [AppLocalizations]로 해석한다.
/// 매퍼가 생성한 메시지는 [AccountDeletionState.errorMessage]로 전달된다.
enum AccountDeletionError {
  invalidConfirmation,
  emptyPassword,
  userNotFound,
  unknown,
}

/// 회원 탈퇴 상태
class AccountDeletionState extends Equatable {
  final AccountDeletionStatus status;
  final String? password;
  final String? confirmationText;

  /// 매퍼가 생성한 에러 메시지(컨텍스트 없는 유틸 산출물).
  final String? errorMessage;

  /// 의미론적 실패 종류. 표시 문자열은 위젯 레이어에서 해석한다.
  final AccountDeletionError? errorType;
  final bool canDelete;

  const AccountDeletionState({
    this.status = AccountDeletionStatus.initial,
    this.password,
    this.confirmationText,
    this.errorMessage,
    this.errorType,
    this.canDelete = false,
  });

  const AccountDeletionState.initial() : this();

  const AccountDeletionState.passwordEntered(String password)
      : this(
          status: AccountDeletionStatus.passwordEntered,
          password: password,
        );

  const AccountDeletionState.waitingConfirmation({
    required String password,
    String? confirmationText,
  }) : this(
          status: AccountDeletionStatus.waitingConfirmation,
          password: password,
          confirmationText: confirmationText,
          canDelete: confirmationText == '삭제합니다',
        );

  const AccountDeletionState.deleting()
      : this(status: AccountDeletionStatus.deleting);

  const AccountDeletionState.deleted()
      : this(status: AccountDeletionStatus.deleted);

  const AccountDeletionState.error(String message)
      : this(status: AccountDeletionStatus.error, errorMessage: message);

  /// 의미론적 실패 상태. 표시 텍스트는 위젯 레이어에서 해석한다.
  const AccountDeletionState.failure(AccountDeletionError type)
      : this(status: AccountDeletionStatus.error, errorType: type);

  AccountDeletionState copyWith({
    AccountDeletionStatus? status,
    String? password,
    String? confirmationText,
    String? errorMessage,
    AccountDeletionError? errorType,
    bool? canDelete,
  }) {
    return AccountDeletionState(
      status: status ?? this.status,
      password: password ?? this.password,
      confirmationText: confirmationText ?? this.confirmationText,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  @override
  List<Object?> get props =>
      [status, password, confirmationText, errorMessage, errorType, canDelete];
}
