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

  group('FriendBloc', () {
    test('initial state is FriendState with initial status', () {
      final bloc = FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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

    group('Friend request in-flight guard (4th-review P3)', () {
      blocTest<FriendBloc, FriendState>(
        'ignores a duplicate accept for the same requestId while in flight',
        build: () {
          when(() => mockFriendRepository.acceptFriendRequest(any()))
              .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
          });
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => FakeEntities.friends);
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) {
          // Double tap before the first accept resolves.
          bloc.add(const FriendRequestAccepted(1));
          bloc.add(const FriendRequestAccepted(1));
        },
        wait: const Duration(milliseconds: 150),
        verify: (bloc) {
          // The repository must be hit only once — no 409/400 false error.
          verify(() => mockFriendRepository.acceptFriendRequest(1)).called(1);
          expect(bloc.state.processingRequestIds, isEmpty);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'marks requestId as processing while accept is in flight',
        build: () {
          when(() => mockFriendRepository.acceptFriendRequest(any()))
              .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
          });
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => FakeEntities.friends);
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendRequestAccepted(7)),
        wait: const Duration(milliseconds: 150),
        expect: () => [
          // First emit marks 7 as processing (button should disable).
          isA<FriendState>()
              .having((s) => s.processingRequestIds, 'processing', contains(7)),
          // Final emit clears the processing flag.
          isA<FriendState>()
              .having((s) => s.processingRequestIds, 'processing', isEmpty)
              .having((s) => s.status, 'status', FriendStatus.success),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'ignores a duplicate reject for the same requestId while in flight',
        build: () {
          when(() => mockFriendRepository.rejectFriendRequest(any()))
              .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
          });
          when(() => mockFriendRepository.getReceivedFriendRequests())
              .thenAnswer((_) async => FakeEntities.receivedFriendRequests);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) {
          bloc.add(const FriendRequestRejected(1));
          bloc.add(const FriendRequestRejected(1));
        },
        wait: const Duration(milliseconds: 150),
        verify: (bloc) {
          verify(() => mockFriendRepository.rejectFriendRequest(1)).called(1);
          expect(bloc.state.processingRequestIds, isEmpty);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'clears processing flag and reports error when accept fails',
        build: () {
          when(() => mockFriendRepository.acceptFriendRequest(any()))
              .thenThrow(Exception('boom'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendRequestAccepted(3)),
        verify: (bloc) {
          expect(bloc.state.processingRequestIds, isEmpty);
          expect(bloc.state.errorMessage, isNotNull);
        },
      );
    });

    group('FriendRemoved', () {
      blocTest<FriendBloc, FriendState>(
        'removes friend and updates list',
        build: () {
          when(() => mockFriendRepository.removeFriend(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
          return FriendBloc(mockFriendRepository, mockWebSocketService);
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
