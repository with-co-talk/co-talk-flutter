import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

void main() {
  final testUser = User(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testFriend = Friend(
    id: 1,
    user: testUser,
    createdAt: DateTime(2024, 1, 1),
  );

  group('FriendEvent', () {
    group('FriendListLoadRequested', () {
      test('creates event', () {
        const event = FriendListLoadRequested();
        expect(event, isA<FriendEvent>());
      });

      test('equality works', () {
        const event1 = FriendListLoadRequested();
        const event2 = FriendListLoadRequested();
        expect(event1, equals(event2));
      });
    });

    group('FriendRequestSent', () {
      test('creates event with receiverId', () {
        const event = FriendRequestSent(2);
        expect(event.receiverId, 2);
      });

      test('equality works', () {
        const event1 = FriendRequestSent(2);
        const event2 = FriendRequestSent(2);
        const event3 = FriendRequestSent(3);

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('props contains receiverId', () {
        const event = FriendRequestSent(2);
        expect(event.props, contains(2));
      });
    });

    group('FriendRequestAccepted', () {
      test('creates event with requestId', () {
        const event = FriendRequestAccepted(1);
        expect(event.requestId, 1);
      });

      test('equality works', () {
        const event1 = FriendRequestAccepted(1);
        const event2 = FriendRequestAccepted(1);
        expect(event1, equals(event2));
      });
    });

    group('FriendRequestRejected', () {
      test('creates event with requestId', () {
        const event = FriendRequestRejected(1);
        expect(event.requestId, 1);
      });

      test('equality works', () {
        const event1 = FriendRequestRejected(1);
        const event2 = FriendRequestRejected(1);
        expect(event1, equals(event2));
      });
    });

    group('FriendRemoved', () {
      test('creates event with friendId', () {
        const event = FriendRemoved(1);
        expect(event.friendId, 1);
      });

      test('equality works', () {
        const event1 = FriendRemoved(1);
        const event2 = FriendRemoved(1);
        expect(event1, equals(event2));
      });
    });

    group('UserSearchRequested', () {
      test('creates event with query', () {
        const event = UserSearchRequested('test');
        expect(event.query, 'test');
      });

      test('equality works', () {
        const event1 = UserSearchRequested('test');
        const event2 = UserSearchRequested('test');
        const event3 = UserSearchRequested('other');

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('props contains query', () {
        const event = UserSearchRequested('test');
        expect(event.props, contains('test'));
      });
    });
  });

  group('FriendState', () {
    test('initial state', () {
      const state = FriendState();

      expect(state.status, FriendStatus.initial);
      expect(state.friends, isEmpty);
      expect(state.searchResults, isEmpty);
      expect(state.isSearching, false);
      expect(state.errorMessage, isNull);
    });

    test('creates state with all fields', () {
      final state = FriendState(
        status: FriendStatus.success,
        friends: [testFriend],
        searchResults: [testUser],
        isSearching: false,
        errorMessage: null,
      );

      expect(state.status, FriendStatus.success);
      expect(state.friends.length, 1);
      expect(state.searchResults.length, 1);
    });

    test('copyWith creates new state', () {
      const state = FriendState();

      final newState = state.copyWith(
        status: FriendStatus.loading,
      );

      expect(newState.status, FriendStatus.loading);
      expect(newState.friends, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      final state = FriendState(
        status: FriendStatus.success,
        friends: [testFriend],
        searchResults: [testUser],
      );

      final newState = state.copyWith(status: FriendStatus.loading);

      expect(newState.friends.length, 1);
      expect(newState.searchResults.length, 1);
    });

    test('equality works', () {
      const state1 = FriendState();
      const state2 = FriendState();
      const state3 = FriendState(status: FriendStatus.loading);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props contains all fields', () {
      final state = FriendState(
        status: FriendStatus.success,
        friends: [testFriend],
        searchResults: [testUser],
        isSearching: true,
        errorMessage: 'Error',
      );

      expect(state.props.length, 5);
    });
  });

  group('FriendStatus', () {
    test('has all expected values', () {
      expect(FriendStatus.values.length, 4);
      expect(FriendStatus.values, contains(FriendStatus.initial));
      expect(FriendStatus.values, contains(FriendStatus.loading));
      expect(FriendStatus.values, contains(FriendStatus.success));
      expect(FriendStatus.values, contains(FriendStatus.failure));
    });
  });
}
