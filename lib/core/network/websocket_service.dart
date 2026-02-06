import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../data/datasources/local/auth_local_datasource.dart';
import 'event_dedupe_cache.dart';
import 'websocket/websocket.dart';

// Re-export all event types and parser for backward compatibility
export 'websocket/websocket_event_parser.dart'
    show
        ParsedRoomPayload,
        ParsedChatMessagePayload,
        ParsedReadPayload,
        ParsedReactionPayload,
        ParsedTypingPayload,
        ParsedMessageDeletedPayload,
        ParsedUnknownPayload,
        WebSocketPayloadParser;
export 'websocket/websocket_events.dart';

/// STOMP WebSocket service facade.
///
/// Provides a unified API for real-time chat communication by composing:
/// - [WebSocketConnectionManager]: Connection lifecycle
/// - [WebSocketSubscriptionManager]: Topic subscriptions
/// - [WebSocketMessageSender]: Message sending
/// - [WebSocketPayloadParser]: Payload parsing
///
/// This facade maintains backward compatibility with the original API
/// while internally using modular components.
@lazySingleton
class WebSocketService {
  final AuthLocalDataSource _authLocalDataSource;
  final WebSocketPayloadParser _payloadParser;
  final WebSocketConnectionManager _connectionManager;
  final WebSocketSubscriptionManager _subscriptionManager;
  final WebSocketMessageSender _messageSender;
  final EventDedupeCache _dedupeCache;

  // Event stream controllers
  final _messageController = StreamController<WebSocketChatMessage>.broadcast();
  final _reactionController = StreamController<WebSocketReactionEvent>.broadcast();
  final _readEventController = StreamController<WebSocketReadEvent>.broadcast();
  final _chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>.broadcast();
  final _typingController = StreamController<WebSocketTypingEvent>.broadcast();
  final _onlineStatusController = StreamController<WebSocketOnlineStatusEvent>.broadcast();
  final _messageDeletedController = StreamController<WebSocketMessageDeletedEvent>.broadcast();
  final _profileUpdateController = StreamController<WebSocketProfileUpdateEvent>.broadcast();

  WebSocketService(
    this._authLocalDataSource, {
    WebSocketPayloadParser payloadParser = const WebSocketPayloadParser(),
  })  : _payloadParser = payloadParser,
        _connectionManager = WebSocketConnectionManager(_authLocalDataSource),
        _subscriptionManager = WebSocketSubscriptionManager(),
        _messageSender = WebSocketMessageSender(),
        _dedupeCache = EventDedupeCache(
          ttl: WebSocketConfig.dedupeCacheTtl,
          maxSize: WebSocketConfig.dedupeCacheMaxSize,
        ) {
    _setupConnectionCallbacks();
  }

  void _setupConnectionCallbacks() {
    _connectionManager.onConnected = _onConnected;
    _connectionManager.onDisconnected = _onDisconnected;
  }

  // ============================================================
  // Connection State
  // ============================================================

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionManager.connectionState;

  /// Current connection state.
  WebSocketConnectionState get currentConnectionState =>
      _connectionManager.currentConnectionState;

  /// Whether currently connected.
  bool get isConnected => _connectionManager.isConnected;

  // ============================================================
  // Event Streams
  // ============================================================

  /// Stream of incoming chat messages.
  Stream<WebSocketChatMessage> get messages => _messageController.stream;

  /// Stream of reaction events.
  Stream<WebSocketReactionEvent> get reactions => _reactionController.stream;

  /// Stream of read receipt events.
  Stream<WebSocketReadEvent> get readEvents => _readEventController.stream;

  /// Stream of chat room list updates.
  Stream<WebSocketChatRoomUpdateEvent> get chatRoomUpdates =>
      _chatRoomUpdateController.stream;

  /// Stream of typing indicator events.
  Stream<WebSocketTypingEvent> get typingEvents => _typingController.stream;

  /// Stream of online status events.
  Stream<WebSocketOnlineStatusEvent> get onlineStatusEvents =>
      _onlineStatusController.stream;

  /// Stream of message deletion events.
  Stream<WebSocketMessageDeletedEvent> get messageDeletedEvents =>
      _messageDeletedController.stream;

