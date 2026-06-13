import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'websocket_config.dart';

/// Handles sending messages through WebSocket.
///
/// Responsibilities:
/// - Text message sending
/// - File message sending
/// - Reaction management (add/remove)
/// - Typing indicator sending
/// - Presence management (ping/inactive)
/// - Read status sending
class WebSocketMessageSender {
  /// Sends a text message.
  ///
  /// Returns false if not connected.
  bool sendMessage({
    required StompClient? stompClient,
    required int roomId,
    required String content,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] sendMessage: Not connected');
      }
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendMessageDestination,
      body: jsonEncode({
        'roomId': roomId,
        'content': content,
      }),
    );
    return true;
  }

  /// Sends a file message.
  ///
  /// Returns false if not connected.
  ///
  /// NOTE: 실제 파일 메시지 전송은 REST(`SendFileMessageRequest`) 경로를 사용한다.
  /// [objectId]/[thumbnailObjectId]는 현재 이 WS 경로에서 미사용이며(호출부 전부 null),
  /// 향후 WS 파일 전송 시 REST 경로와의 일관성을 위해 옵셔널로 미리 배선해 둔 것이다.
  bool sendFileMessage({
    required StompClient? stompClient,
    required int roomId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
    String? objectId,
    String? thumbnailObjectId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] sendFileMessage: Not connected');
      }
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendFileMessageDestination,
      body: jsonEncode({
        'roomId': roomId,
        // 신규 방식: object-id (서버가 존재 시 우선 사용). 하위호환을 위해 fileUrl도 함께 전송.
        if (objectId != null) 'objectId': objectId,
        if (thumbnailObjectId != null) 'thumbnailObjectId': thumbnailObjectId,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
        'thumbnailUrl': thumbnailUrl,
      }),
    );
    return true;
  }

  /// Adds a reaction to a message.
  ///
  /// Returns false if not connected.
  bool addReaction({
    required StompClient? stompClient,
    required int messageId,
    required String emoji,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] addReaction: Not connected');
      }
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendReactionAddDestination,
      body: jsonEncode({
        'messageId': messageId,
        'emoji': emoji,
      }),
    );
    return true;
  }

  /// Removes a reaction from a message.
  ///
  /// Returns false if not connected.
  bool removeReaction({
    required StompClient? stompClient,
    required int messageId,
    required String emoji,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] removeReaction: Not connected');
      }
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendReactionRemoveDestination,
      body: jsonEncode({
        'messageId': messageId,
        'emoji': emoji,
      }),
    );
    return true;
  }

  /// Sends typing status.
  ///
  /// Returns false if not connected.
  bool sendTypingStatus({
    required StompClient? stompClient,
    required int roomId,
    required bool isTyping,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] sendTypingStatus: Not connected');
      }
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendTypingDestination,
      body: jsonEncode({
        'roomId': roomId,
        'isTyping': isTyping,
      }),
    );
    return true;
  }

  /// Sends presence ping (TTL renewal).
  ///
  /// Returns false if not connected.
  bool sendPresencePing({
    required StompClient? stompClient,
    required int roomId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendPresenceDestination,
      body: jsonEncode({
        'roomId': roomId,
      }),
    );
    return true;
  }

  /// Sends presence inactive (immediate TTL release).
  ///
  /// Returns false if not connected.
  bool sendPresenceInactive({
    required StompClient? stompClient,
    required int roomId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendPresenceInactiveDestination,
      body: jsonEncode({
        'roomId': roomId,
      }),
    );
    return true;
  }

}
