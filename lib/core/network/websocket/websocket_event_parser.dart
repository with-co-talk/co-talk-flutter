import 'dart:convert';

import 'package:injectable/injectable.dart';

import 'websocket_events.dart';

/// Parsed room payload result types using sealed classes.
sealed class ParsedRoomPayload {
  const ParsedRoomPayload();
}

final class ParsedChatMessagePayload extends ParsedRoomPayload {
  final WebSocketChatMessage message;
  const ParsedChatMessagePayload(this.message);
}

final class ParsedReadPayload extends ParsedRoomPayload {
  final WebSocketReadEvent event;
  const ParsedReadPayload(this.event);
}

final class ParsedReactionPayload extends ParsedRoomPayload {
  final WebSocketReactionEvent event;
  const ParsedReactionPayload(this.event);
}

final class ParsedTypingPayload extends ParsedRoomPayload {
  final WebSocketTypingEvent event;
  const ParsedTypingPayload(this.event);
}

final class ParsedMessageDeletedPayload extends ParsedRoomPayload {
  final WebSocketMessageDeletedEvent event;
  const ParsedMessageDeletedPayload(this.event);
}

final class ParsedMessageUpdatedPayload extends ParsedRoomPayload {
  final WebSocketMessageUpdatedEvent event;
  const ParsedMessageUpdatedPayload(this.event);
}

final class ParsedLinkPreviewUpdatedPayload extends ParsedRoomPayload {
  final WebSocketLinkPreviewUpdatedEvent event;
  const ParsedLinkPreviewUpdatedPayload(this.event);
}

final class ParsedUnknownPayload extends ParsedRoomPayload {
  final Map<String, dynamic> raw;
  const ParsedUnknownPayload(this.raw);
}

/// WebSocket payload parser.
///
/// Converts incoming JSON payloads to typed event objects.
/// Separated from STOMP connection for testability.
@singleton
class WebSocketPayloadParser {
  const WebSocketPayloadParser();

  /// Parses a room topic payload into a typed event.
  ///
  /// Event type detection logic:
  /// - Messages: contain 'messageId' field
  /// - System messages: messageId + eventType (USER_LEFT, USER_JOINED)
  /// - Read events: eventType == 'READ'
  /// - Reactions: eventType == 'ADDED' or 'REMOVED'
  /// - Typing: eventType == 'TYPING' or 'STOP_TYPING'
  /// - Deletions: eventType == 'MESSAGE_DELETED'
  ParsedRoomPayload parseRoomPayload({
    required String body,
    required int roomId,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final eventType = json['eventType'] as String?;

    // Chat message (has messageId)
    // - Normal message: no eventType
    // - System message: eventType = USER_LEFT, USER_JOINED, etc.
    if (json.containsKey('messageId')) {
      final isSystemEvent = eventType == 'USER_LEFT' || eventType == 'USER_JOINED';
      if (eventType == null || isSystemEvent) {
        return ParsedChatMessagePayload(WebSocketChatMessage.fromJson(json, roomId));
      }
    }

    if (eventType == 'READ') {
      return ParsedReadPayload(WebSocketReadEvent.fromJson(json));
    }

    if (eventType == 'ADDED' || eventType == 'REMOVED') {
      return ParsedReactionPayload(WebSocketReactionEvent.fromJson(json));
    }

    if (eventType == 'TYPING' || eventType == 'STOP_TYPING') {
      return ParsedTypingPayload(WebSocketTypingEvent.fromJson(json));
    }

    if (eventType == 'MESSAGE_DELETED') {
      return ParsedMessageDeletedPayload(WebSocketMessageDeletedEvent.fromJson(json));
    }

    if (eventType == 'MESSAGE_UPDATED') {
      return ParsedMessageUpdatedPayload(WebSocketMessageUpdatedEvent.fromJson(json));
    }

    if (eventType == 'LINK_PREVIEW_UPDATED') {
      return ParsedLinkPreviewUpdatedPayload(WebSocketLinkPreviewUpdatedEvent.fromJson(json));
    }

    return ParsedUnknownPayload(json);
  }

  /// Parses a chat list update payload.
  WebSocketChatRoomUpdateEvent parseChatListPayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketChatRoomUpdateEvent.fromJson(json);
  }

  /// Parses a read receipt payload.
  WebSocketReadEvent parseReadReceiptPayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketReadEvent.fromJson(json);
  }

  /// Parses an online status payload.
  WebSocketOnlineStatusEvent parseOnlineStatusPayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketOnlineStatusEvent.fromJson(json);
  }

  /// Parses a profile update payload.
  WebSocketProfileUpdateEvent parseProfileUpdatePayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketProfileUpdateEvent.fromJson(json);
  }
}
