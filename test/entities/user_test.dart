import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

void main() {
  group('User', () {
    test('creates user with required fields', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.nickname, 'TestUser');
      expect(user.status, UserStatus.active);
      expect(user.role, UserRole.user);
      expect(user.onlineStatus, OnlineStatus.offline);
      expect(user.avatarUrl, isNull);
      expect(user.lastActiveAt, isNull);
    });

    test('creates user with all fields', () {
      final lastActive = DateTime(2024, 1, 1, 10, 0);
      final createdAt = DateTime(2024, 1, 1);

      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        avatarUrl: 'https://example.com/avatar.jpg',
        status: UserStatus.active,
        role: UserRole.admin,
        onlineStatus: OnlineStatus.online,
        lastActiveAt: lastActive,
        createdAt: createdAt,
      );

      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.role, UserRole.admin);
      expect(user.onlineStatus, OnlineStatus.online);
      expect(user.lastActiveAt, lastActive);
    });

    test('copyWith creates new user with updated fields', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedUser = user.copyWith(
        nickname: 'UpdatedUser',
        onlineStatus: OnlineStatus.online,
      );

      expect(updatedUser.id, 1);
      expect(updatedUser.email, 'test@example.com');
      expect(updatedUser.nickname, 'UpdatedUser');
      expect(updatedUser.onlineStatus, OnlineStatus.online);
    });

    test('copyWith preserves unchanged fields', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        avatarUrl: 'https://example.com/avatar.jpg',
        status: UserStatus.active,
        role: UserRole.admin,
        onlineStatus: OnlineStatus.online,
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedUser = user.copyWith(nickname: 'NewName');

      expect(updatedUser.id, user.id);
      expect(updatedUser.email, user.email);
      expect(updatedUser.avatarUrl, user.avatarUrl);
      expect(updatedUser.status, user.status);
      expect(updatedUser.role, user.role);
      expect(updatedUser.onlineStatus, user.onlineStatus);
    });

    test('equality works correctly', () {
      final user1 = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      final user3 = User(
        id: 2,
        email: 'other@example.com',
        nickname: 'OtherUser',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('props returns correct list', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.props.length, 9);
      expect(user.props.contains(1), isTrue);
      expect(user.props.contains('test@example.com'), isTrue);
      expect(user.props.contains('TestUser'), isTrue);
    });
  });

  group('UserStatus', () {
    test('has all expected values', () {
      expect(UserStatus.values.length, 3);
      expect(UserStatus.values, contains(UserStatus.active));
      expect(UserStatus.values, contains(UserStatus.inactive));
      expect(UserStatus.values, contains(UserStatus.suspended));
    });
  });

  group('OnlineStatus', () {
    test('has all expected values', () {
      expect(OnlineStatus.values.length, 3);
      expect(OnlineStatus.values, contains(OnlineStatus.online));
      expect(OnlineStatus.values, contains(OnlineStatus.offline));
      expect(OnlineStatus.values, contains(OnlineStatus.away));
    });
  });

  group('UserRole', () {
    test('has all expected values', () {
      expect(UserRole.values.length, 2);
      expect(UserRole.values, contains(UserRole.user));
      expect(UserRole.values, contains(UserRole.admin));
    });
  });
}