  /// Stream of profile update events.
  Stream<WebSocketProfileUpdateEvent> get profileUpdateEvents =>
      _profileUpdateController.stream;

  // ============================================================
  // Connection Management
  // ============================================================

  /// Connects to the WebSocket server.
  Future<void> connect() async {
    // Auto-restore user channel subscription on connect
    _subscriptionManager.subscribedUserId ??=
        await _authLocalDataSource.getUserId();

    await _connectionManager.connect();
  }

  /// Disconnects from the WebSocket server.
  void disconnect() {
    _subscriptionManager.dispose();
    _connectionManager.disconnect();
  }

  // ============================================================
  // Subscriptions
  // ============================================================

  /// Subscribes to a chat room for real-time messages.
  void subscribeToChatRoom(int roomId) {
    _subscriptionManager.subscribeToChatRoom(
      roomId: roomId,
      stompClient: _connectionManager.stompClient,
      onMessage: (frame) => _handleRoomMessage(frame, roomId),
    );
  }

  /// Unsubscribes from a chat room.
  void unsubscribeFromChatRoom(int roomId) {
    _subscriptionManager.unsubscribeFromChatRoom(roomId);
  }

  /// Subscribes to user-specific channels (chat-list, read-receipt, online-status, profile-update).
  void subscribeToUserChannel(int userId) {
    _subscriptionManager.subscribeToUserChannel(
      userId: userId,
      stompClient: _connectionManager.stompClient,
      onChatListMessage: _handleChatListMessage,
      onReadReceiptMessage: _handleReadReceiptMessage,
      onOnlineStatusMessage: _handleOnlineStatusMessage,
      onProfileUpdateMessage: _handleProfileUpdateMessage,
    );
  }

  /// Unsubscribes from user-specific channels.
  void unsubscribeFromUserChannel() {
    _subscriptionManager.unsubscribeFromUserChannel();
  }

  // ============================================================
  // Message Sending
  // ============================================================

  /// Sends a text message.
  void sendMessage({
    required int roomId,
    required int senderId,
    required String content,
  }) {
    _messageSender.sendMessage(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      senderId: senderId,
      content: content,
    );
  }

