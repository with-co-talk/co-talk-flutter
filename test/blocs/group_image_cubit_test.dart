import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/group_image_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/group_image_state.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockFile extends Mock implements File {}

void main() {
  late GroupImageCubit cubit;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    cubit = GroupImageCubit(mockRepository);
  });

  tearDown(() => cubit.close());

  setUpAll(() {
    registerFallbackValue(MockFile());
  });

  group('GroupImageCubit', () {
    blocTest<GroupImageCubit, GroupImageState>(
      'should upload and update group image successfully',
      build: () {
        when(() => mockRepository.uploadFile(any()))
            .thenAnswer((_) async => const FileUploadResult(
                  fileUrl: 'http://example.com/image.jpg',
                  fileName: 'image.jpg',
                  contentType: 'image/jpeg',
                  fileSize: 1024,
                  isImage: true,
                ));
        when(() => mockRepository.updateChatRoomImage(any(), any()))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.updateGroupImage(1, MockFile()),
      expect: () => [
        const GroupImageState(status: GroupImageStatus.uploading),
        const GroupImageState(
          status: GroupImageStatus.success,
          imageUrl: 'http://example.com/image.jpg',
        ),
      ],
    );

    blocTest<GroupImageCubit, GroupImageState>(
      'should handle upload error',
      build: () {
        when(() => mockRepository.uploadFile(any()))
            .thenThrow(Exception('Upload failed'));
        return cubit;
      },
      act: (cubit) => cubit.updateGroupImage(1, MockFile()),
      expect: () => [
        const GroupImageState(status: GroupImageStatus.uploading),
        const GroupImageState(
          status: GroupImageStatus.error,
          errorMessage: '이미지 변경에 실패했습니다.',
        ),
      ],
    );

    blocTest<GroupImageCubit, GroupImageState>(
      'should reset state',
      build: () => cubit,
      seed: () => const GroupImageState(
        status: GroupImageStatus.success,
        imageUrl: 'http://example.com/image.jpg',
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [const GroupImageState()],
    );
  });
}
