import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_events.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_event_parser.dart';

void main() {
  group('WebSocketLinkPreviewUpdatedEvent', () {
    test('fromJson parses all fields correctly', () {
      // Arrange
      final json = {
        'schemaVersion': 1,
        'eventId': 'test-event-123',
        'chatRoomId': 42,
        'messageId': 100,
        'linkPreviewUrl': 'https://example.com',
        'linkPreviewTitle': 'Example Title',
        'linkPreviewDescription': 'Example description text',
        'linkPreviewImageUrl': 'https://example.com/image.png',
      };

      // Act
      final event = WebSocketLinkPreviewUpdatedEvent.fromJson(json);

      // Assert
      expect(event.schemaVersion, 1);
      expect(event.eventId, 'test-event-123');
      expect(event.chatRoomId, 42);
      expect(event.messageId, 100);
      expect(event.linkPreviewUrl, 'https://example.com');
      expect(event.linkPreviewTitle, 'Example Title');
      expect(event.linkPreviewDescription, 'Example description text');
      expect(event.linkPreviewImageUrl, 'https://example.com/image.png');
    });

    test('fromJson handles null optional fields', () {
      // Arrange
      final json = {
        'chatRoomId': 42,
        'messageId': 100,
      };

      // Act
      final event = WebSocketLinkPreviewUpdatedEvent.fromJson(json);

      // Assert
      expect(event.schemaVersion, null);
      expect(event.eventId, null);
      expect(event.chatRoomId, 42);
      expect(event.messageId, 100);
      expect(event.linkPreviewUrl, null);
      expect(event.linkPreviewTitle, null);
      expect(event.linkPreviewDescription, null);
      expect(event.linkPreviewImageUrl, null);
    });

    test('fromJson handles numeric types correctly', () {
      // Arrange - test both int and double inputs
      final json = {
        'chatRoomId': 42.0, // double
        'messageId': 100, // int
      };

      // Act
      final event = WebSocketLinkPreviewUpdatedEvent.fromJson(json);

      // Assert
      expect(event.chatRoomId, 42);
      expect(event.messageId, 100);
    });
  });

  group('WebSocketPayloadParser - LINK_PREVIEW_UPDATED', () {
    const parser = WebSocketPayloadParser();

    test('returns ParsedLinkPreviewUpdatedPayload for LINK_PREVIEW_UPDATED eventType', () {
      // Arrange
      final body = '''
      {
        "eventType": "LINK_PREVIEW_UPDATED",
        "schemaVersion": 1,
        "eventId": "test-event-456",
        "chatRoomId": 50,
        "messageId": 200,
        "linkPreviewUrl": "https://test.com",
        "linkPreviewTitle": "Test Title",
        "linkPreviewDescription": "Test Description",
        "linkPreviewImageUrl": "https://test.com/thumb.jpg"
      }
      ''';

      // Act
      final result = parser.parseRoomPayload(body: body, roomId: 50);

      // Assert
      expect(result, isA<ParsedLinkPreviewUpdatedPayload>());
      final payload = result as ParsedLinkPreviewUpdatedPayload;
      expect(payload.event.eventType, 'LINK_PREVIEW_UPDATED');
      expect(payload.event.chatRoomId, 50);
      expect(payload.event.messageId, 200);
      expect(payload.event.linkPreviewUrl, 'https://test.com');
      expect(payload.event.linkPreviewTitle, 'Test Title');
      expect(payload.event.linkPreviewDescription, 'Test Description');
      expect(payload.event.linkPreviewImageUrl, 'https://test.com/thumb.jpg');
    });

    test('parser handles minimal link preview event', () {
      // Arrange
      final body = '''
      {
        "eventType": "LINK_PREVIEW_UPDATED",
        "chatRoomId": 50,
        "messageId": 200
      }
      ''';

      // Act
      final result = parser.parseRoomPayload(body: body, roomId: 50);

      // Assert
      expect(result, isA<ParsedLinkPreviewUpdatedPayload>());
      final payload = result as ParsedLinkPreviewUpdatedPayload;
      expect(payload.event.chatRoomId, 50);
      expect(payload.event.messageId, 200);
      expect(payload.event.linkPreviewUrl, null);
      expect(payload.event.linkPreviewTitle, null);
    });
  });
}
