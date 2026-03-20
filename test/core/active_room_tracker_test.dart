import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/services/active_room_tracker.dart';

void main() {
  late ActiveRoomTracker tracker;

  setUp(() {
    tracker = ActiveRoomTracker();
  });

  group('ActiveRoomTracker', () {
    test('starts with null activeRoomId', () {
      expect(tracker.activeRoomId, isNull);
    });

    test('can set activeRoomId to a positive integer', () {
      tracker.activeRoomId = 123;
      expect(tracker.activeRoomId, 123);
    });

    test('can change activeRoomId from one room to another', () {
      tracker.activeRoomId = 1;
      expect(tracker.activeRoomId, 1);

      tracker.activeRoomId = 2;
      expect(tracker.activeRoomId, 2);
    });

    test('can set activeRoomId back to null when leaving room', () {
      tracker.activeRoomId = 456;
      expect(tracker.activeRoomId, 456);

      tracker.activeRoomId = null;
      expect(tracker.activeRoomId, isNull);
    });

    test('can set activeRoomId multiple times between rooms', () {
      // Simulating navigation: null -> room1 -> null -> room2 -> null
      expect(tracker.activeRoomId, isNull);

      tracker.activeRoomId = 100;
      expect(tracker.activeRoomId, 100);

      tracker.activeRoomId = null;
      expect(tracker.activeRoomId, isNull);

      tracker.activeRoomId = 200;
      expect(tracker.activeRoomId, 200);

      tracker.activeRoomId = null;
      expect(tracker.activeRoomId, isNull);
    });

    test('can handle zero as a room ID', () {
      tracker.activeRoomId = 0;
      expect(tracker.activeRoomId, 0);
    });

    test('can handle negative room ID (edge case)', () {
      tracker.activeRoomId = -1;
      expect(tracker.activeRoomId, -1);
    });

    test('maintains state across multiple reads', () {
      tracker.activeRoomId = 789;

      // Multiple reads should return the same value
      expect(tracker.activeRoomId, 789);
      expect(tracker.activeRoomId, 789);
      expect(tracker.activeRoomId, 789);
    });

    test('different instances have independent state', () {
      final tracker1 = ActiveRoomTracker();
      final tracker2 = ActiveRoomTracker();

      tracker1.activeRoomId = 111;
      tracker2.activeRoomId = 222;

      expect(tracker1.activeRoomId, 111);
      expect(tracker2.activeRoomId, 222);
    });

    test('supports use case: suppress notifications for active room', () {
      // Simulate entering a chat room
      const roomId = 42;
      tracker.activeRoomId = roomId;

      // Check if notification should be suppressed
      const incomingMessageRoomId = 42;
      final shouldSuppressNotification = tracker.activeRoomId == incomingMessageRoomId;
      expect(shouldSuppressNotification, isTrue);

      // Different room should not suppress
      const otherRoomId = 99;
      final shouldSuppressOther = tracker.activeRoomId == otherRoomId;
      expect(shouldSuppressOther, isFalse);
    });

    test('supports use case: handle same-room push notification tap', () {
      // User is in room 10
      const currentRoomId = 10;
      tracker.activeRoomId = currentRoomId;

      // Push notification for the same room
      const notificationRoomId = 10;
      final isSameRoom = tracker.activeRoomId == notificationRoomId;
      expect(isSameRoom, isTrue);

      // Should refresh instead of navigate
      // (actual refresh logic would be in the handler)
    });

    test('supports use case: check if any room is active', () {
      // No room active
      expect(tracker.activeRoomId != null, isFalse);

      // Room is active
      tracker.activeRoomId = 555;
      expect(tracker.activeRoomId != null, isTrue);

      // Back to no active room
      tracker.activeRoomId = null;
      expect(tracker.activeRoomId != null, isFalse);
    });
  });
}