  /// Sends a file message.
  void sendFileMessage({
    required int roomId,
    required int senderId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
  }) {
    _messageSender.sendFileMessage(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      senderId: senderId,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      contentType: contentType,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Adds a reaction to a message.
  void addReaction({
    required int messageId,
    required int userId,
    required String emoji,
  }) {
    _messageSender.addReaction(
      stompClient: _connectionManager.stompClient,
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );
  }

  /// Removes a reaction from a message.
  void removeReaction({
    required int messageId,
    required int userId,
    required String emoji,
  }) {
    _messageSender.removeReaction(
      stompClient: _connectionManager.stompClient,
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );
  }

  /// Sends typing status indicator.
  void sendTypingStatus({
    required int roomId,
    required int userId,
    required bool isTyping,
  }) {
    _messageSender.sendTypingStatus(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  /// Sends presence ping (TTL renewal).
  void sendPresencePing({
    required int roomId,
    required int userId,
  }) {
    _messageSender.sendPresencePing(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      userId: userId,
    );
  }

  /// Sends presence inactive (TTL release).
  void sendPresenceInactive({
    required int roomId,
    required int userId,
  }) {
    _messageSender.sendPresenceInactive(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      userId: userId,
    );
  }

  /// Sends mark as read notification.
  void sendMarkAsRead({
    required int roomId,
    required int userId,
  }) {
    _messageSender.sendMarkAsRead(
      stompClient: _connectionManager.stompClient,
      roomId: roomId,
      userId: userId,
    );
  }

  // ============================================================
  // Private: Connection Callbacks
  // ============================================================

  void _onConnected() {
    // Delay subscription restore to prevent StompBadStateException
    Future.delayed(WebSocketConfig.subscriptionDelay, () {
      final stompClient = _connectionManager.stompClient;
      if (stompClient == null || !stompClient.connected) {
        if (kDebugMode) {
          debugPrint('[WebSocket] Connection lost during delay, skipping subscription restore');
        }
        return;
      }

      _subscriptionManager.restoreSubscriptions(
        stompClient: stompClient,
        onRoomMessage: (roomId) => (frame) => _handleRoomMessage(frame, roomId),
        onChatListMessage: _handleChatListMessage,
        onReadReceiptMessage: _handleReadReceiptMessage,
        onOnlineStatusMessage: _handleOnlineStatusMessage,
        onProfileUpdateMessage: _handleProfileUpdateMessage,
      );
    });
  }

  void _onDisconnected() {
    // Subscriptions will be restored on reconnection via _onConnected
  }

  // ============================================================
  // Private: Message Handlers
  // ============================================================

  void _handleRoomMessage(StompFrame frame, int roomId) {
    if (frame.body == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Frame body is null, returning');
      }
      return;
    }

    try {
      final parsed = _payloadParser.parseRoomPayload(body: frame.body!, roomId: roomId);
      switch (parsed) {
        case ParsedChatMessagePayload(:final message):
          if (_dedupeCache.isDuplicate(message.eventId)) return;
          _messageController.add(message);
        case ParsedReadPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _readEventController.add(event);
        case ParsedReactionPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _reactionController.add(event);
        case ParsedTypingPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _typingController.add(event);
        case ParsedMessageDeletedPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          if (kDebugMode) {
            debugPrint('[WebSocket] Message deleted event: messageId=${event.messageId}, roomId=${event.chatRoomId}');
          }
          _messageDeletedController.add(event);
        case ParsedUnknownPayload(:final raw):
          if (kDebugMode) {
            debugPrint('[WebSocket] Unknown message type: ${raw['eventType']}');
          }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Error parsing message: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
    }
  }

  void _handleChatListMessage(StompFrame frame) {
    if (frame.body == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Frame body is null, returning');
      }
      return;
    }

    try {
      final update = _payloadParser.parseChatListPayload(frame.body!);
      if (_dedupeCache.isDuplicate(update.eventId)) return;
      if (kDebugMode) {
        debugPrint('[WebSocket] Chat room update received: roomId=${update.chatRoomId}, eventType=${update.eventType}');
      }
      _chatRoomUpdateController.add(update);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Error parsing chat-list message: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
    }
  }

  void _handleReadReceiptMessage(StompFrame frame) {
    if (frame.body == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Frame body is null, returning');
      }
      return;
    }

    try {
      final readEvent = _payloadParser.parseReadReceiptPayload(frame.body!);
      if (_dedupeCache.isDuplicate(readEvent.eventId)) return;
      if (kDebugMode) {
        debugPrint('[WebSocket] Read event: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
      }
      _readEventController.add(readEvent);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Error parsing read-receipt message: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
    }
  }

  void _handleOnlineStatusMessage(StompFrame frame) {
    if (frame.body == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Frame body is null, returning');
      }
      return;
    }

    try {
      final event = _payloadParser.parseOnlineStatusPayload(frame.body!);
      if (_dedupeCache.isDuplicate(event.eventId)) return;
      if (kDebugMode) {
        debugPrint('[WebSocket] Online status event: userId=${event.userId}, isOnline=${event.isOnline}');
      }
      _onlineStatusController.add(event);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Error parsing online-status message: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
    }
  }

  void _handleProfileUpdateMessage(StompFrame frame) {
    if (frame.body == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Frame body is null, returning');
      }
      return;
    }

    try {
      final event = _payloadParser.parseProfileUpdatePayload(frame.body!);
      if (_dedupeCache.isDuplicate(event.eventId)) return;
      if (kDebugMode) {
        debugPrint('[WebSocket] Profile update event: userId=${event.userId}');
      }
      _profileUpdateController.add(event);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Error parsing profile-update message: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  /// Releases all resources.
  void dispose() {
    disconnect();
    _connectionManager.dispose();
    _messageController.close();
    _reactionController.close();
    _readEventController.close();
    _chatRoomUpdateController.close();
    _typingController.close();
    _onlineStatusController.close();
    _messageDeletedController.close();
    _profileUpdateController.close();
  }
}
