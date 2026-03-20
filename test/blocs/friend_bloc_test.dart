import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
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

    group('FriendListLoadRequested - hidden friends filtering', () {
      blocTest<FriendBloc, FriendState>(
        'filters out hidden friends from the list',
        build: () {
          final hiddenFriend = Friend(
            id: 99,
            user: User(
              id: 99,
              email: 'hidden@example.com',
              nickname: 'HiddenUser',
              status: UserStatus.active,
              role: UserRole.user,
              onlineStatus: OnlineStatus.offline,
              createdAt: DateTime(2024, 1, 1),
            ),
            createdAt: DateTime(2024, 1, 1),
            isHidden: true,
          );
          final allFriends = [...FakeEntities.friends, hiddenFriend];
          when(() => mockFriendRepository.getFriends())
              .thenAnswer((_) async => allFriends);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendListLoadRequested()),
        expect: () => [
          const FriendState(status: FriendStatus.loading),
          isA<FriendState>()
              .having((s) => s.status, 'status', FriendStatus.success)
              .having(
                (s) => s.friends.any((f) => f.isHidden),
                'no hidden friends',
                false,
              )
              .having(
                (s) => s.friends.length,
                'visible friends count',
                FakeEntities.friends.length,
              ),
        ],
      );
    });

    group('FriendRequestAccepted - error path', () {
      blocTest<FriendBloc, FriendState>(
        'emits error message when acceptFriendRequest fails',
        build: () {
          when(() => mockFriendRepository.acceptFriendRequest(any()))
              .thenThrow(Exception('Accept failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendRequestAccepted(1)),
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
        verify: (_) {
          verify(() => mockFriendRepository.acceptFriendRequest(1)).called(1);
          verifyNever(() => mockFriendRepository.getFriends());
        },
      );
    });

    group('FriendRequestRejected - error path', () {
      blocTest<FriendBloc, FriendState>(
        'emits error message when rejectFriendRequest fails',
        build: () {
          when(() => mockFriendRepository.rejectFriendRequest(any()))
              .thenThrow(Exception('Reject failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendRequestRejected(1)),
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
        verify: (_) {
          verify(() => mockFriendRepository.rejectFriendRequest(1)).called(1);
          verifyNever(() => mockFriendRepository.getReceivedFriendRequests());
        },
      );
    });

    group('FriendRemoved - error path', () {
      blocTest<FriendBloc, FriendState>(
        'emits error message when removeFriend fails',
        build: () {
          when(() => mockFriendRepository.removeFriend(any()))
              .thenThrow(Exception('Remove failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(const FriendRemoved(2)),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.removeFriend(2)).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits successMessage when removeFriend succeeds',
        build: () {
          when(() => mockFriendRepository.removeFriend(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(const FriendRemoved(2)),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.successMessage,
            'successMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('FriendOnlineStatusChanged', () {
      blocTest<FriendBloc, FriendState>(
        'updates online status for matching friend (offline -> online)',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends, // otherUser is offline
        ),
        act: (bloc) => bloc.add(FriendOnlineStatusChanged(
          userId: FakeEntities.otherUser.id, // id=2
          isOnline: true, // change from offline to online
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends
                .firstWhere((f) => f.user.id == FakeEntities.otherUser.id)
                .user
                .onlineStatus,
            'onlineStatus',
            OnlineStatus.online,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'updates online status for matching friend (online -> offline)',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: [
            Friend(
              id: 1,
              user: FakeEntities.otherUser.copyWith(
                onlineStatus: OnlineStatus.online,
              ),
              createdAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
        act: (bloc) => bloc.add(FriendOnlineStatusChanged(
          userId: FakeEntities.otherUser.id,
          isOnline: false,
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends
                .firstWhere((f) => f.user.id == FakeEntities.otherUser.id)
                .user
                .onlineStatus,
            'onlineStatus',
            OnlineStatus.offline,
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'does not emit new state when userId does not match any friend',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(const FriendOnlineStatusChanged(
          userId: 9999,
          isOnline: true,
        )),
        // State is equal to seeded state (Equatable deduplication) -> no emission
        expect: () => [],
      );

      blocTest<FriendBloc, FriendState>(
        'updates lastActiveAt when provided',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(FriendOnlineStatusChanged(
          userId: FakeEntities.otherUser.id,
          isOnline: false,
          lastActiveAt: DateTime(2024, 6, 1),
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends
                .firstWhere((f) => f.user.id == FakeEntities.otherUser.id)
                .user
                .lastActiveAt,
            'lastActiveAt',
            DateTime(2024, 6, 1),
          ),
        ],
      );
    });

    group('FriendProfileUpdated', () {
      blocTest<FriendBloc, FriendState>(
        'updates avatarUrl for matching friend',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(FriendProfileUpdated(
          userId: FakeEntities.otherUser.id,
          avatarUrl: 'https://example.com/new-avatar.jpg',
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends
                .firstWhere((f) => f.user.id == FakeEntities.otherUser.id)
                .user
                .avatarUrl,
            'avatarUrl',
            'https://example.com/new-avatar.jpg',
          ),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'does not emit new state when userId does not match any friend',
        build: () => FriendBloc(mockFriendRepository, mockWebSocketService),
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(const FriendProfileUpdated(
          userId: 9999,
          avatarUrl: 'https://example.com/avatar.jpg',
        )),
        // State is equal to seeded state (Equatable deduplication) -> no emission
        expect: () => [],
      );
    });

    group('FriendListSubscriptionStarted and Stopped', () {
      blocTest<FriendBloc, FriendState>(
        'starts subscription without emitting new states',
        build: () {
          when(() => mockWebSocketService.onlineStatusEvents)
              .thenAnswer((_) => const Stream.empty());
          when(() => mockWebSocketService.profileUpdateEvents)
              .thenAnswer((_) => const Stream.empty());
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const FriendListSubscriptionStarted()),
        expect: () => [],
      );

      blocTest<FriendBloc, FriendState>(
        'stops subscription without emitting new states',
        build: () {
          when(() => mockWebSocketService.onlineStatusEvents)
              .thenAnswer((_) => const Stream.empty());
          when(() => mockWebSocketService.profileUpdateEvents)
              .thenAnswer((_) => const Stream.empty());
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) async {
          bloc.add(const FriendListSubscriptionStarted());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const FriendListSubscriptionStopped());
        },
        expect: () => [],
      );
    });

    group('HideFriendRequested', () {
      blocTest<FriendBloc, FriendState>(
        'optimistically removes friend from list on success',
        build: () {
          when(() => mockFriendRepository.hideFriend(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(HideFriendRequested(
          FakeEntities.otherUser.id,
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends.any((f) => f.user.id == FakeEntities.otherUser.id),
            'friend removed optimistically',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.hideFriend(
                FakeEntities.otherUser.id,
              )).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'restores previous friends list when hideFriend fails',
        build: () {
          when(() => mockFriendRepository.hideFriend(any()))
              .thenThrow(Exception('Hide failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(HideFriendRequested(
          FakeEntities.otherUser.id,
        )),
        expect: () => [
          // optimistic removal
          isA<FriendState>().having(
            (s) => s.friends.any((f) => f.user.id == FakeEntities.otherUser.id),
            'friend removed optimistically',
            false,
          ),
          // restored on failure
          isA<FriendState>()
              .having(
                (s) => s.friends,
                'friends restored',
                FakeEntities.friends,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                isNotNull,
              ),
        ],
      );
    });

    group('UnhideFriendRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits updated hiddenFriends on success',
        build: () {
          when(() => mockFriendRepository.unhideFriend(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnhideFriendRequested(2)),
        // The first emit (clearErrorMessage) is deduplicated because initial state
        // already has errorMessage=null, so only the second emit is observable.
        expect: () => [
          isA<FriendState>().having(
            (s) => s.hiddenFriends,
            'hiddenFriends',
            isEmpty,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unhideFriend(2)).called(1);
          verify(() => mockFriendRepository.getHiddenFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when unhideFriend fails',
        build: () {
          when(() => mockFriendRepository.unhideFriend(any()))
              .thenThrow(Exception('Unhide failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnhideFriendRequested(2)),
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

    group('HiddenFriendsLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, hiddenFriends, loading=false] on success',
        build: () {
          final hiddenFriend = Friend(
            id: 5,
            user: User(
              id: 5,
              email: 'hidden@example.com',
              nickname: 'HiddenUser',
              status: UserStatus.active,
              role: UserRole.user,
              onlineStatus: OnlineStatus.offline,
              createdAt: DateTime(2024, 1, 1),
            ),
            createdAt: DateTime(2024, 1, 1),
            isHidden: true,
          );
          when(() => mockFriendRepository.getHiddenFriends())
              .thenAnswer((_) async => [hiddenFriend]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HiddenFriendsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.isHiddenFriendsLoading,
            'isHiddenFriendsLoading',
            true,
          ),
          isA<FriendState>()
              .having(
                (s) => s.isHiddenFriendsLoading,
                'isHiddenFriendsLoading',
                false,
              )
              .having(
                (s) => s.hiddenFriends.length,
                'hiddenFriends count',
                1,
              ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getHiddenFriends()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when getHiddenFriends fails',
        build: () {
          when(() => mockFriendRepository.getHiddenFriends())
              .thenThrow(Exception('Load failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const HiddenFriendsLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.isHiddenFriendsLoading,
            'isHiddenFriendsLoading',
            true,
          ),
          isA<FriendState>()
              .having(
                (s) => s.isHiddenFriendsLoading,
                'isHiddenFriendsLoading',
                false,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                isNotNull,
              ),
        ],
      );
    });

    group('BlockUserRequested', () {
      blocTest<FriendBloc, FriendState>(
        'optimistically removes user from friends list on success',
        build: () {
          when(() => mockFriendRepository.blockUser(any()))
              .thenAnswer((_) async {});
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(BlockUserRequested(
          FakeEntities.otherUser.id,
        )),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.friends.any((f) => f.user.id == FakeEntities.otherUser.id),
            'user removed from friends',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.blockUser(
                FakeEntities.otherUser.id,
              )).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'restores previous friends list when blockUser fails',
        build: () {
          when(() => mockFriendRepository.blockUser(any()))
              .thenThrow(Exception('Block failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        seed: () => FriendState(
          status: FriendStatus.success,
          friends: FakeEntities.friends,
        ),
        act: (bloc) => bloc.add(BlockUserRequested(
          FakeEntities.otherUser.id,
        )),
        expect: () => [
          // optimistic removal
          isA<FriendState>().having(
            (s) => s.friends.any((f) => f.user.id == FakeEntities.otherUser.id),
            'user removed optimistically',
            false,
          ),
          // restored on failure
          isA<FriendState>()
              .having(
                (s) => s.friends,
                'friends restored',
                FakeEntities.friends,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                isNotNull,
              ),
        ],
      );
    });

    group('UnblockUserRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits updated blockedUsers on success',
        build: () {
          when(() => mockFriendRepository.unblockUser(any()))
              .thenAnswer((_) async {});
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => []);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnblockUserRequested(2)),
        // The first emit (clearErrorMessage) is deduplicated because initial state
        // already has errorMessage=null, so only the second emit is observable.
        expect: () => [
          isA<FriendState>().having(
            (s) => s.blockedUsers,
            'blockedUsers',
            isEmpty,
          ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.unblockUser(2)).called(1);
          verify(() => mockFriendRepository.getBlockedUsers()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when unblockUser fails',
        build: () {
          when(() => mockFriendRepository.unblockUser(any()))
              .thenThrow(Exception('Unblock failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const UnblockUserRequested(2)),
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

    group('BlockedUsersLoadRequested', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading=true, blockedUsers, loading=false] on success',
        build: () {
          when(() => mockFriendRepository.getBlockedUsers())
              .thenAnswer((_) async => [FakeEntities.otherUser]);
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockedUsersLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.isBlockedUsersLoading,
            'isBlockedUsersLoading',
            true,
          ),
          isA<FriendState>()
              .having(
                (s) => s.isBlockedUsersLoading,
                'isBlockedUsersLoading',
                false,
              )
              .having(
                (s) => s.blockedUsers.length,
                'blockedUsers count',
                1,
              ),
        ],
        verify: (_) {
          verify(() => mockFriendRepository.getBlockedUsers()).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits error message when getBlockedUsers fails',
        build: () {
          when(() => mockFriendRepository.getBlockedUsers())
              .thenThrow(Exception('Load failed'));
          return FriendBloc(mockFriendRepository, mockWebSocketService);
        },
        act: (bloc) => bloc.add(const BlockedUsersLoadRequested()),
        expect: () => [
          isA<FriendState>().having(
            (s) => s.isBlockedUsersLoading,
            'isBlockedUsersLoading',
            true,
          ),
          isA<FriendState>()
              .having(
                (s) => s.isBlockedUsersLoading,
                'isBlockedUsersLoading',
                false,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                isNotNull,
              ),
        ],
      );
    });
  });
}
