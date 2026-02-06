import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

void main() {
  final testUser = User(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testUser2 = User(
    id: 2,
    email: 'user2@example.com',
    nickname: 'User2',
    createdAt: DateTime(2024, 1, 1),
  );

  group('Friend', () {
    test('creates friend with required fields', () {
      final friend = Friend(
        id: 1,
        user: testUser,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(friend.id, 1);
      expect(friend.user, testUser);
      expect(friend.createdAt, DateTime(2024, 1, 1));
    });

    test('equality works correctly', () {
      final friend1 = Friend(
        id: 1,
        user: testUser,
        createdAt: DateTime(2024, 1, 1),
      );

      final friend2 = Friend(
        id: 1,
        user: testUser,
        createdAt: DateTime(2024, 1, 1),
      );

      final friend3 = Friend(
        id: 2,
        user: testUser2,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(friend1, equals(friend2));
      expect(friend1, isNot(equals(friend3)));
    });

    test('props returns correct list', () {
      final friend = Friend(
        id: 1,
        user: testUser,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(friend.props.length, 4);
      expect(friend.props, contains(1));
      expect(friend.props, contains(testUser));
    });
  });

  group('FriendRequest', () {
    test('creates friend request with required fields', () {
      final request = FriendRequest(
        id: 1,
        requester: testUser,
        receiver: testUser2,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(request.id, 1);
      expect(request.requester, testUser);
      expect(request.receiver, testUser2);
      expect(request.status, FriendRequestStatus.pending);
    });

    test('creates friend request with custom status', () {
      final request = FriendRequest(
        id: 1,
        requester: testUser,
        receiver: testUser2,
        status: FriendRequestStatus.accepted,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(request.status, FriendRequestStatus.accepted);
    });

    test('equality works correctly', () {
      final request1 = FriendRequest(
        id: 1,
        requester: testUser,
        receiver: testUser2,
        createdAt: DateTime(2024, 1, 1),
      );

      final request2 = FriendRequest(
        id: 1,
        requester: testUser,
        receiver: testUser2,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(request1, equals(request2));
    });

    test('props returns correct list', () {
      final request = FriendRequest(
        id: 1,
        requester: testUser,
        receiver: testUser2,
        status: FriendRequestStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(request.props.length, 5);
    });
  });

  group('FriendRequestStatus', () {
    test('has all expected values', () {
      expect(FriendRequestStatus.values.length, 3);
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.pending));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.accepted));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.rejected));
    });
  });
}
