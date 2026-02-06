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
    required int senderId,
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
        'senderId': senderId,
        'content': content,
      }),
    );
    return true;
  }

  /// Sends a file message.
  ///
  /// Returns false if not connected.
  bool sendFileMessage({
    required StompClient? stompClient,
    required int roomId,
    required int senderId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
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
        'senderId': senderId,
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
    required int userId,
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
        'userId': userId,
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
    required int userId,
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
        'userId': userId,
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
    required int userId,
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
        'userId': userId,
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
    required int userId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendPresenceDestination,
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
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
    required int userId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      return false;
    }

    stompClient.send(
      destination: WebSocketConfig.sendPresenceInactiveDestination,
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
      }),
    );
    return true;
  }

  /// Sends mark as read.
  ///
  /// Returns false if not connected.
  bool sendMarkAsRead({
    required StompClient? stompClient,
    required int roomId,
    required int userId,
  }) {
    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] sendMarkAsRead: Not connected');
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint('[WebSocket] Sending markAsRead for room $roomId');
    }

    stompClient.send(
      destination: WebSocketConfig.sendMarkAsReadDestination,
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
      }),
    );
    return true;
  }
}
