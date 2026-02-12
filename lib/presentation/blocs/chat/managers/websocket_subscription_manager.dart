import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../domain/entities/message.dart';

/// Manages WebSocket subscriptions for chat room events.
///
/// Handles:
/// - Message subscriptions
/// - Read event subscriptions
/// - Typing event subscriptions
/// - Message deleted event subscriptions
/// - Subscription lifecycle and cleanup
class WebSocketSubscriptionManager {
  final WebSocketService _webSocketService;

  StreamSubscription<WebSocketChatMessage>? _messageSubscription;
  StreamSubscription<WebSocketReadEvent>? _readEventSubscription;
  StreamSubscription<WebSocketTypingEvent>? _typingSubscription;
  StreamSubscription<WebSocketMessageDeletedEvent>? _messageDeletedSubscription;
  StreamSubscription<WebSocketMessageUpdatedEvent>? _messageUpdatedSubscription;
  StreamSubscription<WebSocketLinkPreviewUpdatedEvent>? _linkPreviewUpdatedSubscription;
  StreamSubscription<WebSocketReactionEvent>? _reactionSubscription;

  int? _lastKnownMessageId;
  bool _isRoomSubscribed = false;

  WebSocketSubscriptionManager(this._webSocketService);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WebSocketSubscriptionManager] $message');
    }
  }

  /// Subscribes to WebSocket events for a specific room.
  void subscribeToRoom(
    int roomId, {
    int? lastMessageId,
    required Function(WebSocketChatMessage) onMessage,
    required Function(WebSocketReadEvent) onReadEvent,
    required Function(WebSocketTypingEvent) onTypingEvent,
    required Function(WebSocketMessageDeletedEvent) onMessageDeleted,
    required Function(WebSocketMessageUpdatedEvent) onMessageUpdated,
    required Function(WebSocketLinkPreviewUpdatedEvent) onLinkPreviewUpdated,
    required Function(WebSocketReactionEvent) onReactionEvent,
  }) {
    final isConnected = _webSocketService.isConnected;
    _log('subscribeToRoom: roomId=$roomId, lastMessageId=$lastMessageId, wsConnected=$isConnected');

    _lastKnownMessageId = lastMessageId;
    cancelSubscriptions();

    _webSocketService.subscribeToChatRoom(roomId);
    _isRoomSubscribed = true;
    _log('subscribeToRoom: STOMP subscription requested, now listening to streams');

    _messageSubscription = _webSocketService.messages.listen(
      (wsMessage) {
        _log('STREAM received message: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}, senderId=${wsMessage.senderId}, unreadCount=${wsMessage.unreadCount}');
        onMessage(wsMessage);
      },
      onError: (error) {
        _log('Error in message stream: $error');
      },
      onDone: () {
        _log('Message stream closed');
      },
    );

    _readEventSubscription = _webSocketService.readEvents.listen(
      (readEvent) {
        _log('ReadEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
        onReadEvent(readEvent);
      },
      onError: (error) {
        _log('Error in readEvent stream: $error');
      },
    );

    _typingSubscription = _webSocketService.typingEvents.listen(
      (typingEvent) {
        onTypingEvent(typingEvent);
      },
      onError: (error) {
        _log('Error in typing event stream: $error');
      },
    );

    _messageDeletedSubscription = _webSocketService.messageDeletedEvents.listen(
      (deletedEvent) {
        _log('WebSocket message deleted: messageId=${deletedEvent.messageId}, roomId=${deletedEvent.chatRoomId}');
        onMessageDeleted(deletedEvent);
      },
      onError: (error) {
        _log('Error in message deleted stream: $error');
      },
    );

    _messageUpdatedSubscription = _webSocketService.messageUpdatedEvents.listen(
      (updatedEvent) {
        _log('WebSocket message updated: messageId=${updatedEvent.messageId}, roomId=${updatedEvent.chatRoomId}');
        onMessageUpdated(updatedEvent);
      },
      onError: (error) {
        _log('Error in message updated stream: $error');
      },
    );

    _linkPreviewUpdatedSubscription = _webSocketService.linkPreviewUpdatedEvents.listen(
      (linkPreviewEvent) {
        _log('WebSocket link preview updated: messageId=${linkPreviewEvent.messageId}, roomId=${linkPreviewEvent.chatRoomId}');
        onLinkPreviewUpdated(linkPreviewEvent);
      },
      onError: (error) {
        _log('Error in link preview updated stream: $error');
      },
    );

    _reactionSubscription = _webSocketService.reactions.listen(
      (reactionEvent) {
        _log('WebSocket reaction: messageId=${reactionEvent.messageId}, userId=${reactionEvent.userId}, emoji=${reactionEvent.emoji}, type=${reactionEvent.eventType}');
        onReactionEvent(reactionEvent);
      },
      onError: (error) {
        _log('Error in reaction event stream: $error');
      },
    );
  }

  /// Unsubscribes from the current room.
  void unsubscribeFromRoom(int roomId) {
    if (_isRoomSubscribed) {
      _webSocketService.unsubscribeFromChatRoom(roomId);
      _isRoomSubscribed = false;
    }
    cancelSubscriptions();
  }

  /// Cancels all active subscriptions.
  void cancelSubscriptions() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _readEventSubscription?.cancel();
    _readEventSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _messageDeletedSubscription?.cancel();
    _messageDeletedSubscription = null;
    _messageUpdatedSubscription?.cancel();
    _messageUpdatedSubscription = null;
    _linkPreviewUpdatedSubscription?.cancel();
    _linkPreviewUpdatedSubscription = null;
    _reactionSubscription?.cancel();
    _reactionSubscription = null;
  }

  /// Converts WebSocket message to domain Message entity.
  Message convertToMessage(WebSocketChatMessage wsMessage) {
    return Message(
      id: wsMessage.messageId,
      chatRoomId: wsMessage.chatRoomId,
      senderId: wsMessage.senderId ?? 0,
      senderNickname: wsMessage.senderNickname,
      senderAvatarUrl: wsMessage.senderAvatarUrl,
      content: wsMessage.content,
      type: _parseMessageType(wsMessage.type),
      createdAt: wsMessage.createdAt,
      fileUrl: wsMessage.fileUrl,
      fileName: wsMessage.fileName,
      fileSize: wsMessage.fileSize,
      fileContentType: wsMessage.fileContentType,
      thumbnailUrl: wsMessage.thumbnailUrl,
      replyToMessageId: wsMessage.replyToMessageId,
      forwardedFromMessageId: wsMessage.forwardedFromMessageId,
      unreadCount: wsMessage.unreadCount,
    );
  }

  MessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'SYSTEM':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Checks if a message should be filtered based on last known message ID.
  bool shouldFilterMessage(int messageId) {
    if (_lastKnownMessageId != null && messageId <= _lastKnownMessageId!) {
      return true;
    }
    return false;
  }

  /// Updates the last known message ID (e.g., after gap recovery).
  void updateLastKnownMessageId(int messageId) {
    _lastKnownMessageId = messageId;
    _log('Updated lastKnownMessageId to $messageId');
  }

  bool get isRoomSubscribed => _isRoomSubscribed;

  int? get lastKnownMessageId => _lastKnownMessageId;

  void dispose() {
    cancelSubscriptions();
  }
}
