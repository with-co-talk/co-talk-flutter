import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';

void main() {
  group('ProfileHistory', () {
    test('should create ProfileHistory with required fields', () {
      final createdAt = DateTime(2024, 1, 1);

      final history = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        createdAt: createdAt,
      );

      expect(history.id, 1);
      expect(history.userId, 100);
      expect(history.type, ProfileHistoryType.avatar);
      expect(history.url, isNull);
      expect(history.content, isNull);
      expect(history.isPrivate, false);
      expect(history.isCurrent, false);
      expect(history.createdAt, createdAt);
    });

    test('should create ProfileHistory with all fields', () {
      final createdAt = DateTime(2024, 1, 1);

      final history = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/avatar.jpg',
        content: 'Status message',
        isPrivate: true,
        isCurrent: true,
        createdAt: createdAt,
      );

      expect(history.url, 'https://example.com/avatar.jpg');
      expect(history.content, 'Status message');
      expect(history.isPrivate, true);
      expect(history.isCurrent, true);
    });

    test('should have correct equality based on all fields', () {
      final createdAt = DateTime(2024, 1, 1);

      final history1 = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        createdAt: createdAt,
      );

      final history2 = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        createdAt: createdAt,
      );

      final history3 = ProfileHistory(
        id: 2,
        userId: 100,
        type: ProfileHistoryType.avatar,
        createdAt: createdAt,
      );

      expect(history1, equals(history2));
      expect(history1, isNot(equals(history3)));
    });

    test('copyWith should create new instance with updated fields', () {
      final createdAt = DateTime(2024, 1, 1);

      final history = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        createdAt: createdAt,
      );

      final updated = history.copyWith(
        isPrivate: true,
        isCurrent: true,
        url: 'https://example.com/new-avatar.jpg',
      );

      expect(updated.id, 1);
      expect(updated.userId, 100);
      expect(updated.type, ProfileHistoryType.avatar);
      expect(updated.url, 'https://example.com/new-avatar.jpg');
      expect(updated.isPrivate, true);
      expect(updated.isCurrent, true);
      expect(updated.createdAt, createdAt);
    });

    test('copyWith should preserve unchanged fields', () {
      final createdAt = DateTime(2024, 1, 1);

      final history = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/avatar.jpg',
        content: 'Status',
        isPrivate: true,
        isCurrent: true,
        createdAt: createdAt,
      );

      final updated = history.copyWith(isPrivate: false);

      expect(updated.id, history.id);
      expect(updated.userId, history.userId);
      expect(updated.type, history.type);
      expect(updated.url, history.url);
      expect(updated.content, history.content);
      expect(updated.isCurrent, history.isCurrent);
      expect(updated.createdAt, history.createdAt);
      expect(updated.isPrivate, false);
    });

    test('props should include all fields for equality', () {
      final createdAt = DateTime(2024, 1, 1);

      final history = ProfileHistory(
        id: 1,
        userId: 100,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/avatar.jpg',
        content: 'Status',
        isPrivate: true,
        isCurrent: true,
        createdAt: createdAt,
      );

      expect(history.props.length, 8);
      expect(history.props.contains(1), isTrue);
      expect(history.props.contains(100), isTrue);
      expect(history.props.contains(ProfileHistoryType.avatar), isTrue);
      expect(history.props.contains('https://example.com/avatar.jpg'), isTrue);
      expect(history.props.contains('Status'), isTrue);
      expect(history.props.contains(true), isTrue);
      expect(history.props.contains(createdAt), isTrue);
    });
  });

  group('ProfileHistoryType', () {
    test('has all expected values', () {
      expect(ProfileHistoryType.values.length, 3);
      expect(ProfileHistoryType.values, contains(ProfileHistoryType.avatar));
      expect(ProfileHistoryType.values, contains(ProfileHistoryType.background));
      expect(ProfileHistoryType.values, contains(ProfileHistoryType.statusMessage));
    });
  });
}
