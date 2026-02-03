import 'package:equatable/equatable.dart';

enum AccountDeletionStatus {
  initial,
  passwordEntered,
  waitingConfirmation,
  deleting,
  deleted,
  error,
}

/// 회원 탈퇴 상태
class AccountDeletionState extends Equatable {
  final AccountDeletionStatus status;
  final String? password;
  final String? confirmationText;
  final String? errorMessage;
  final bool canDelete;

  const AccountDeletionState({
    this.status = AccountDeletionStatus.initial,
    this.password,
    this.confirmationText,
    this.errorMessage,
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

  AccountDeletionState copyWith({
    AccountDeletionStatus? status,
    String? password,
    String? confirmationText,
    String? errorMessage,
    bool? canDelete,
  }) {
    return AccountDeletionState(
      status: status ?? this.status,
      password: password ?? this.password,
      confirmationText: confirmationText ?? this.confirmationText,
      errorMessage: errorMessage ?? this.errorMessage,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  @override
  List<Object?> get props => [status, password, confirmationText, errorMessage, canDelete];
}
