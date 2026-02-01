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
    if (!state.canDelete || state.password == null) {
      emit(AccountDeletionState.error('올바른 확인 텍스트를 입력해주세요'));
      return;
    }

    emit(const AccountDeletionState.deleting());

    try {
      // 현재 사용자 ID 가져오기
      final userId = await _authRepository.getCurrentUserId();
      if (userId == null) {
        emit(AccountDeletionState.error('사용자 정보를 찾을 수 없습니다'));
        return;
      }

      // 회원 탈퇴 요청
      await _settingsRepository.deleteAccount(userId, state.password!);

      emit(const AccountDeletionState.deleted());
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AccountDeletionState.error(message));
    }
  }

  void _onReset(
    AccountDeletionReset event,
    Emitter<AccountDeletionState> emit,
  ) {
    emit(const AccountDeletionState.initial());
  }
}
