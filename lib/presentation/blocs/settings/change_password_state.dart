import 'package:equatable/equatable.dart';

enum ChangePasswordStatus {
  initial,
  loading,
  success,
  error,
}

/// 비밀번호 변경 상태
class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;
  final String? errorMessage;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.errorMessage,
  });

  const ChangePasswordState.initial() : this();

  const ChangePasswordState.loading()
      : this(status: ChangePasswordStatus.loading);

  const ChangePasswordState.success()
      : this(status: ChangePasswordStatus.success);

  const ChangePasswordState.error(String message)
      : this(status: ChangePasswordStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, errorMessage];
}
