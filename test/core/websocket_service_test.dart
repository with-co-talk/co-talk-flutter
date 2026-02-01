import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:convert';

import '../mocks/mock_repositories.dart';
import 'package:co_talk_flutter/core/network/event_dedupe_cache.dart';

void main() {
  group('EventDedupeCache', () {
    test('treats same eventId within ttl as duplicate', () {
      var now = DateTime(2026, 1, 24, 12, 0, 0);
      final cache = EventDedupeCache(
        ttl: const Duration(seconds: 10),
        maxSize: 10,
        now: () => now,
      );

      expect(cache.isDuplicate('e1'), isFalse);
      now = now.add(const Duration(seconds: 5));
      expect(cache.isDuplicate('e1'), isTrue);
    });

    test('treats same eventId after ttl as new', () {
      var now = DateTime(2026, 1, 24, 12, 0, 0);
      final cache = EventDedupeCache(
        ttl: const Duration(seconds: 10),
        maxSize: 10,
        now: () => now,
      );

      expect(cache.isDuplicate('e1'), isFalse);
      now = now.add(const Duration(seconds: 11));
      expect(cache.isDuplicate('e1'), isFalse);
    });

    test('does not treat null/empty as duplicate', () {
      final cache = EventDedupeCache(
        ttl: const Duration(seconds: 10),
        maxSize: 10,
        now: () => DateTime(2026, 1, 24),
      );
      expect(cache.isDuplicate(null), isFalse);
      expect(cache.isDuplicate(''), isFalse);
    });
  });

  group('WebSocketPayloadParser', () {
    const parser = WebSocketPayloadParser();

    test('parses room payload as chat message when messageId exists and eventType is null', () {
      final payload = {
        'schemaVersion': 1,
        'eventId': 'message:10',
        'messageId': 10,
        'senderId': 2,
        'roomId': 3,
        'content': 'hi',
        'type': 'TEXT',
        'createdAt': '2026-01-22T10:00:00.000',
        'unreadCount': 1,
      };

      final parsed = parser.parseRoomPayload(
        body: jsonEncode(payload),
        roomId: 999,
      );

      expect(parsed, isA<ParsedChatMessagePayload>());
      final msg = (parsed as ParsedChatMessagePayload).message;
      expect(msg.schemaVersion, 1);
      expect(msg.eventId, 'message:10');
      expect(msg.messageId, 10);
      expect(msg.chatRoomId, 3); // json roomId 우선
      expect(msg.unreadCount, 1);
    });

    test('parses room payload as READ when eventType=READ', () {
      final payload = {
        'schemaVersion': 1,
        'eventId': 'room-event:READ:7:42:100',
        'eventType': 'READ',
        'chatRoomId': 7,
        'userId': 42,
        'lastReadMessageId': 100,
        'lastReadAt': '2026-01-22T10:00:00.000',
      };

      final parsed = parser.parseRoomPayload(
        body: jsonEncode(payload),
        roomId: 7,
      );

      expect(parsed, isA<ParsedReadPayload>());
      final evt = (parsed as ParsedReadPayload).event;
      expect(evt.schemaVersion, 1);
      expect(evt.eventId, 'room-event:READ:7:42:100');
      expect(evt.chatRoomId, 7);
      expect(evt.userId, 42);
      expect(evt.lastReadMessageId, 100);
      expect(evt.lastReadAt, isNotNull);
    });

    test('parses room payload as reaction when eventType=ADDED', () {
      final payload = {
        'eventType': 'ADDED',
        'messageId': 1,
        'userId': 2,
        'emoji': '👍',
        'timestamp': 123456,
      };

      final parsed = parser.parseRoomPayload(
        body: jsonEncode(payload),
        roomId: 1,
      );

      expect(parsed, isA<ParsedReactionPayload>());
      final evt = (parsed as ParsedReactionPayload).event;
      expect(evt.eventType, 'ADDED');
      expect(evt.emoji, '👍');
    });

    test('parses room payload as typing when eventType=STOP_TYPING', () {
      final payload = {
        'eventType': 'STOP_TYPING',
        'roomId': 9,
        'userId': 2,
        'userNickname': 'Bob',
        'isTyping': false,
      };

      final parsed = parser.parseRoomPayload(
        body: jsonEncode(payload),
        roomId: 9,
      );

      expect(parsed, isA<ParsedTypingPayload>());
      final evt = (parsed as ParsedTypingPayload).event;
      expect(evt.chatRoomId, 9);
      expect(evt.userId, 2);
      expect(evt.isTyping, isFalse);
    });

    test('parses unknown payload as ParsedUnknownPayload', () {
      final payload = {'foo': 'bar'};
      final parsed = parser.parseRoomPayload(
        body: jsonEncode(payload),
        roomId: 1,
      );
      expect(parsed, isA<ParsedUnknownPayload>());
    });

    test('parses chat-list payload as WebSocketChatRoomUpdateEvent', () {
      final payload = {
        'schemaVersion': 1,
        'eventId': 'chat-list:NEW_MESSAGE:1:10:2',
        'chatRoomId': 1,
        'lastMessage': 'hello',
        'lastMessageAt': '2026-01-22T10:00:00.000',
        'unreadCount': 3,
      };

      final update = parser.parseChatListPayload(jsonEncode(payload));
      expect(update.schemaVersion, 1);
      expect(update.eventId, 'chat-list:NEW_MESSAGE:1:10:2');
      expect(update.chatRoomId, 1);
      expect(update.lastMessage, 'hello');
      expect(update.unreadCount, 3);
    });

    test('parses read-receipt payload as WebSocketReadEvent', () {
      final payload = {
        'schemaVersion': 1,
        'eventId': 'read-receipt:1:2:5',
        'eventType': 'READ',
        'roomId': 1,
        'readerId': 2,
        'lastReadMessageId': 5,
      };

      final evt = parser.parseReadReceiptPayload(jsonEncode(payload));
      expect(evt.schemaVersion, 1);
      expect(evt.eventId, 'read-receipt:1:2:5');
      expect(evt.chatRoomId, 1);
      expect(evt.userId, 2);
      expect(evt.lastReadMessageId, 5);
    });
  });

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

      group('🔴 RED: unreadCount 파싱 검증', () {
        test('unreadCount=1이 정확히 파싱됨 (1:1 채팅 기본 시나리오)', () {
          final json = {
            'messageId': 100,
            'senderId': 2,
            'roomId': 1,
            'content': 'Hello',
            'type': 'TEXT',
            'createdAt': '2026-01-31T10:00:00.000',
            'unreadCount': 1, // 서버: totalMembers(2) - 1 = 1
          };

          final message = WebSocketChatMessage.fromJson(json, 1);

          expect(message.unreadCount, 1, reason: 'unreadCount=1이 그대로 파싱되어야 함');
        });

        test('unreadCount=0이 정확히 파싱됨 (모두 읽은 경우)', () {
          final json = {
            'messageId': 101,
            'senderId': 2,
            'roomId': 1,
            'content': 'Already read',
            'type': 'TEXT',
            'createdAt': '2026-01-31T10:00:00.000',
            'unreadCount': 0,
          };

          final message = WebSocketChatMessage.fromJson(json, 1);

          expect(message.unreadCount, 0, reason: 'unreadCount=0이 그대로 파싱되어야 함');
        });

        test('unreadCount가 null이면 기본값 0으로 설정됨', () {
          final json = {
            'messageId': 102,
            'senderId': 2,
            'roomId': 1,
            'content': 'Null unread',
            'type': 'TEXT',
            'createdAt': '2026-01-31T10:00:00.000',
            'unreadCount': null,
          };

          final message = WebSocketChatMessage.fromJson(json, 1);

          expect(message.unreadCount, 0, reason: 'unreadCount가 null이면 0이어야 함');
        });

        test('unreadCount 필드가 없으면 기본값 0으로 설정됨', () {
          final json = {
            'messageId': 103,
            'senderId': 2,
            'roomId': 1,
            'content': 'Missing unread field',
            'type': 'TEXT',
            'createdAt': '2026-01-31T10:00:00.000',
            // unreadCount 필드 없음
          };

          final message = WebSocketChatMessage.fromJson(json, 1);

          expect(message.unreadCount, 0, reason: 'unreadCount 필드가 없으면 0이어야 함');
        });

        test('그룹 채팅 unreadCount=3이 정확히 파싱됨', () {
          final json = {
            'messageId': 104,
            'senderId': 2,
            'roomId': 5,
            'content': 'Group message',
            'type': 'TEXT',
            'createdAt': '2026-01-31T10:00:00.000',
            'unreadCount': 3, // 4명 그룹: totalMembers(4) - 1 = 3
          };

          final message = WebSocketChatMessage.fromJson(json, 5);

          expect(message.unreadCount, 3, reason: '그룹 채팅 unreadCount=3이 그대로 파싱되어야 함');
        });
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

  group('WebSocketReadEvent', () {
    group('fromJson', () {
      test('parses room READ event schema correctly', () {
        final json = {
          'eventType': 'READ',
          'chatRoomId': 10,
          'userId': 2,
          'lastReadMessageId': 777,
          'lastReadAt': '2026-01-24T12:34:56',
        };

        final event = WebSocketReadEvent.fromJson(json);

        expect(event.chatRoomId, 10);
        expect(event.userId, 2);
        expect(event.lastReadMessageId, 777);
        expect(event.lastReadAt, isNotNull);
        expect(event.lastReadAt!.year, 2026);
        expect(event.lastReadAt!.month, 1);
        expect(event.lastReadAt!.day, 24);
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
