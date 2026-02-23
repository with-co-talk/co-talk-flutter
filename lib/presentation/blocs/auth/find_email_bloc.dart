import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/error_message_mapper.dart';

// Events
abstract class FindEmailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FindEmailRequested extends FindEmailEvent {
  final String nickname;
  final String phoneNumber;

  FindEmailRequested({required this.nickname, required this.phoneNumber});

  @override
  List<Object?> get props => [nickname, phoneNumber];
}

class FindEmailReset extends FindEmailEvent {}

// States
enum FindEmailStatus { initial, loading, success, notFound, failure }

class FindEmailState extends Equatable {
  final FindEmailStatus status;
  final String? maskedEmail;
  final String? message;
  final String? errorMessage;

  const FindEmailState({
    this.status = FindEmailStatus.initial,
    this.maskedEmail,
    this.message,
    this.errorMessage,
  });

  FindEmailState copyWith({
    FindEmailStatus? status,
    String? maskedEmail,
    String? message,
    String? errorMessage,
  }) {
    return FindEmailState(
      status: status ?? this.status,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, maskedEmail, message, errorMessage];
}

// BLoC
class FindEmailBloc extends Bloc<FindEmailEvent, FindEmailState> {
  final AuthRepository _authRepository;

  FindEmailBloc(this._authRepository) : super(const FindEmailState()) {
    on<FindEmailRequested>(_onFindEmailRequested);
    on<FindEmailReset>(_onReset);
  }

  Future<void> _onFindEmailRequested(
    FindEmailRequested event,
    Emitter<FindEmailState> emit,
  ) async {
    emit(state.copyWith(status: FindEmailStatus.loading));

    try {
      final result = await _authRepository.findEmail(
        nickname: event.nickname,
        phoneNumber: event.phoneNumber,
      );

      final found = result['found'] as bool? ?? false;
      final maskedEmail = result['maskedEmail'] as String?;
      final message = result['message'] as String?;

      if (found) {
        emit(state.copyWith(
          status: FindEmailStatus.success,
          maskedEmail: maskedEmail,
          message: message,
        ));
      } else {
        emit(state.copyWith(
          status: FindEmailStatus.notFound,
          message: message ?? '일치하는 계정을 찾을 수 없습니다.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FindEmailStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  void _onReset(FindEmailReset event, Emitter<FindEmailState> emit) {
    emit(const FindEmailState());
  }
}
