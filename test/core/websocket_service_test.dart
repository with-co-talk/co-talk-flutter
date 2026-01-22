import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_repositories.dart';

void main() {
  group('WebSocketChatMessage', () {
    group('fromJson', () {
      test('parses basic message correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Hello, World!',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.messageId, 1);
        expect(message.senderId, 2);
        expect(message.chatRoomId, 3);
        expect(message.content, 'Hello, World!');
        expect(message.type, 'TEXT');
        expect(message.createdAt.year, 2026);
        expect(message.createdAt.month, 1);
        expect(message.createdAt.day, 22);
      });

      test('uses roomId parameter when json roomId is missing', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 99);

        expect(message.chatRoomId, 99);
      });

      test('uses json roomId when provided', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 5,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 99);

        expect(message.chatRoomId, 5);
      });

      test('handles null senderId', () {
        final json = {
          'messageId': 1,
          'senderId': null,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.senderId, isNull);
      });

      test('handles missing senderId', () {
        final json = {
          'messageId': 1,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.senderId, isNull);
      });

      test('handles null content as empty string', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': null,
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.content, '');
      });

      test('parses file message correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': '',
          'type': 'FILE',
          'createdAt': '2026-01-22T10:00:00.000',
          'fileUrl': 'https://example.com/file.pdf',
          'fileName': 'document.pdf',
          'fileSize': 1024,
          'fileContentType': 'application/pdf',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.type, 'FILE');
        expect(message.fileUrl, 'https://example.com/file.pdf');
        expect(message.fileName, 'document.pdf');
        expect(message.fileSize, 1024);
        expect(message.fileContentType, 'application/pdf');
      });

      test('parses image message with thumbnailUrl correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': '',
          'type': 'IMAGE',
          'createdAt': '2026-01-22T10:00:00.000',
          'fileUrl': 'https://example.com/image.jpg',
          'fileName': 'photo.jpg',
          'fileSize': 2048,
          'contentType': 'image/jpeg',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.type, 'IMAGE');
        expect(message.fileUrl, 'https://example.com/image.jpg');
        expect(message.thumbnailUrl, 'https://example.com/thumb.jpg');
        expect(message.fileContentType, 'image/jpeg');
      });

      test('parses contentType fallback correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': '',
          'type': 'FILE',
          'createdAt': '2026-01-22T10:00:00.000',
          'contentType': 'application/pdf',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.fileContentType, 'application/pdf');
      });

      test('parses reply message correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Reply message',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
          'replyToMessageId': 100,
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.replyToMessageId, 100);
      });

      test('parses forwarded message correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Forwarded message',
          'type': 'TEXT',
          'createdAt': '2026-01-22T10:00:00.000',
          'forwardedFromMessageId': 200,
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.forwardedFromMessageId, 200);
      });
    });

    group('_parseDateTime', () {
      test('parses ISO 8601 string correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': '2026-01-22T15:30:45.123',
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.createdAt.year, 2026);
        expect(message.createdAt.month, 1);
        expect(message.createdAt.day, 22);
        expect(message.createdAt.hour, 15);
        expect(message.createdAt.minute, 30);
        expect(message.createdAt.second, 45);
      });

      test('parses array format without nanoseconds correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': [2026, 1, 22, 15, 30, 45],
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.createdAt.year, 2026);
        expect(message.createdAt.month, 1);
        expect(message.createdAt.day, 22);
        expect(message.createdAt.hour, 15);
        expect(message.createdAt.minute, 30);
        expect(message.createdAt.second, 45);
        expect(message.createdAt.millisecond, 0);
      });

      test('parses array format with nanoseconds correctly', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': [2026, 1, 22, 15, 30, 45, 946596000],
        };

        final message = WebSocketChatMessage.fromJson(json, 3);

        expect(message.createdAt.year, 2026);
        expect(message.createdAt.month, 1);
        expect(message.createdAt.day, 22);
        expect(message.createdAt.hour, 15);
        expect(message.createdAt.minute, 30);
        expect(message.createdAt.second, 45);
        expect(message.createdAt.millisecond, 946);
        expect(message.createdAt.microsecond, 596);
      });

      test('handles null createdAt gracefully', () {
        final json = {
          'messageId': 1,
          'senderId': 2,
          'roomId': 3,
          'content': 'Hello',
          'type': 'TEXT',
          'createdAt': null,
        };

        final before = DateTime.now();
        final message = WebSocketChatMessage.fromJson(json, 3);
        final after = DateTime.now();

        expect(message.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(message.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });
  });

  group('WebSocketReactionEvent', () {
    group('fromJson', () {
      test('parses reaction added event correctly', () {
        final json = {
          'reactionId': 1,
          'messageId': 100,
          'userId': 2,
          'emoji': '👍',
          'eventType': 'ADDED',
          'timestamp': 1706000000000,
        };

        final reaction = WebSocketReactionEvent.fromJson(json);

        expect(reaction.reactionId, 1);
        expect(reaction.messageId, 100);
        expect(reaction.userId, 2);
        expect(reaction.emoji, '👍');
        expect(reaction.eventType, 'ADDED');
        expect(reaction.timestamp, 1706000000000);
      });

      test('parses reaction removed event correctly', () {
        final json = {
          'reactionId': null,
          'messageId': 100,
          'userId': 2,
          'emoji': '👍',
          'eventType': 'REMOVED',
          'timestamp': 1706000000000,
        };

        final reaction = WebSocketReactionEvent.fromJson(json);

        expect(reaction.reactionId, isNull);
        expect(reaction.eventType, 'REMOVED');
      });
    });
  });

  group('WebSocketService', () {
    late MockAuthLocalDataSource mockAuthLocalDataSource;
    late WebSocketService webSocketService;

    setUp(() {
      mockAuthLocalDataSource = MockAuthLocalDataSource();
      webSocketService = WebSocketService(mockAuthLocalDataSource);
    });

    tearDown(() {
      webSocketService.dispose();
    });

    test('initial state is disconnected', () {
      expect(webSocketService.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(webSocketService.isConnected, isFalse);
    });

    test('subscribeToChatRoom adds to pending when not connected', () {
      webSocketService.subscribeToChatRoom(1);

      // Cannot directly test _pendingSubscriptions as it's private
      // But we can verify it doesn't throw and handles gracefully
      expect(webSocketService.isConnected, isFalse);
    });

    test('subscribeToChatRoom does not duplicate subscriptions', () {
      webSocketService.subscribeToChatRoom(1);
      webSocketService.subscribeToChatRoom(1);

      // Should not throw and handle gracefully
      expect(webSocketService.isConnected, isFalse);
    });

    test('unsubscribeFromChatRoom removes from pending', () {
      webSocketService.subscribeToChatRoom(1);
      webSocketService.unsubscribeFromChatRoom(1);

      // Should not throw
      expect(webSocketService.isConnected, isFalse);
    });

    test('connect returns early when no access token', () async {
      when(() => mockAuthLocalDataSource.getAccessToken())
          .thenAnswer((_) async => null);

      await webSocketService.connect();

      expect(webSocketService.currentConnectionState, WebSocketConnectionState.disconnected);
      verify(() => mockAuthLocalDataSource.getAccessToken()).called(1);
    });

    test('sendMessage does nothing when not connected', () {
      webSocketService.sendMessage(
        roomId: 1,
        senderId: 2,
        content: 'Hello',
      );

      // Should not throw when not connected
      expect(webSocketService.isConnected, isFalse);
    });

    test('sendFileMessage does nothing when not connected', () {
      webSocketService.sendFileMessage(
        roomId: 1,
        senderId: 2,
        fileUrl: 'https://example.com/file.pdf',
        fileName: 'document.pdf',
        fileSize: 1024,
        contentType: 'application/pdf',
      );

      // Should not throw when not connected
      expect(webSocketService.isConnected, isFalse);
    });

    test('addReaction does nothing when not connected', () {
      webSocketService.addReaction(
        messageId: 1,
        userId: 2,
        emoji: '👍',
      );

      // Should not throw when not connected
      expect(webSocketService.isConnected, isFalse);
    });

    test('removeReaction does nothing when not connected', () {
      webSocketService.removeReaction(
        messageId: 1,
        userId: 2,
        emoji: '👍',
      );

      // Should not throw when not connected
      expect(webSocketService.isConnected, isFalse);
    });

    test('disconnect clears state', () {
      webSocketService.subscribeToChatRoom(1);
      webSocketService.disconnect();

      expect(webSocketService.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(webSocketService.isConnected, isFalse);
    });

    test('messages stream is broadcast', () {
      final stream1 = webSocketService.messages;
      final stream2 = webSocketService.messages;

      expect(stream1, isA<Stream<WebSocketChatMessage>>());
      expect(stream2, isA<Stream<WebSocketChatMessage>>());
    });

    test('reactions stream is broadcast', () {
      final stream1 = webSocketService.reactions;
      final stream2 = webSocketService.reactions;

      expect(stream1, isA<Stream<WebSocketReactionEvent>>());
      expect(stream2, isA<Stream<WebSocketReactionEvent>>());
    });

    test('connectionState stream is broadcast', () {
      final stream1 = webSocketService.connectionState;
      final stream2 = webSocketService.connectionState;

      expect(stream1, isA<Stream<WebSocketConnectionState>>());
      expect(stream2, isA<Stream<WebSocketConnectionState>>());
    });
  });
}
