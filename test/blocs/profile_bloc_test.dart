import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_event.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_state.dart';
import '../mocks/mock_repositories.dart';

class FakeFile extends Fake implements File {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(ProfileHistoryType.avatar);
  });

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
  });

  ProfileBloc createBloc() => ProfileBloc(
        mockProfileRepository,
        mockAuthRepository,
      );

  final testHistory1 = ProfileHistory(
    id: 1,
    userId: 100,
    type: ProfileHistoryType.avatar,
    url: 'https://example.com/avatar.jpg',
    isPrivate: false,
    isCurrent: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final testHistory2 = ProfileHistory(
    id: 2,
    userId: 100,
    type: ProfileHistoryType.statusMessage,
    content: 'Hello world',
    isPrivate: false,
    isCurrent: true,
    createdAt: DateTime(2024, 1, 2),
  );

  final testHistory3 = ProfileHistory(
    id: 3,
    userId: 100,
    type: ProfileHistoryType.avatar,
    url: 'https://example.com/old-avatar.jpg',
    isPrivate: false,
    isCurrent: false,
    createdAt: DateTime(2024, 1, 3),
  );

  group('ProfileBloc', () {
    test('initial state should be ProfileState.initial', () {
      final bloc = createBloc();
      expect(bloc.state, const ProfileState.initial());
    });

    group('ProfileHistoryLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'should emit loading then loaded when successful',
        build: () {
          when(() => mockProfileRepository.getProfileHistory(
                any(),
                type: any(named: 'type'),
              )).thenAnswer((_) async => [testHistory1, testHistory2]);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryLoadRequested(userId: 100)),
        expect: () => [
          const ProfileState(
            status: ProfileStatus.loading,
            filterType: null,
          ),
          ProfileState(
            status: ProfileStatus.loaded,
            histories: [testHistory1, testHistory2],
            filterType: null,
          ),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.getProfileHistory(100, type: null)).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'should emit loading then failure when error',
        build: () {
          when(() => mockProfileRepository.getProfileHistory(
                any(),
                type: any(named: 'type'),
              )).thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryLoadRequested(userId: 100)),
        expect: () => [
          const ProfileState(
            status: ProfileStatus.loading,
            filterType: null,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should filter by type when type provided',
        build: () {
          when(() => mockProfileRepository.getProfileHistory(
                any(),
                type: any(named: 'type'),
              )).thenAnswer((_) async => [testHistory1]);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryLoadRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
        )),
        expect: () => [
          const ProfileState(
            status: ProfileStatus.loading,
            filterType: ProfileHistoryType.avatar,
          ),
          ProfileState(
            status: ProfileStatus.loaded,
            histories: [testHistory1],
            filterType: ProfileHistoryType.avatar,
          ),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.getProfileHistory(
                100,
                type: ProfileHistoryType.avatar,
              )).called(1);
        },
      );
    });

    group('ProfileHistoryCreateRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'should emit creating then success when successful',
        build: () {
          when(() => mockProfileRepository.createProfileHistory(
                userId: any(named: 'userId'),
                type: any(named: 'type'),
                url: any(named: 'url'),
                content: any(named: 'content'),
                isPrivate: any(named: 'isPrivate'),
                setCurrent: any(named: 'setCurrent'),
              )).thenAnswer((_) async => testHistory1);
          return createBloc();
        },
        act: (bloc) => bloc.add(ProfileHistoryCreateRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
          content: 'Test',
        )),
        expect: () => [
          const ProfileState(status: ProfileStatus.creating),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory1],
            successMessage: '프로필이 업데이트되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should upload image first when imageFile provided',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenAnswer((_) async => 'https://example.com/uploaded.jpg');
          when(() => mockProfileRepository.createProfileHistory(
                userId: any(named: 'userId'),
                type: any(named: 'type'),
                url: any(named: 'url'),
                content: any(named: 'content'),
                isPrivate: any(named: 'isPrivate'),
                setCurrent: any(named: 'setCurrent'),
              )).thenAnswer((_) async => testHistory1);
          return createBloc();
        },
        act: (bloc) => bloc.add(ProfileHistoryCreateRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
          imageFile: File('test.jpg'),
        )),
        expect: () => [
          const ProfileState(status: ProfileStatus.creating),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory1],
            successMessage: '프로필이 업데이트되었습니다.',
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.uploadAvatar(any())).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'should emit creating then failure when error',
        build: () {
          when(() => mockProfileRepository.createProfileHistory(
                userId: any(named: 'userId'),
                type: any(named: 'type'),
                url: any(named: 'url'),
                content: any(named: 'content'),
                isPrivate: any(named: 'isPrivate'),
                setCurrent: any(named: 'setCurrent'),
              )).thenThrow(Exception('Creation failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryCreateRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
        )),
        expect: () => [
          const ProfileState(status: ProfileStatus.creating),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should update histories list with new item',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory2],
        ),
        build: () {
          when(() => mockProfileRepository.createProfileHistory(
                userId: any(named: 'userId'),
                type: any(named: 'type'),
                url: any(named: 'url'),
                content: any(named: 'content'),
                isPrivate: any(named: 'isPrivate'),
                setCurrent: any(named: 'setCurrent'),
              )).thenAnswer((_) async => testHistory1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryCreateRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.creating,
            histories: [testHistory2],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory1, testHistory2],
            successMessage: '프로필이 업데이트되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should update isCurrent flags when setCurrent is true',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory3],
        ),
        build: () {
          when(() => mockProfileRepository.createProfileHistory(
                userId: any(named: 'userId'),
                type: any(named: 'type'),
                url: any(named: 'url'),
                content: any(named: 'content'),
                isPrivate: any(named: 'isPrivate'),
                setCurrent: any(named: 'setCurrent'),
              )).thenAnswer((_) async => testHistory1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryCreateRequested(
          userId: 100,
          type: ProfileHistoryType.avatar,
          setCurrent: true,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.creating,
            histories: [testHistory3],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              testHistory1,
              testHistory3.copyWith(isCurrent: false),
            ],
            successMessage: '프로필이 업데이트되었습니다.',
          ),
        ],
      );
    });

    group('ProfileHistoryPrivacyToggled', () {
      blocTest<ProfileBloc, ProfileState>(
        'should emit updating then success when successful',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1],
        ),
        build: () {
          when(() => mockProfileRepository.updateProfileHistory(
                any(),
                any(),
                isPrivate: any(named: 'isPrivate'),
              )).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryPrivacyToggled(
          userId: 100,
          historyId: 1,
          isPrivate: true,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory1.copyWith(isPrivate: true)],
            successMessage: '나만보기로 설정되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should update local history isPrivate flag',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1, testHistory2],
        ),
        build: () {
          when(() => mockProfileRepository.updateProfileHistory(
                any(),
                any(),
                isPrivate: any(named: 'isPrivate'),
              )).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryPrivacyToggled(
          userId: 100,
          historyId: 1,
          isPrivate: true,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1, testHistory2],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              testHistory1.copyWith(isPrivate: true),
              testHistory2,
            ],
            successMessage: '나만보기로 설정되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should emit updating then failure when error',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1],
        ),
        build: () {
          when(() => mockProfileRepository.updateProfileHistory(
                any(),
                any(),
                isPrivate: any(named: 'isPrivate'),
              )).thenThrow(Exception('Update failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryPrivacyToggled(
          userId: 100,
          historyId: 1,
          isPrivate: true,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1],
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ProfileHistoryDeleteRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'should emit deleting then success when successful',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1],
        ),
        build: () {
          when(() => mockProfileRepository.deleteProfileHistory(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryDeleteRequested(
          userId: 100,
          historyId: 1,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.deleting,
            histories: [testHistory1],
          ),
          const ProfileState(
            status: ProfileStatus.success,
            histories: [],
            successMessage: '프로필 이력이 삭제되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should remove history from list',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1, testHistory2],
        ),
        build: () {
          when(() => mockProfileRepository.deleteProfileHistory(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryDeleteRequested(
          userId: 100,
          historyId: 1,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.deleting,
            histories: [testHistory1, testHistory2],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory2],
            successMessage: '프로필 이력이 삭제되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should promote next to current when deleting current',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1, testHistory3],
        ),
        build: () {
          when(() => mockProfileRepository.deleteProfileHistory(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryDeleteRequested(
          userId: 100,
          historyId: 1,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.deleting,
            histories: [testHistory1, testHistory3],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [testHistory3.copyWith(isCurrent: true)],
            successMessage: '프로필 이력이 삭제되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should emit deleting then failure when error',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1],
        ),
        build: () {
          when(() => mockProfileRepository.deleteProfileHistory(any(), any()))
              .thenThrow(Exception('Delete failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistoryDeleteRequested(
          userId: 100,
          historyId: 1,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.deleting,
            histories: [testHistory1],
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ProfileHistorySetCurrentRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'should emit updating then success when successful',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1, testHistory3],
        ),
        build: () {
          when(() => mockProfileRepository.setCurrentProfile(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistorySetCurrentRequested(
          userId: 100,
          historyId: 3,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1, testHistory3],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              testHistory1.copyWith(isCurrent: false),
              testHistory3.copyWith(isCurrent: true),
            ],
            successMessage: '현재 프로필로 설정되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should update isCurrent flags in list',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1, testHistory2, testHistory3],
        ),
        build: () {
          when(() => mockProfileRepository.setCurrentProfile(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistorySetCurrentRequested(
          userId: 100,
          historyId: 3,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1, testHistory2, testHistory3],
          ),
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              testHistory1.copyWith(isCurrent: false),
              testHistory2,
              testHistory3.copyWith(isCurrent: true),
            ],
            successMessage: '현재 프로필로 설정되었습니다.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'should emit updating then failure when error',
        seed: () => ProfileState(
          status: ProfileStatus.loaded,
          histories: [testHistory1],
        ),
        build: () {
          when(() => mockProfileRepository.setCurrentProfile(any(), any()))
              .thenThrow(Exception('Set current failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ProfileHistorySetCurrentRequested(
          userId: 100,
          historyId: 1,
        )),
        expect: () => [
          ProfileState(
            status: ProfileStatus.updating,
            histories: [testHistory1],
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });
  });
}
