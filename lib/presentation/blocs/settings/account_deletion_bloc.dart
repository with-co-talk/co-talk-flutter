import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/utils/error_message_mapper.dart';
import 'account_deletion_event.dart';
import 'account_deletion_state.dart';

/// 회원 탈퇴 BLoC
///
/// 회원 탈퇴 프로세스를 관리합니다.
/// 강력한 확인 UX: 비밀번호 → 확인 텍스트 → 최종 삭제
@injectable
class AccountDeletionBloc extends Bloc<AccountDeletionEvent, AccountDeletionState> {
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  AccountDeletionBloc(this._settingsRepository, this._authRepository)
      : super(const AccountDeletionState.initial()) {
    on<AccountDeletionPasswordEntered>(_onPasswordEntered);
    on<AccountDeletionConfirmationEntered>(_onConfirmationEntered);
    on<AccountDeletionRequested>(_onDeletionRequested);
    on<AccountDeletionReset>(_onReset);
  }

  void _onPasswordEntered(
    AccountDeletionPasswordEntered event,
    Emitter<AccountDeletionState> emit,
  ) {
    if (event.password.isEmpty) {
      emit(const AccountDeletionState.initial());
    } else {
      emit(AccountDeletionState.waitingConfirmation(
        password: event.password,
        confirmationText: state.confirmationText,
      ));
    }
  }

  void _onConfirmationEntered(
    AccountDeletionConfirmationEntered event,
    Emitter<AccountDeletionState> emit,
  ) {
    emit(AccountDeletionState.waitingConfirmation(
      password: state.password ?? '',
      confirmationText: event.confirmationText,
    ));
  }

  Future<void> _onDeletionRequested(
    AccountDeletionRequested event,
    Emitter<AccountDeletionState> emit,
  ) async {
    if (!state.canDelete) {
      emit(const AccountDeletionState.failure(
          AccountDeletionError.invalidConfirmation));
      return;
    }

    // 빈 비밀번호로는 탈퇴를 진행하지 않는다(null뿐 아니라 빈 문자열도 차단).
    final password = state.password;
    if (password == null || password.isEmpty) {
      emit(const AccountDeletionState.failure(
          AccountDeletionError.emptyPassword));
      return;
    }

    emit(const AccountDeletionState.deleting());

    try {
      // 현재 사용자 ID 가져오기
      final userId = await _authRepository.getCurrentUserId();
      if (userId == null) {
        emit(const AccountDeletionState.failure(
            AccountDeletionError.userNotFound));
        return;
      }

      // 회원 탈퇴 요청
      await _settingsRepository.deleteAccount(userId, password);

      emit(const AccountDeletionState.deleted());
    } catch (e, stackTrace) {
      // 디버그 모드에서 상세 에러 로깅
      assert(() {
        // ignore: avoid_print
        print('[AccountDeletionBloc] Error: $e');
        // ignore: avoid_print
        print('[AccountDeletionBloc] StackTrace: $stackTrace');
        return true;
      }());

      // 인식되지 않은(알 수 없는) 에러면 더 구체적인 안내로 대체한다.
      // 사용자 표시 메시지의 부분 문자열 매칭 대신 타입 기반으로 판별한다.
      if (ErrorMessageMapper.isUnknownError(e)) {
        emit(const AccountDeletionState.failure(AccountDeletionError.unknown));
      } else {
        emit(AccountDeletionState.error(ErrorMessageMapper.toUserFriendlyMessage(e)));
      }
    }
  }

  void _onReset(
    AccountDeletionReset event,
    Emitter<AccountDeletionState> emit,
  ) {
    emit(const AccountDeletionState.initial());
  }
}
