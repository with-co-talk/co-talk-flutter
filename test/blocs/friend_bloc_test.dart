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

  setUp(() {
    mockFriendRepository = MockFriendRepository();
  });

  group('FriendBloc', () {
    test('initial state is FriendState with initial status', () {
      final bloc = FriendBloc(mockFriendRepository);
      expect(bloc.state.status, FriendStatus.initial);
      expect(bloc.state.friends, isEmpty);
      expect(bloc.state.searchResults, isEmpty);
    });

    group('FriendListLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading, success] when getFriends succeeds',
        build: () {
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => FakeEntities.friends);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendListLoadRequested()),
        expect: () => [
          const FriendState(status: FriendStatus.loading),
          FriendState(
            status: FriendStatus.success,
            friends: FakeEntities.friends,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading, success] with empty list when no friends',
        build: () {
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendListLoadRequested()),
        expect: () => [
          const FriendState(status: FriendStatus.loading),
          const FriendState(status: FriendStatus.success, friends: []),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading, failure] when getFriends fails',
        build: () {
          when(() => mockFriendRepository.getFriends())
              .thenThrow(Exception('Network error'));
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendListLoadRequested()),
        expect: () => [
          const FriendState(status: FriendStatus.loading),
          isA<FriendState>().having(
            (s) => s.status,
            'status',
            FriendStatus.failure,
          ),
        ],
      );
    });

    group('FriendRequestSent', () {
      blocTest<FriendBloc, FriendState>(
        'sends friend request successfully',
        build: () {
          when(() => mockFriendRepository.sendFriendRequest(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestSent(2)),
        expect: () => [],
        verify: (_) {
          verify(() => mockFriendRepository.sendFriendRequest(2)).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when sendFriendRequest fails',
        build: () {
          when(() => mockFriendRepository.sendFriendRequest(any()))
              .thenThrow(Exception('Already sent request'));
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestSent(2)),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('FriendRequestAccepted', () {
      blocTest<FriendBloc, FriendState>(
        'accepts friend request and reloads list',
        build: () {
          when(() => mockFriendRepository.acceptFriendRequest(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => FakeEntities.friends);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestAccepted(1)),
        expect: () => [
          const FriendState(status: FriendStatus.loading),
          FriendState(
            status: FriendStatus.success,
            friends: FakeEntities.friends,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.acceptFriendRequest(1)).called(1);
          verify(() => mockFriendRepository.getFriends()).called(1);
        },
      );
    });

    group('FriendRequestRejected', () {
      blocTest<FriendBloc, FriendState>(
        'rejects friend request successfully',
        build: () {
          when(() => mockFriendRepository.rejectFriendRequest(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestRejected(1)),
        expect: () => [],
        verify: (_) {
          verify(() => mockFriendRepository.rejectFriendRequest(1)).called(1);
        },
      );
    });

    group('FriendRemoved', () {
      blocTest<FriendBloc, FriendState>(
        'removes friend and updates list',
        build: () {
          when(() => mockFriendRepository.removeFriend(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(const FriendRemoved(2)), // otherUser.id
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends.any((f) => f.user.id == 2),
            'contains removed friend',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.removeFriend(2)).called(1);
        },
      );
    });

    group('UserSearchRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [isSearching=true, searchResults] when search succeeds',
        build: () {
          when(() => mockFriendRepository.searchUsers(any()))
              .thenAnswer((_) async => [FakeEntities.user, FakeEntities.otherUser]);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const UserSearchRequested('test')),
        expect: () => [
          const FriendState(isSearching: true),
          FriendState(
            isSearching: false,
            searchResults: [FakeEntities.user, FakeEntities.otherUser],
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.searchUsers('test')).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'clears search results when query is empty',
        build: () => FriendBloc(mockFriendRepository),
        seed: () => FriendState(
          searchResults: [FakeEntities.user],
          isSearching: false,
        ),
        act: (bloc) => bloc.add(const UserSearchRequested('')),
        expect: () => [
          const FriendState(searchResults: [], isSearching: false),
        ],
        verify: (_) {
          verifyNever(() => mockFriendRepository.searchUsers(any()));
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error when search fails',
        build: () {
          when(() => mockFriendRepository.searchUsers(any()))
              .thenThrow(Exception('Search failed'));
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const UserSearchRequested('test')),
        expect: () => [
          const FriendState(isSearching: true),
          isA<FriendState>()
              .having((s) => s.isSearching, 'isSearching', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });
  });
}
