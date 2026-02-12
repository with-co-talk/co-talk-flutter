import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'email_verification_event.dart';
import 'email_verification_state.dart';

/// 이메일 인증 BLoC
@injectable
class EmailVerificationBloc
    extends Bloc<EmailVerificationEvent, EmailVerificationState> {
  final AuthRepository _authRepository;

  EmailVerificationBloc(this._authRepository)
      : super(const EmailVerificationState.waiting()) {
    on<EmailVerificationResendRequested>(_onResendRequested);
    on<EmailVerificationReset>(_onReset);
  }

  Future<void> _onResendRequested(
    EmailVerificationResendRequested event,
    Emitter<EmailVerificationState> emit,
  ) async {
    emit(const EmailVerificationState.resending());

    try {
      await _authRepository.resendVerification(email: event.email);
      emit(const EmailVerificationState.resent());
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(EmailVerificationState.error(message));
    }
  }

  void _onReset(
    EmailVerificationReset event,
    Emitter<EmailVerificationState> emit,
  ) {
    emit(const EmailVerificationState.waiting());
  }
}
