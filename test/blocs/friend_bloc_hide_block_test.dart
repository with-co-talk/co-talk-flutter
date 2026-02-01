import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

void main() {
  late MockFriendRepository mockFriendRepository;
  late MockWebSocketService mockWebSocketService;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    mockWebSocketService = MockWebSocketService();

    // Setup default WebSocket behavior
    when(() => mockWebSocketService.onlineStatusEvents).thenAnswer((_) => const Stream.empty());
  });

  group('FriendBloc - Hide/Block Events', () {
    group('HideFriendRequested', () {
      blocTest<FriendBloc, FriendState>(
        'calls hideFriend and refreshes friends list on success',
        build: () {
          when(() => mockFriendRepository.hideFriend(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HideFriendRequested(2)),
        expect: () => [
          // Updated friends list
          const FriendState(
            friends: [],
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.hideFriend(2)).called(1);
          verify(() => mockFriendRepository.getFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'removes hidden friend from friends list',
        build: () {
          when(() => mockFriendRepository.hideFriend(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => [FakeEntities.friends.first]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(friends: FakeEntities.friends),
        act: (bloc) => bloc.add(const HideFriendRequested(3)), // Friend2's id
        expect: () => [
          // Updated friends list (only first friend remains)
          FriendState(
            friends: [FakeEntities.friends.first],
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when hideFriend fails',
        build: () {
          when(() => mockFriendRepository.hideFriend(any()))
              .thenThrow(Exception('Hide friend failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HideFriendRequested(2)),
        skip: 1, // Skip clearErrorMessage emission
        expect: () => [
          // Error state
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.hideFriend(2)).called(1);
          verifyNever(() => mockFriendRepository.getFriends());
        },
      );
    });

    group('UnhideFriendRequested', () {
      blocTest<FriendBloc, FriendState>(
        'calls unhideFriend and refreshes hidden friends list on success',
        build: () {
          when(() => mockFriendRepository.unhideFriend(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnhideFriendRequested(2)),
        expect: () => [
          // Updated hidden friends list
          const FriendState(
            hiddenFriends: [],
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unhideFriend(2)).called(1);
          verify(() => mockFriendRepository.getHiddenFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'removes unhidden friend from hidden friends list',
        build: () {
          when(() => mockFriendRepository.unhideFriend(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => [FakeEntities.friends.first]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(hiddenFriends: FakeEntities.friends),
        act: (bloc) => bloc.add(const UnhideFriendRequested(3)), // Friend2's id
        expect: () => [
          // Updated hidden friends list (only first friend remains)
          FriendState(
            hiddenFriends: [FakeEntities.friends.first],
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when unhideFriend fails',
        build: () {
          when(() => mockFriendRepository.unhideFriend(any()))
              .thenThrow(Exception('Unhide friend failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnhideFriendRequested(2)),
        skip: 1, // Skip clearErrorMessage emission
        expect: () => [
          // Error state
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unhideFriend(2)).called(1);
          verifyNever(() => mockFriendRepository.getHiddenFriends());
        },
      );
    });

    group('HiddenFriendsLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, hiddenFriends, loading=false] when getHiddenFriends succeeds',
        build: () {
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => FakeEntities.friends);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HiddenFriendsLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isHiddenFriendsLoading: true,
            errorMessage: null,
          ),
          // Second: success with hidden friends
          FriendState(
            hiddenFriends: FakeEntities.friends,
            isHiddenFriendsLoading: false,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getHiddenFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits empty list when no hidden friends',
        build: () {
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HiddenFriendsLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isHiddenFriendsLoading: true,
            errorMessage: null,
          ),
          // Second: success with empty list
          const FriendState(
            hiddenFriends: [],
            isHiddenFriendsLoading: false,
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, loading=false, error] when getHiddenFriends fails',
        build: () {
          when(() => mockFriendRepository.getHiddenFriends())
              .thenThrow(Exception('Network error'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HiddenFriendsLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isHiddenFriendsLoading: true,
            errorMessage: null,
          ),
          // Second: error state
          isA<FriendState>()
              .having((s) => s.isHiddenFriendsLoading, 'isHiddenFriendsLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('BlockUserRequested', () {
      blocTest<FriendBloc, FriendState>(
        'calls blockUser and refreshes friends list on success',
        build: () {
          when(() => mockFriendRepository.blockUser(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockUserRequested(2)),
        expect: () => [
          // Updated friends list
          const FriendState(
            friends: [],
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.blockUser(2)).called(1);
          verify(() => mockFriendRepository.getFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'removes blocked user from friends list',
        build: () {
          when(() => mockFriendRepository.blockUser(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => [FakeEntities.friends.first]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(friends: FakeEntities.friends),
        act: (bloc) => bloc.add(const BlockUserRequested(3)), // Friend2's id
        expect: () => [
          // Updated friends list (only first friend remains)
          FriendState(
            friends: [FakeEntities.friends.first],
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when blockUser fails',
        build: () {
          when(() => mockFriendRepository.blockUser(any()))
              .thenThrow(Exception('Block user failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockUserRequested(2)),
        skip: 1, // Skip clearErrorMessage emission
        expect: () => [
          // Error state
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.blockUser(2)).called(1);
          verifyNever(() => mockFriendRepository.getFriends());
        },
      );
    });

    group('UnblockUserRequested', () {
      blocTest<FriendBloc, FriendState>(
        'calls unblockUser and refreshes blocked users list on success',
        build: () {
          when(() => mockFriendRepository.unblockUser(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnblockUserRequested(2)),
        expect: () => [
          // Updated blocked users list
          const FriendState(
            blockedUsers: [],
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unblockUser(2)).called(1);
          verify(() => mockFriendRepository.getBlockedUsers()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'removes unblocked user from blocked users list',
        build: () {
          when(() => mockFriendRepository.unblockUser(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => [FakeEntities.otherUser]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(blockedUsers: [FakeEntities.user, FakeEntities.otherUser]),
        act: (bloc) => bloc.add(const UnblockUserRequested(1)), // user's id
        expect: () => [
          // Updated blocked users list (only otherUser remains)
          FriendState(
            blockedUsers: [FakeEntities.otherUser],
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when unblockUser fails',
        build: () {
          when(() => mockFriendRepository.unblockUser(any()))
              .thenThrow(Exception('Unblock user failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnblockUserRequested(2)),
        skip: 1, // Skip clearErrorMessage emission
        expect: () => [
          // Error state
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unblockUser(2)).called(1);
          verifyNever(() => mockFriendRepository.getBlockedUsers());
        },
      );
    });

    group('BlockedUsersLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, blockedUsers, loading=false] when getBlockedUsers succeeds',
        build: () {
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => [FakeEntities.user, FakeEntities.otherUser]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockedUsersLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isBlockedUsersLoading: true,
            errorMessage: null,
          ),
          // Second: success with blocked users
          FriendState(
            blockedUsers: [FakeEntities.user, FakeEntities.otherUser],
            isBlockedUsersLoading: false,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getBlockedUsers()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits empty list when no blocked users',
        build: () {
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockedUsersLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isBlockedUsersLoading: true,
            errorMessage: null,
          ),
          // Second: success with empty list
          const FriendState(
            blockedUsers: [],
            isBlockedUsersLoading: false,
            errorMessage: null,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, loading=false, error] when getBlockedUsers fails',
        build: () {
          when(() => mockFriendRepository.getBlockedUsers())
              .thenThrow(Exception('Network error'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockedUsersLoadRequested()),
        expect: () => [
          // First: loading state
          const FriendState(
            isBlockedUsersLoading: true,
            errorMessage: null,
          ),
          // Second: error state
          isA<FriendState>()
              .having((s) => s.isBlockedUsersLoading, 'isBlockedUsersLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });
  });
}
