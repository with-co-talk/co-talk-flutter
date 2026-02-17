import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/error_message_mapper.dart';

// Events
abstract class ForgotPasswordEvent {}

class ForgotPasswordCodeRequested extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordCodeRequested({required this.email});
}

class ForgotPasswordCodeVerified extends ForgotPasswordEvent {
  final String email;
  final String code;
  ForgotPasswordCodeVerified({required this.email, required this.code});
}

class ForgotPasswordResetRequested extends ForgotPasswordEvent {
  final String email;
  final String code;
  final String newPassword;
  ForgotPasswordResetRequested({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

class ForgotPasswordReset extends ForgotPasswordEvent {}

// States
enum ForgotPasswordStep { email, code, newPassword, complete }

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final ForgotPasswordStatus status;
  final String? email;
  final String? code;
  final String? errorMessage;

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.status = ForgotPasswordStatus.initial,
    this.email,
    this.code,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    ForgotPasswordStatus? status,
    String? email,
    String? code,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      status: status ?? this.status,
      email: email ?? this.email,
      code: code ?? this.code,
      errorMessage: errorMessage,
    );
  }
}

// BLoC
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordBloc(this._authRepository) : super(const ForgotPasswordState()) {
    on<ForgotPasswordCodeRequested>(_onCodeRequested);
    on<ForgotPasswordCodeVerified>(_onCodeVerified);
    on<ForgotPasswordResetRequested>(_onResetRequested);
    on<ForgotPasswordReset>(_onReset);
  }

  Future<void> _onCodeRequested(
    ForgotPasswordCodeRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading));
    try {
      await _authRepository.requestPasswordResetCode(email: event.email);
      emit(state.copyWith(
        step: ForgotPasswordStep.code,
        status: ForgotPasswordStatus.success,
        email: event.email,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onCodeVerified(
    ForgotPasswordCodeVerified event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading));
    try {
      final isValid = await _authRepository.verifyPasswordResetCode(
        email: event.email,
        code: event.code,
      );
      if (isValid) {
        emit(state.copyWith(
          step: ForgotPasswordStep.newPassword,
          status: ForgotPasswordStatus.success,
          code: event.code,
        ));
      } else {
        emit(state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: '인증 코드가 유효하지 않습니다. 다시 확인해주세요.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading));
    try {
      await _authRepository.resetPasswordWithCode(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(
        step: ForgotPasswordStep.complete,
        status: ForgotPasswordStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  void _onReset(ForgotPasswordReset event, Emitter<ForgotPasswordState> emit) {
    emit(const ForgotPasswordState());
  }
}
