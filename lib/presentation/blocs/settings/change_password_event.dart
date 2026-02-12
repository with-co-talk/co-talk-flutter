import 'package:equatable/equatable.dart';

/// 비밀번호 변경 이벤트 기본 클래스
abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

/// 비밀번호 변경 요청 이벤트
class ChangePasswordSubmitted extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// 비밀번호 변경 상태 초기화 이벤트
class ChangePasswordReset extends ChangePasswordEvent {
  const ChangePasswordReset();
}
