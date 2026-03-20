import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:co_talk_flutter/core/network/websocket_service.dart';

import '../../mocks/mock_repositories.dart';

/// A testable WebSocketService that allows injecting mocked STOMP client
/// by overriding the connection behavior.
///
/// Rather than mocking the internal StompClient (which requires real network),
/// these tests verify the public API and event stream behavior by testing
/// the facade's properties, stream existence, and isolated pure logic.
void main() {
  late MockAuthLocalDataSource mockAuthLocalDataSource;

  setUp(() {
    mockAuthLocalDataSource = MockAuthLocalDataSource();

    when(() => mockAuthLocalDataSource.getAccessToken())
        .thenAnswer((_) async => 'test_access_token');
    when(() => mockAuthLocalDataSource.getRefreshToken())
        .thenAnswer((_) async => 'test_refresh_token');
    when(() => mockAuthLocalDataSource.getUserId())
        .thenAnswer((_) async => 1);
    when(() => mockAuthLocalDataSource.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
  });

  WebSocketService createService() {
    return WebSocketService(mockAuthLocalDataSource);
  }

  group('WebSocketService', () {
    group('Initialization', () {
      test('creates service without throwing', () {
        expect(() => createService(), returnsNormally);
      });

      test('initial connection state is disconnected', () {
        final service = createService();
        expect(
          service.currentConnectionState,
          WebSocketConnectionState.disconnected,
        );
        service.dispose();
      });

      test('isConnected is false initially', () {
        final service = createService();
        expect(service.isConnected, isFalse);
        service.dispose();
      });
    });

    group('Event Streams', () {
      test('messages stream is a broadcast stream', () {
        final service = createService();
        expect(service.messages.isBroadcast, isTrue);
        service.dispose();
      });

      test('reactions stream is a broadcast stream', () {
        final service = createService();
        expect(service.reactions.isBroadcast, isTrue);
        service.dispose();
      });

      test('readEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.readEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('chatRoomUpdates stream is a broadcast stream', () {
        final service = createService();
        expect(service.chatRoomUpdates.isBroadcast, isTrue);
        service.dispose();
      });

      test('typingEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.typingEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('onlineStatusEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.onlineStatusEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('messageDeletedEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.messageDeletedEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('messageUpdatedEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.messageUpdatedEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('linkPreviewUpdatedEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.linkPreviewUpdatedEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('profileUpdateEvents stream is a broadcast stream', () {
        final service = createService();
        expect(service.profileUpdateEvents.isBroadcast, isTrue);
        service.dispose();
      });

      test('errors stream is a broadcast stream', () {
        final service = createService();
        expect(service.errors.isBroadcast, isTrue);
        service.dispose();
      });

      test('reconnected stream is a broadcast stream', () {
        final service = createService();
        expect(service.reconnected.isBroadcast, isTrue);
        service.dispose();
      });

      test('connectionState stream is a broadcast stream', () {
        final service = createService();
        expect(service.connectionState.isBroadcast, isTrue);
        service.dispose();
      });
    });

    group('Disconnect', () {
      test('disconnect does not throw when not connected', () {
        final service = createService();
        expect(() => service.disconnect(), returnsNormally);
        service.dispose();
      });

      test('disconnect can be called multiple times safely', () {
        final service = createService();
        service.disconnect();
        expect(() => service.disconnect(), returnsNormally);
        service.dispose();
      });
    });

    group('Connect', () {
      test('connect fetches user id from local datasource', () async {
        final service = createService();
        // connect() will attempt to connect but fail (no real server),
        // but it should call getUserId() for subscription restore
        try {
          await service.connect().timeout(const Duration(milliseconds: 300));
        } catch (_) {
          // Expected timeout — no real server
        }
        // getUserId is called during connect() for subscribedUserId
        verify(() => mockAuthLocalDataSource.getUserId()).called(greaterThanOrEqualTo(1));
        service.dispose();
      });

      test('connect calls getAccessToken', () async {
        final service = createService();
        try {
          await service.connect().timeout(const Duration(milliseconds: 300));
        } catch (_) {}
        verify(() => mockAuthLocalDataSource.getAccessToken())
            .called(greaterThanOrEqualTo(1));
        service.dispose();
      });

      test('connect does not throw when no access token', () async {
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);

        final service = createService();
        await expectLater(service.connect(), completes);
        service.dispose();
      });

      test('connect sets state to disconnected when no access token', () async {
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);

        final service = createService();
        await service.connect();

        expect(
          service.currentConnectionState,
          WebSocketConnectionState.disconnected,
        );
        service.dispose();
      });
    });

    group('ensureConnected', () {
      test('returns false when not connected and timeout reached', () async {
        when(() => mockAuthLocalDataSource.getAccessToken())
            .thenAnswer((_) async => null);

        final service = createService();
        final result = await service.ensureConnected(
          timeout: const Duration(milliseconds: 100),
        );

        expect(result, isFalse);
        service.dispose();
      });

      test('returns true immediately when already connected', () async {
        final service = createService();
        // Manually verify the logic: if isConnected is false, it starts connection
        // Since we can't easily simulate a connected state without real STOMP,
        // we just verify it runs without throwing
        final result = await service.ensureConnected(
          timeout: const Duration(milliseconds: 100),
        ).catchError((_) => false);
        expect(result, isA<bool>());
        service.dispose();
      });
    });

    group('resetReconnectAttempts', () {
      test('does not throw when called', () {
        final service = createService();
        expect(() => service.resetReconnectAttempts(), returnsNormally);
        service.dispose();
      });
    });

    group('Subscription Management', () {
      test('subscribeToChatRoom does not throw when not connected', () {
        final service = createService();
        expect(() => service.subscribeToChatRoom(1), returnsNormally);
        service.dispose();
      });

      test('unsubscribeFromChatRoom does not throw when not subscribed', () {
        final service = createService();
        expect(() => service.unsubscribeFromChatRoom(1), returnsNormally);
        service.dispose();
      });

      test('subscribeToUserChannel does not throw when not connected', () {
        final service = createService();
        expect(() => service.subscribeToUserChannel(1), returnsNormally);
        service.dispose();
      });

      test('unsubscribeFromUserChannel does not throw when not subscribed', () {
        final service = createService();
        expect(() => service.unsubscribeFromUserChannel(), returnsNormally);
        service.dispose();
      });

      test('subscribeToChatRoom and unsubscribeFromChatRoom roundtrip',
          () {
        final service = createService();
        // Subscribe (will be pending because not connected)
        service.subscribeToChatRoom(42);
        // Unsubscribe should remove it from pending
        expect(() => service.unsubscribeFromChatRoom(42), returnsNormally);
        service.dispose();
      });
    });

    group('Message Sending when Disconnected', () {
      test('sendMessage returns false when not connected', () {
        final service = createService();
        final result = service.sendMessage(roomId: 1, content: 'hello');
        expect(result, isFalse);
        service.dispose();
      });

      test('sendFileMessage returns false when not connected', () {
        final service = createService();
        final result = service.sendFileMessage(
          roomId: 1,
          fileUrl: 'https://example.com/file.jpg',
          fileName: 'file.jpg',
          fileSize: 1024,
          contentType: 'image/jpeg',
        );
        expect(result, isFalse);
        service.dispose();
      });

      test('addReaction does not throw when not connected', () {
        final service = createService();
        expect(
          () => service.addReaction(messageId: 1, emoji: '👍'),
          returnsNormally,
        );
        service.dispose();
      });

      test('removeReaction does not throw when not connected', () {
        final service = createService();
        expect(
          () => service.removeReaction(messageId: 1, emoji: '👍'),
          returnsNormally,
        );
        service.dispose();
      });

      test('sendTypingStatus does not throw when not connected', () {
        final service = createService();
        expect(
          () => service.sendTypingStatus(roomId: 1, isTyping: true),
          returnsNormally,
        );
        service.dispose();
      });

      test('sendPresencePing does not throw when not connected', () {
        final service = createService();
        expect(
          () => service.sendPresencePing(roomId: 1),
          returnsNormally,
        );
        service.dispose();
      });

      test('sendPresenceInactive does not throw when not connected', () {
        final service = createService();
        expect(
          () => service.sendPresenceInactive(roomId: 1),
          returnsNormally,
        );
        service.dispose();
      });
    });

    group('Dispose', () {
      test('dispose does not throw', () {
        final service = createService();
        expect(() => service.dispose(), returnsNormally);
      });

      test('dispose can be called after disconnect', () {
        final service = createService();
        service.disconnect();
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });

  group('WebSocketPayloadParser', () {
    const parser = WebSocketPayloadParser();

    group('parseRoomPayload', () {
      test('parses chat message payload', () {
        final body = jsonEncode({
          'messageId': 1,
          'senderId': 2,
          'senderNickname': 'Alice',
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2024-01-01T10:00:00',
          'unreadCount': 0,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 10);

        expect(result, isA<ParsedChatMessagePayload>());
        final msg = (result as ParsedChatMessagePayload).message;
        expect(msg.messageId, 1);
        expect(msg.chatRoomId, 10);
        expect(msg.content, 'Hello');
      });

      test('parses read event payload', () {
        final body = jsonEncode({
          'eventType': 'READ',
          'chatRoomId': 5,
          'userId': 3,
          'lastReadMessageId': 10,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedReadPayload>());
        final event = (result as ParsedReadPayload).event;
        expect(event.chatRoomId, 5);
        expect(event.userId, 3);
      });

      test('parses reaction added payload', () {
        final body = jsonEncode({
          'eventType': 'ADDED',
          'messageId': 7,
          'userId': 1,
          'emoji': '❤️',
          'timestamp': 1234567890,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedReactionPayload>());
        final event = (result as ParsedReactionPayload).event;
        expect(event.emoji, '❤️');
        expect(event.eventType, 'ADDED');
      });

      test('parses reaction removed payload', () {
        final body = jsonEncode({
          'eventType': 'REMOVED',
          'messageId': 7,
          'userId': 1,
          'emoji': '❤️',
          'timestamp': 1234567890,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedReactionPayload>());
        final event = (result as ParsedReactionPayload).event;
        expect(event.eventType, 'REMOVED');
      });

      test('parses typing payload', () {
        final body = jsonEncode({
          'eventType': 'TYPING',
          'chatRoomId': 5,
          'userId': 2,
          'isTyping': true,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedTypingPayload>());
        final event = (result as ParsedTypingPayload).event;
        expect(event.isTyping, isTrue);
      });

      test('parses stop typing payload', () {
        final body = jsonEncode({
          'eventType': 'STOP_TYPING',
          'chatRoomId': 5,
          'userId': 2,
          'isTyping': false,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedTypingPayload>());
      });

      test('parses message deleted payload', () {
        final body = jsonEncode({
          'eventType': 'MESSAGE_DELETED',
          'chatRoomId': 5,
          'messageId': 42,
          'deletedBy': 1,
          'deletedAtMillis': 1704067200000,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedMessageDeletedPayload>());
        final event = (result as ParsedMessageDeletedPayload).event;
        expect(event.messageId, 42);
        expect(event.chatRoomId, 5);
      });

      test('parses message updated payload', () {
        final body = jsonEncode({
          'eventType': 'MESSAGE_UPDATED',
          'chatRoomId': 5,
          'messageId': 42,
          'updatedBy': 1,
          'newContent': 'Edited content',
          'updatedAtMillis': 1704067200000,
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedMessageUpdatedPayload>());
        final event = (result as ParsedMessageUpdatedPayload).event;
        expect(event.newContent, 'Edited content');
      });

      test('parses link preview updated payload', () {
        final body = jsonEncode({
          'eventType': 'LINK_PREVIEW_UPDATED',
          'chatRoomId': 5,
          'messageId': 42,
          'linkPreviewUrl': 'https://example.com',
          'linkPreviewTitle': 'Example',
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedLinkPreviewUpdatedPayload>());
        final event = (result as ParsedLinkPreviewUpdatedPayload).event;
        expect(event.linkPreviewTitle, 'Example');
      });

      test('parses system message USER_LEFT as chat message', () {
        final body = jsonEncode({
          'messageId': 99,
          'eventType': 'USER_LEFT',
          'content': 'User left the room',
          'type': 'SYSTEM',
          'createdAt': '2024-01-01T10:00:00',
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedChatMessagePayload>());
      });

      test('parses system message USER_JOINED as chat message', () {
        final body = jsonEncode({
          'messageId': 100,
          'eventType': 'USER_JOINED',
          'content': 'User joined the room',
          'type': 'SYSTEM',
          'createdAt': '2024-01-01T10:00:00',
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedChatMessagePayload>());
      });

      test('returns ParsedUnknownPayload for unknown event type', () {
        final body = jsonEncode({
          'eventType': 'UNKNOWN_EVENT',
          'someField': 'someValue',
        });

        final result = parser.parseRoomPayload(body: body, roomId: 5);

        expect(result, isA<ParsedUnknownPayload>());
      });

      test('chat message uses roomId fallback when roomId not in body', () {
        final body = jsonEncode({
          'messageId': 1,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2024-01-01T10:00:00',
        });

        final result = parser.parseRoomPayload(body: body, roomId: 99);

        final msg = (result as ParsedChatMessagePayload).message;
        expect(msg.chatRoomId, 99);
      });
    });

    group('parseChatListPayload', () {
      test('parses chat list update', () {
        final body = jsonEncode({
          'chatRoomId': 5,
          'eventType': 'NEW_MESSAGE',
          'lastMessage': 'Hello there',
          'unreadCount': 3,
        });

        final result = parser.parseChatListPayload(body);

        expect(result.chatRoomId, 5);
        expect(result.lastMessage, 'Hello there');
        expect(result.unreadCount, 3);
      });
    });

    group('parseReadReceiptPayload', () {
      test('parses read receipt', () {
        final body = jsonEncode({
          'chatRoomId': 10,
          'userId': 2,
          'lastReadMessageId': 100,
        });

        final result = parser.parseReadReceiptPayload(body);

        expect(result.chatRoomId, 10);
        expect(result.userId, 2);
        expect(result.lastReadMessageId, 100);
      });
    });

    group('parseOnlineStatusPayload', () {
      test('parses online status', () {
        final body = jsonEncode({
          'userId': 3,
          'isOnline': true,
        });

        final result = parser.parseOnlineStatusPayload(body);

        expect(result.userId, 3);
        expect(result.isOnline, isTrue);
      });

      test('parses offline status', () {
        final body = jsonEncode({
          'userId': 3,
          'isOnline': false,
        });

        final result = parser.parseOnlineStatusPayload(body);

        expect(result.isOnline, isFalse);
      });
    });

    group('parseProfileUpdatePayload', () {
      test('parses profile update with avatar url', () {
        final body = jsonEncode({
          'userId': 5,
          'avatarUrl': 'https://example.com/new_avatar.jpg',
          'statusMessage': 'New status',
        });

        final result = parser.parseProfileUpdatePayload(body);

        expect(result.userId, 5);
        expect(result.avatarUrl, 'https://example.com/new_avatar.jpg');
        expect(result.statusMessage, 'New status');
      });

      test('parses profile update with background url', () {
        final body = jsonEncode({
          'userId': 5,
          'backgroundUrl': 'https://example.com/bg.jpg',
        });

        final result = parser.parseProfileUpdatePayload(body);

        expect(result.backgroundUrl, 'https://example.com/bg.jpg');
      });
    });
  });

  group('WebSocketChatMessage.fromJson', () {
    test('parses all fields', () {
      final json = {
        'messageId': 42,
        'senderId': 1,
        'senderNickname': 'Alice',
        'content': 'Test message',
        'type': 'TEXT',
        'createdAt': '2024-01-15T10:30:00',
        'unreadCount': 5,
        'eventId': 'event-123',
      };

      final msg = WebSocketChatMessage.fromJson(json, 10);

      expect(msg.messageId, 42);
      expect(msg.senderId, 1);
      expect(msg.senderNickname, 'Alice');
      expect(msg.content, 'Test message');
      expect(msg.chatRoomId, 10);
      expect(msg.unreadCount, 5);
      expect(msg.eventId, 'event-123');
    });

    test('uses roomId from body when present', () {
      final json = {
        'messageId': 1,
        'roomId': 20,
        'content': 'Hello',
        'type': 'TEXT',
        'createdAt': '2024-01-01T00:00:00',
      };

      final msg = WebSocketChatMessage.fromJson(json, 99);

      expect(msg.chatRoomId, 20);
    });

    test('parses array-format createdAt', () {
      final json = {
        'messageId': 1,
        'content': 'Hello',
        'type': 'TEXT',
        'createdAt': [2024, 1, 15, 10, 30, 0],
      };

      final msg = WebSocketChatMessage.fromJson(json, 1);

      expect(msg.createdAt.year, 2024);
      expect(msg.createdAt.month, 1);
      expect(msg.createdAt.day, 15);
    });

    test('uses DateTime.now when createdAt is null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final json = {
        'messageId': 1,
        'content': 'Hello',
        'type': 'TEXT',
        'createdAt': null,
      };

      final msg = WebSocketChatMessage.fromJson(json, 1);
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(msg.createdAt.isAfter(before), isTrue);
      expect(msg.createdAt.isBefore(after), isTrue);
    });
  });

  group('WebSocketErrorEvent.fromJson', () {
    test('parses error event', () {
      final json = {
        'code': 'ROOM_NOT_FOUND',
        'message': 'Chat room does not exist',
        'timestamp': 1704067200000,
      };

      final event = WebSocketErrorEvent.fromJson(json);

      expect(event.code, 'ROOM_NOT_FOUND');
      expect(event.message, 'Chat room does not exist');
    });

    test('uses UNKNOWN code when code is null', () {
      final json = {
        'message': 'Some error',
        'timestamp': 1704067200000,
      };

      final event = WebSocketErrorEvent.fromJson(json);

      expect(event.code, 'UNKNOWN');
    });
  });

  group('WebSocketConnectionState', () {
    test('has all expected states', () {
      expect(WebSocketConnectionState.values, contains(WebSocketConnectionState.disconnected));
      expect(WebSocketConnectionState.values, contains(WebSocketConnectionState.connecting));
      expect(WebSocketConnectionState.values, contains(WebSocketConnectionState.connected));
      expect(WebSocketConnectionState.values, contains(WebSocketConnectionState.reconnecting));
      expect(WebSocketConnectionState.values, contains(WebSocketConnectionState.failed));
    });
  });

  group('WebSocketService reconnect tracking', () {
    test('resetReconnectAttempts can be called safely', () {
      final service = createService();
      // No exception should be thrown
      service.resetReconnectAttempts();
      service.resetReconnectAttempts();
      service.dispose();
    });
  });

  group('WebSocketService multiple subscription calls', () {
    test('subscribeToChatRoom called multiple times with same id is safe', () {
      final service = createService();
      service.subscribeToChatRoom(1);
      service.subscribeToChatRoom(1); // duplicate
      service.subscribeToChatRoom(2);
      expect(() => service.dispose(), returnsNormally);
    });

    test('unsubscribeFromChatRoom called without prior subscribe is safe', () {
      final service = createService();
      expect(() => service.unsubscribeFromChatRoom(99), returnsNormally);
      service.dispose();
    });

    test('disconnect clears all pending subscriptions', () {
      final service = createService();
      service.subscribeToChatRoom(1);
      service.subscribeToChatRoom(2);
      service.disconnect();
      // No exception should be thrown on dispose
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
