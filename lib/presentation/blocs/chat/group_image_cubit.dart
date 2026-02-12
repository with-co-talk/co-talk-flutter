import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'group_image_state.dart';

/// 그룹 채팅방 이미지 관리 Cubit
@injectable
class GroupImageCubit extends Cubit<GroupImageState> {
  final ChatRepository _chatRepository;

  GroupImageCubit(this._chatRepository) : super(const GroupImageState());

  /// 이미지 업로드 및 채팅방 이미지 변경
  Future<void> updateGroupImage(int roomId, File imageFile) async {
    emit(state.copyWith(status: GroupImageStatus.uploading));

    try {
      // 1. 파일 업로드
      final uploadResult = await _chatRepository.uploadFile(imageFile);

      // 2. 채팅방 이미지 URL 업데이트
      await _chatRepository.updateChatRoomImage(roomId, uploadResult.fileUrl);

      emit(state.copyWith(
        status: GroupImageStatus.success,
        imageUrl: uploadResult.fileUrl,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GroupImageStatus.error,
        errorMessage: '이미지 변경에 실패했습니다.',
      ));
    }
  }

  /// 상태 초기화
  void reset() {
    emit(const GroupImageState());
  }
}
