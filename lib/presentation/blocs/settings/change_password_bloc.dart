import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

/// 비밀번호 변경 BLoC
@injectable
class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final SettingsRepository _settingsRepository;

  ChangePasswordBloc(this._settingsRepository)
      : super(const ChangePasswordState.initial()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
    on<ChangePasswordReset>(_onReset);
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordState.loading());

    try {
      await _settingsRepository.changePassword(
        event.currentPassword,
        event.newPassword,
      );
      emit(const ChangePasswordState.success());
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      if (message.contains('알 수 없는 오류')) {
        emit(ChangePasswordState.error('비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.'));
      } else {
        emit(ChangePasswordState.error(message));
      }
    }
  }

  void _onReset(
    ChangePasswordReset event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(const ChangePasswordState.initial());
  }
}
