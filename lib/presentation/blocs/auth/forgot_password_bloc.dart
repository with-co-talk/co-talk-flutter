import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/error_message_mapper.dart';

// Events
abstract class ForgotPasswordEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ForgotPasswordCodeRequested extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ForgotPasswordCodeVerified extends ForgotPasswordEvent {
  final String email;
  final String code;
  ForgotPasswordCodeVerified({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
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

  @override
  List<Object?> get props => [email, code, newPassword];
}

class ForgotPasswordReset extends ForgotPasswordEvent {}

// States
enum ForgotPasswordStep { email, code, newPassword, complete }

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStep step;
  final ForgotPasswordStatus status;
  final String? email;
  final String? code;
  final String? errorMessage;
  final bool isInvalidCode; // 인증 코드 무효 시 true → 위젯에서 authInvalidCode ARB 키로 해석

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.status = ForgotPasswordStatus.initial,
    this.email,
    this.code,
    this.errorMessage,
    this.isInvalidCode = false,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    ForgotPasswordStatus? status,
    String? email,
    String? code,
    String? errorMessage,
    bool clearError = false,
    bool? isInvalidCode,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      status: status ?? this.status,
      email: email ?? this.email,
      code: code ?? this.code,
      // FindEmailState와 동일하게 기본은 보존하고,
      // 새 시도 시작 등 에러 클리어 의도는 clearError로 명시한다.
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInvalidCode: clearError ? false : (isInvalidCode ?? this.isInvalidCode),
    );
  }

  @override
  List<Object?> get props => [step, status, email, code, errorMessage, isInvalidCode];
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
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
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
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
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
          isInvalidCode: true,
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
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
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
