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
        'sends friend request successfully and refreshes sent requests',
        build: () {
          when(() => mockFriendRepository.sendFriendRequest(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getSentFriendRequests())
              .thenAnswer((_) async => FakeEntities.sentFriendRequests);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestSent(2)),
        expect: () => [
          // First: clearErrorMessage (same as initial, so Equatable may dedupe)
          const FriendState(),
          // Second: getSentFriendRequests succeeds
          FriendState(sentRequests: FakeEntities.sentFriendRequests),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.sendFriendRequest(2)).called(1);
          verify(() => mockFriendRepository.getSentFriendRequests()).called(1);
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
          // First: clearErrorMessage (same as initial)
          const FriendState(),
          // Second: error
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
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestAccepted(1)),
        expect: () => [
          // First: clearErrorMessage
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          // Second: success with friends and receivedRequests
          FriendState(
            status: FriendStatus.success,
            friends: FakeEntities.friends,
            receivedRequests: FakeEntities.receivedFriendRequests,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.acceptFriendRequest(1)).called(1);
          verify(() => mockFriendRepository.getFriends()).called(1);
          verify(() => mockFriendRepository.getReceivedFriendRequests()).called(1);
        },
      );
    });

    group('FriendRequestRejected', () {
      blocTest<FriendBloc, FriendState>(
        'rejects friend request successfully',
        build: () {
          when(() => mockFriendRepository.rejectFriendRequest(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const FriendRequestRejected(1)),
        expect: () => [
          // First: clearErrorMessage
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          // Second: updated receivedRequests
          FriendState(
            receivedRequests: FakeEntities.receivedFriendRequests,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.rejectFriendRequest(1)).called(1);
          verify(() => mockFriendRepository.getReceivedFriendRequests()).called(1);
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
          const FriendState(
            isSearching: true,
            hasSearched: true,
            searchQuery: 'test',
          ),
          FriendState(
            isSearching: false,
            hasSearched: true,
            searchQuery: 'test',
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
          hasSearched: true,
          searchQuery: 'previous',
        ),
        act: (bloc) => bloc.add(const UserSearchRequested('')),
        expect: () => [
          const FriendState(
            searchResults: [],
            isSearching: false,
            hasSearched: false,
            searchQuery: null,
          ),
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
          const FriendState(
            isSearching: true,
            hasSearched: true,
            searchQuery: 'test',
          ),
          isA<FriendState>()
              .having((s) => s.isSearching, 'isSearching', false)
              .having((s) => s.hasSearched, 'hasSearched', true)
              .having((s) => s.searchQuery, 'searchQuery', 'test')
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ReceivedFriendRequestsLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits receivedRequests when getReceivedFriendRequests succeeds',
        build: () {
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const ReceivedFriendRequestsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          FriendState(
            receivedRequests: FakeEntities.receivedFriendRequests,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getReceivedFriendRequests()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when getReceivedFriendRequests fails',
        build: () {
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenThrow(Exception('Network error'));
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const ReceivedFriendRequestsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('SentFriendRequestsLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits sentRequests when getSentFriendRequests succeeds',
        build: () {
          when(() => mockFriendRepository.getSentFriendRequests())
              .thenAnswer((_) async => FakeEntities.sentFriendRequests);
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const SentFriendRequestsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          FriendState(
            sentRequests: FakeEntities.sentFriendRequests,
            errorMessage: null,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getSentFriendRequests()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when getSentFriendRequests fails',
        build: () {
          when(() => mockFriendRepository.getSentFriendRequests())
              .thenThrow(Exception('Network error'));
          return FriendBloc(mockFriendRepository);
        },
        act: (bloc) => bloc.add(const SentFriendRequestsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });
  });
}
