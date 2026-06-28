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
      // 인식되지 않은(알 수 없는) 에러면 도메인 특화 안내로 대체한다.
      // 사용자 표시 메시지의 부분 문자열 매칭 대신 타입 기반으로 판별한다.
      if (ErrorMessageMapper.isUnknownError(e)) {
        emit(ChangePasswordState.error('비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.'));
      } else {
        emit(ChangePasswordState.error(ErrorMessageMapper.toUserFriendlyMessage(e)));
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
