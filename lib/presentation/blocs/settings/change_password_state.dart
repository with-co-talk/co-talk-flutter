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

  /// 매퍼가 생성한 에러 메시지(컨텍스트 없는 유틸 산출물). null이면 위젯 레이어가
  /// 기본 메시지로 대체한다.
  final String? errorMessage;

  /// 인식되지 않은(알 수 없는) 에러로 도메인 특화 안내를 표시해야 하는지 여부.
  /// 표시 문자열은 위젯 레이어에서 [AppLocalizations]로 해석한다.
  final bool isUnknownError;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.errorMessage,
    this.isUnknownError = false,
  });

  const ChangePasswordState.initial() : this();

  const ChangePasswordState.loading()
      : this(status: ChangePasswordStatus.loading);

  const ChangePasswordState.success()
      : this(status: ChangePasswordStatus.success);

  const ChangePasswordState.error(String message)
      : this(status: ChangePasswordStatus.error, errorMessage: message);

  /// 도메인 특화(알 수 없는 에러) 실패 상태. 표시 텍스트는 위젯에서 해석한다.
  const ChangePasswordState.unknownError()
      : this(status: ChangePasswordStatus.error, isUnknownError: true);

  @override
  List<Object?> get props => [status, errorMessage, isUnknownError];
}
