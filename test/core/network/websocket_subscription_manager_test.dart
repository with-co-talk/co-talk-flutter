import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_subscription_manager.dart';

// ---------------------------------------------------------------------------
// Fakes / mocks
// ---------------------------------------------------------------------------

class MockStompClient extends Mock implements StompClient {}

void main() {
  late WebSocketSubscriptionManager manager;

  setUp(() {
    manager = WebSocketSubscriptionManager();
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('initial state', () {
    test('subscribedRoomIds is empty initially', () {
      expect(manager.subscribedRoomIds, isEmpty);
    });

    test('pendingRoomIds is empty initially', () {
      expect(manager.pendingRoomIds, isEmpty);
    });

    test('subscribedUserId is null initially', () {
      expect(manager.subscribedUserId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // subscribeToChatRoom – disconnected path
  // -------------------------------------------------------------------------
  group('subscribeToChatRoom – not connected', () {
    test('adds room to pending when stompClient is null', () {
      manager.subscribeToChatRoom(
        roomId: 1,
        stompClient: null,
        onMessage: (_) {},
      );

      expect(manager.pendingRoomIds, contains(1));
      expect(manager.subscribedRoomIds, isEmpty);
    });

    test('adds room to pending when stompClient is disconnected', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(false);

      manager.subscribeToChatRoom(
        roomId: 2,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      expect(manager.pendingRoomIds, contains(2));
      expect(manager.subscribedRoomIds, isEmpty);
    });

    test('does not duplicate pending room IDs', () {
      manager.subscribeToChatRoom(roomId: 3, stompClient: null, onMessage: (_) {});
      manager.subscribeToChatRoom(roomId: 3, stompClient: null, onMessage: (_) {});

      expect(manager.pendingRoomIds.where((id) => id == 3).length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // subscribeToChatRoom – already subscribed
  // -------------------------------------------------------------------------
  group('subscribeToChatRoom – already subscribed', () {
    test('does not re-subscribe if room already active', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      int subscribeCallCount = 0;
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((_) {
        subscribeCallCount++;
        return ({Map<String, String>? unsubscribeHeaders}) {};
      });

      manager.subscribeToChatRoom(
        roomId: 10,
        stompClient: mockClient,
        onMessage: (_) {},
      );
      manager.subscribeToChatRoom(
        roomId: 10,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      // subscribe should only be called once
      expect(subscribeCallCount, 1);
    });
  });

  // -------------------------------------------------------------------------
  // subscribeToChatRoom – connected path
  // -------------------------------------------------------------------------
  group('subscribeToChatRoom – connected', () {
    test('subscribes and adds to active subscriptions', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.subscribeToChatRoom(
        roomId: 5,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      expect(manager.subscribedRoomIds, contains(5));
      expect(manager.pendingRoomIds, isNot(contains(5)));
    });

    test('removes room from pending after successful subscription', () {
      // First add to pending
      manager.subscribeToChatRoom(roomId: 6, stompClient: null, onMessage: (_) {});
      expect(manager.pendingRoomIds, contains(6));

      // Now subscribe with connected client
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.subscribeToChatRoom(
        roomId: 6,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      expect(manager.subscribedRoomIds, contains(6));
      expect(manager.pendingRoomIds, isNot(contains(6)));
    });

    test('adds back to pending when subscription throws', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenThrow(Exception('subscribe failed'));

      manager.subscribeToChatRoom(
        roomId: 7,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      // Should be back in pending after failure
      expect(manager.pendingRoomIds, contains(7));
      expect(manager.subscribedRoomIds, isNot(contains(7)));
    });
  });

  // -------------------------------------------------------------------------
  // unsubscribeFromChatRoom
  // -------------------------------------------------------------------------
  group('unsubscribeFromChatRoom', () {
    test('removes active subscription and calls unsubscribe', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      bool unsubscribeCalled = false;
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({
            Map<String, String>? unsubscribeHeaders,
          }) {
            unsubscribeCalled = true;
          });

      manager.subscribeToChatRoom(
        roomId: 20,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      manager.unsubscribeFromChatRoom(20);

      expect(manager.subscribedRoomIds, isNot(contains(20)));
      expect(unsubscribeCalled, isTrue);
    });

    test('removes pending subscription', () {
      manager.subscribeToChatRoom(roomId: 21, stompClient: null, onMessage: (_) {});
      expect(manager.pendingRoomIds, contains(21));

      manager.unsubscribeFromChatRoom(21);

      expect(manager.pendingRoomIds, isNot(contains(21)));
    });

    test('does not throw when room not subscribed', () {
      expect(() => manager.unsubscribeFromChatRoom(999), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // subscribeToUserChannel
  // -------------------------------------------------------------------------
  group('subscribeToUserChannel', () {
    test('stores userId when not connected', () {
      manager.subscribeToUserChannel(
        userId: 42,
        stompClient: null,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(manager.subscribedUserId, 42);
    });

    test('stores userId when stompClient disconnected', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(false);

      manager.subscribeToUserChannel(
        userId: 43,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(manager.subscribedUserId, 43);
    });

    test('does not re-subscribe same user when already subscribed', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      int subscribeCallCount = 0;
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((_) {
        subscribeCallCount++;
        return ({Map<String, String>? unsubscribeHeaders}) {};
      });

      // First subscription
      manager.subscribeToUserChannel(
        userId: 44,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      final firstCount = subscribeCallCount;

      // Second subscription with same userId — should be a no-op
      manager.subscribeToUserChannel(
        userId: 44,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(subscribeCallCount, firstCount);
    });

    test('subscribes with connected client and sets userId', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.subscribeToUserChannel(
        userId: 50,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(manager.subscribedUserId, 50);
    });

    test('subscribes to error queue when onErrorMessage is provided', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      final subscribedDestinations = <String>[];
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((invocation) {
        subscribedDestinations.add(
          invocation.namedArguments[const Symbol('destination')] as String,
        );
        return ({Map<String, String>? unsubscribeHeaders}) {};
      });

      manager.subscribeToUserChannel(
        userId: 51,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
        onErrorMessage: (_) {},
      );

      expect(subscribedDestinations.any((d) => d.contains('errors')), isTrue);
    });

    test('does not subscribe to error queue when onErrorMessage is null', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      final subscribedDestinations = <String>[];
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((invocation) {
        subscribedDestinations.add(
          invocation.namedArguments[const Symbol('destination')] as String,
        );
        return ({Map<String, String>? unsubscribeHeaders}) {};
      });

      manager.subscribeToUserChannel(
        userId: 52,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      // 4 subscriptions (chatList, readReceipt, onlineStatus, profileUpdate)
      expect(subscribedDestinations.length, 4);
      expect(subscribedDestinations.any((d) => d.contains('errors')), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // unsubscribeFromUserChannel
  // -------------------------------------------------------------------------
  group('unsubscribeFromUserChannel', () {
    test('clears subscribedUserId', () {
      manager.subscribeToUserChannel(
        userId: 60,
        stompClient: null,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      manager.unsubscribeFromUserChannel();

      expect(manager.subscribedUserId, isNull);
    });

    test('does not throw when not subscribed', () {
      expect(() => manager.unsubscribeFromUserChannel(), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // onDisconnected
  // -------------------------------------------------------------------------
  group('onDisconnected', () {
    test('moves active room subscriptions to pending', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.subscribeToChatRoom(
        roomId: 70,
        stompClient: mockClient,
        onMessage: (_) {},
      );
      manager.subscribeToChatRoom(
        roomId: 71,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      expect(manager.subscribedRoomIds, containsAll([70, 71]));

      manager.onDisconnected();

      expect(manager.subscribedRoomIds, isEmpty);
      expect(manager.pendingRoomIds, containsAll([70, 71]));
    });

    test('clears user channel subscription references', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.subscribeToUserChannel(
        userId: 80,
        stompClient: mockClient,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      // subscribedUserId should still be set after disconnect (for reconnect)
      manager.onDisconnected();
      expect(manager.subscribedUserId, 80);
    });
  });

  // -------------------------------------------------------------------------
  // restoreSubscriptions
  // -------------------------------------------------------------------------
  group('restoreSubscriptions', () {
    test('restores pending room subscriptions', () {
      // Set up pending rooms
      manager.subscribeToChatRoom(roomId: 90, stompClient: null, onMessage: (_) {});
      manager.subscribeToChatRoom(roomId: 91, stompClient: null, onMessage: (_) {});

      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.restoreSubscriptions(
        stompClient: mockClient,
        onRoomMessage: (roomId) => (_) {},
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(manager.subscribedRoomIds, containsAll([90, 91]));
    });

    test('restores user channel when subscribedUserId is set', () {
      manager.subscribeToUserChannel(
        userId: 100,
        stompClient: null,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});

      manager.restoreSubscriptions(
        stompClient: mockClient,
        onRoomMessage: (_) => (_) {},
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      expect(manager.subscribedUserId, 100);
    });

    test('skips pending room if already in active subscriptions', () {
      // Simulate: room 95 was added to pending AND active (edge case prevention)
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      int subscribeCount = 0;
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((_) {
        subscribeCount++;
        return ({Map<String, String>? unsubscribeHeaders}) {};
      });

      // First subscribe → active
      manager.subscribeToChatRoom(
        roomId: 95,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      // Manually add to pending as well (simulating race condition)
      manager.subscribeToChatRoom(roomId: 95, stompClient: null, onMessage: (_) {});

      final countBefore = subscribeCount;

      manager.restoreSubscriptions(
        stompClient: mockClient,
        onRoomMessage: (_) => (_) {},
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      // Should not have subscribed again
      expect(subscribeCount, countBefore);
    });
  });

  // -------------------------------------------------------------------------
  // clearAll
  // -------------------------------------------------------------------------
  group('clearAll', () {
    test('clears all state without calling unsubscribe', () {
      manager.subscribeToChatRoom(roomId: 200, stompClient: null, onMessage: (_) {});
      manager.subscribeToUserChannel(
        userId: 201,
        stompClient: null,
        onChatListMessage: (_) {},
        onReadReceiptMessage: (_) {},
        onOnlineStatusMessage: (_) {},
        onProfileUpdateMessage: (_) {},
      );

      manager.clearAll();

      expect(manager.subscribedRoomIds, isEmpty);
      expect(manager.pendingRoomIds, isEmpty);
      expect(manager.subscribedUserId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------
  group('dispose', () {
    test('calls unsubscribe for all active room subscriptions', () {
      final mockClient = MockStompClient();
      when(() => mockClient.connected).thenReturn(true);

      int unsubscribeCount = 0;
      when(() => mockClient.subscribe(
            destination: any(named: 'destination'),
            callback: any(named: 'callback'),
          )).thenAnswer((_) => ({
            Map<String, String>? unsubscribeHeaders,
          }) {
            unsubscribeCount++;
          });

      manager.subscribeToChatRoom(
        roomId: 300,
        stompClient: mockClient,
        onMessage: (_) {},
      );
      manager.subscribeToChatRoom(
        roomId: 301,
        stompClient: mockClient,
        onMessage: (_) {},
      );

      manager.dispose();

      expect(unsubscribeCount, 2);
    });

    test('clears all state after dispose', () {
      final testManager = WebSocketSubscriptionManager();
      testManager.subscribeToChatRoom(roomId: 400, stompClient: null, onMessage: (_) {});

      testManager.dispose();

      expect(testManager.subscribedRoomIds, isEmpty);
      expect(testManager.pendingRoomIds, isEmpty);
      expect(testManager.subscribedUserId, isNull);
    });

    test('dispose does not throw when no subscriptions', () {
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}
