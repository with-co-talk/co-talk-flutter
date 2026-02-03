import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/profile_history.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  ProfileBloc(this._profileRepository, this._authRepository)
      : super(const ProfileState.initial()) {
    on<ProfileUserLoadRequested>(_onUserLoadRequested);
    on<ProfileHistoryLoadRequested>(_onLoadRequested);
    on<ProfileHistoryCreateRequested>(_onCreateRequested);
    on<ProfileHistoryPrivacyToggled>(_onPrivacyToggled);
    on<ProfileHistoryDeleteRequested>(_onDeleteRequested);
    on<ProfileHistorySetCurrentRequested>(_onSetCurrentRequested);
  }

  Future<void> _onUserLoadRequested(
    ProfileUserLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.loading,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      final user = await _profileRepository.getUserById(event.userId);

      emit(state.copyWith(
        status: ProfileStatus.loaded,
        viewingUser: user,
      ));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onLoadRequested(
    ProfileHistoryLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // ignore: avoid_print
    print('[ProfileBloc] _onLoadRequested: userId=${event.userId}, type=${event.type}');

    emit(state.copyWith(
      status: ProfileStatus.loading,
      filterType: event.type,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      final histories = await _profileRepository.getProfileHistory(
        event.userId,
        type: event.type,
      );

      // ignore: avoid_print
      print('[ProfileBloc] Loaded ${histories.length} histories: ${histories.map((h) => 'id=${h.id}, type=${h.type}, url=${h.url}').toList()}');

      emit(state.copyWith(
        status: ProfileStatus.loaded,
        histories: histories,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[ProfileBloc] Error loading histories: $e');
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onCreateRequested(
    ProfileHistoryCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // ignore: avoid_print
    print('[ProfileBloc] _onCreateRequested: userId=${event.userId}, type=${event.type}');

    emit(state.copyWith(
      status: ProfileStatus.creating,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      String? url;

      // 이미지 업로드가 필요한 경우
      if (event.imageFile != null) {
        url = await _authRepository.uploadAvatar(event.imageFile!);
        // ignore: avoid_print
        print('[ProfileBloc] Uploaded file, url=$url');
      }

      final created = await _profileRepository.createProfileHistory(
        userId: event.userId,
        type: event.type,
        url: url,
        content: event.content,
        isPrivate: event.isPrivate,
        setCurrent: event.setCurrent,
      );

      // ignore: avoid_print
      print('[ProfileBloc] Created history: id=${created.id}, type=${created.type}, url=${created.url}');

      // 목록에 새 이력 추가
      final updatedHistories = [created, ...state.histories];

      // setCurrent가 true면 같은 유형의 다른 isCurrent를 false로 변경
      final finalHistories = event.setCurrent
          ? updatedHistories.map((h) {
              if (h.type == event.type && h.id != created.id && h.isCurrent) {
                return h.copyWith(isCurrent: false);
              }
              return h;
            }).toList()
          : updatedHistories;

      // setCurrent가 true면 viewingUser도 업데이트
      User? updatedUser = state.viewingUser;
      if (event.setCurrent && state.viewingUser != null) {
        switch (event.type) {
          case ProfileHistoryType.avatar:
            updatedUser = state.viewingUser!.copyWith(avatarUrl: created.url);
            break;
          case ProfileHistoryType.background:
            updatedUser = state.viewingUser!.copyWith(backgroundUrl: created.url);
            break;
          case ProfileHistoryType.statusMessage:
            updatedUser = state.viewingUser!.copyWith(statusMessage: created.content);
            break;
        }
      }

      emit(state.copyWith(
        status: ProfileStatus.success,
        histories: finalHistories,
        viewingUser: updatedUser,
        successMessage: '프로필이 업데이트되었습니다.',
      ));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onPrivacyToggled(
    ProfileHistoryPrivacyToggled event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.updating,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      await _profileRepository.updateProfileHistory(
        event.userId,
        event.historyId,
        isPrivate: event.isPrivate,
      );

      // 로컬 상태 업데이트
      final updatedHistories = state.histories.map((h) {
        if (h.id == event.historyId) {
          return h.copyWith(isPrivate: event.isPrivate);
        }
        return h;
      }).toList();

      emit(state.copyWith(
        status: ProfileStatus.success,
        histories: updatedHistories,
        successMessage: event.isPrivate ? '나만보기로 설정되었습니다.' : '공개로 설정되었습니다.',
      ));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    ProfileHistoryDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.deleting,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      await _profileRepository.deleteProfileHistory(event.userId, event.historyId);

      // 삭제된 이력 제거
      final deletedHistory = state.histories.firstWhere((h) => h.id == event.historyId);
      final updatedHistories = state.histories
          .where((h) => h.id != event.historyId)
          .toList();

      // 삭제된 것이 current였다면 같은 타입의 첫 번째 이력을 current로 설정
      final finalHistories = deletedHistory.isCurrent
          ? _promoteNextToCurrent(updatedHistories, deletedHistory.type)
          : updatedHistories;

      emit(state.copyWith(
        status: ProfileStatus.success,
        histories: finalHistories,
        successMessage: '프로필 이력이 삭제되었습니다.',
      ));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onSetCurrentRequested(
    ProfileHistorySetCurrentRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.updating,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      await _profileRepository.setCurrentProfile(event.userId, event.historyId);

      // 로컬 상태 업데이트
      final targetHistory = state.histories.firstWhere((h) => h.id == event.historyId);
      final updatedHistories = state.histories.map((h) {
        if (h.type == targetHistory.type) {
          return h.copyWith(isCurrent: h.id == event.historyId);
        }
        return h;
      }).toList();

      emit(state.copyWith(
        status: ProfileStatus.success,
        histories: updatedHistories,
        successMessage: '현재 프로필로 설정되었습니다.',
      ));
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: message,
      ));
    }
  }

  /// 삭제 후 같은 타입의 다음 이력을 current로 승격
  List<ProfileHistory> _promoteNextToCurrent(
    List<ProfileHistory> histories,
    ProfileHistoryType type,
  ) {
    final sameTypeHistories = histories.where((h) => h.type == type).toList();
    if (sameTypeHistories.isEmpty) return histories;

    final nextCurrent = sameTypeHistories.first;
    return histories.map((h) {
      if (h.id == nextCurrent.id) {
        return h.copyWith(isCurrent: true);
      }
      return h;
    }).toList();
  }
}
