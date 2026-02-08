import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'websocket_config.dart';

/// Callback type for STOMP frame handling.
typedef StompFrameCallback = void Function(StompFrame frame);

/// Manages WebSocket topic subscriptions.
///
/// Responsibilities:
/// - Chat room subscriptions (per-room)
/// - User channel subscriptions (global: chat-list, read-receipt, online-status, profile-update)
/// - Pending subscription queue for pre-connection requests
/// - Subscription cleanup
class WebSocketSubscriptionManager {
  /// Active chat room subscriptions (roomId -> unsubscribe function).
  final Map<int, StompUnsubscribe> _roomSubscriptions = {};

  /// Pending room subscriptions (requested before connection).
  final Set<int> _pendingRoomSubscriptions = {};

  /// User channel subscriptions.
  StompUnsubscribe? _chatListSubscription;
  StompUnsubscribe? _readReceiptSubscription;
  StompUnsubscribe? _onlineStatusSubscription;
  StompUnsubscribe? _profileUpdateSubscription;
  StompUnsubscribe? _errorSubscription;
  /// Currently subscribed user ID (if any).
  ///
  /// Used to remember user ID for automatic reconnection when setting,
  /// and to check current subscription state when getting.
  int? subscribedUserId;

  /// Gets the list of currently subscribed room IDs.
  List<int> get subscribedRoomIds => _roomSubscriptions.keys.toList();

  /// Gets the list of pending room subscriptions.
  List<int> get pendingRoomIds => _pendingRoomSubscriptions.toList();

  /// Subscribes to a chat room.
  ///
  /// If [stompClient] is null or not connected, adds to pending queue.
  void subscribeToChatRoom({
    required int roomId,
    required StompClient? stompClient,
    required StompFrameCallback onMessage,
  }) {
    if (kDebugMode) {
      debugPrint('[WebSocket] subscribeToChatRoom($roomId) - connected: ${stompClient?.connected}');
    }

    if (_roomSubscriptions.containsKey(roomId)) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Already subscribed to room $roomId');
      }
      return;
    }

    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Not connected - adding room $roomId to pending');
      }
      _pendingRoomSubscriptions.add(roomId);
      return;
    }

    _doSubscribeToRoom(
      roomId: roomId,
      stompClient: stompClient,
      onMessage: onMessage,
    );
  }

  void _doSubscribeToRoom({
    required int roomId,
    required StompClient stompClient,
    required StompFrameCallback onMessage,
  }) {
    final destination = WebSocketConfig.chatRoomTopic(roomId);
    if (kDebugMode) {
      debugPrint('[WebSocket] Subscribing to $destination');
    }

    try {
      final unsubscribe = stompClient.subscribe(
        destination: destination,
        callback: onMessage,
      );

      _roomSubscriptions[roomId] = unsubscribe;
      _pendingRoomSubscriptions.remove(roomId);

      if (kDebugMode) {
        debugPrint('[WebSocket] Subscribed to room $roomId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Failed to subscribe to room $roomId: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
      _pendingRoomSubscriptions.add(roomId);
      _roomSubscriptions.remove(roomId);
    }
  }

  /// Unsubscribes from a chat room.
  void unsubscribeFromChatRoom(int roomId) {
    if (kDebugMode) {
      debugPrint('[WebSocket] Unsubscribing from room $roomId');
    }
    _pendingRoomSubscriptions.remove(roomId);
    final unsubscribe = _roomSubscriptions.remove(roomId);
    unsubscribe?.call();
  }

  /// Subscribes to user channels (chat-list, read-receipt, online-status, profile-update).
  ///
  /// If [stompClient] is null or not connected, stores userId for later subscription.
  void subscribeToUserChannel({
    required int userId,
    required StompClient? stompClient,
    required StompFrameCallback onChatListMessage,
    required StompFrameCallback onReadReceiptMessage,
    required StompFrameCallback onOnlineStatusMessage,
    required StompFrameCallback onProfileUpdateMessage,
    StompFrameCallback? onErrorMessage,
  }) {
    if (kDebugMode) {
      debugPrint('[WebSocket] subscribeToUserChannel($userId) - connected: ${stompClient?.connected}');
    }

    if (subscribedUserId == userId && _chatListSubscription != null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Already subscribed to user channel $userId');
      }
      return;
    }

    // Unsubscribe from existing channels
    _unsubscribeUserChannels();

    if (stompClient == null || !stompClient.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Not connected - will subscribe to user channel $userId on connect');
      }
      subscribedUserId = userId;
      return;
    }

    _doSubscribeToUserChannel(
      userId: userId,
      stompClient: stompClient,
      onChatListMessage: onChatListMessage,
      onReadReceiptMessage: onReadReceiptMessage,
      onOnlineStatusMessage: onOnlineStatusMessage,
      onProfileUpdateMessage: onProfileUpdateMessage,
      onErrorMessage: onErrorMessage,
    );
  }

  void _doSubscribeToUserChannel({
    required int userId,
    required StompClient stompClient,
    required StompFrameCallback onChatListMessage,
    required StompFrameCallback onReadReceiptMessage,
    required StompFrameCallback onOnlineStatusMessage,
    required StompFrameCallback onProfileUpdateMessage,
    StompFrameCallback? onErrorMessage,
  }) {
    try {
      // Chat list updates
      _chatListSubscription = stompClient.subscribe(
        destination: WebSocketConfig.userChatListTopic(userId),
        callback: onChatListMessage,
      );

      // Read receipts
      _readReceiptSubscription = stompClient.subscribe(
        destination: WebSocketConfig.userReadReceiptTopic(userId),
        callback: onReadReceiptMessage,
      );

      // Online status
      _onlineStatusSubscription = stompClient.subscribe(
        destination: WebSocketConfig.userOnlineStatusTopic(userId),
        callback: onOnlineStatusMessage,
      );

      // Profile updates
      _profileUpdateSubscription = stompClient.subscribe(
        destination: WebSocketConfig.userProfileUpdateTopic(userId),
        callback: onProfileUpdateMessage,
      );

      // Error queue (server-side application errors)
      if (onErrorMessage != null) {
        _errorSubscription = stompClient.subscribe(
          destination: WebSocketConfig.userErrorQueue,
          callback: onErrorMessage,
        );
      }

      subscribedUserId = userId;

      if (kDebugMode) {
        debugPrint('[WebSocket] User channel subscribed for userId: $userId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Failed to subscribe to user channel: $e');
        debugPrint('[WebSocket] Stack trace: $stackTrace');
      }
      _unsubscribeUserChannels();
    }
  }

  /// Unsubscribes from user channels.
  void unsubscribeFromUserChannel() {
    if (kDebugMode) {
      debugPrint('[WebSocket] Unsubscribing from user channel');
    }
    _unsubscribeUserChannels();
    subscribedUserId = null;
  }

  void _unsubscribeUserChannels() {
    _chatListSubscription?.call();
    _chatListSubscription = null;
    _readReceiptSubscription?.call();
    _readReceiptSubscription = null;
    _onlineStatusSubscription?.call();
    _onlineStatusSubscription = null;
    _profileUpdateSubscription?.call();
    _profileUpdateSubscription = null;
    _errorSubscription?.call();
    _errorSubscription = null;
  }

  /// Called when the STOMP connection is lost (auto-disconnect).
  ///
  /// Moves active room subscriptions to the pending queue so they
  /// can be restored on reconnection. Clears stale subscription refs.
  void onDisconnected() {
    if (kDebugMode) {
      debugPrint('[WebSocket] onDisconnected: moving ${_roomSubscriptions.length} rooms to pending');
    }
    _pendingRoomSubscriptions.addAll(_roomSubscriptions.keys);
    _roomSubscriptions.clear();
    _chatListSubscription = null;
    _readReceiptSubscription = null;
    _onlineStatusSubscription = null;
    _profileUpdateSubscription = null;
    _errorSubscription = null;
  }

  /// Restores all subscriptions after reconnection.
  ///
  /// Only processes pending room subscriptions (not active ones),
  /// preventing duplicate STOMP subscriptions when the BLoC subscribes
  /// independently after a foreground transition.
  void restoreSubscriptions({
    required StompClient stompClient,
    required StompFrameCallback Function(int roomId) onRoomMessage,
    required StompFrameCallback onChatListMessage,
    required StompFrameCallback onReadReceiptMessage,
    required StompFrameCallback onOnlineStatusMessage,
    required StompFrameCallback onProfileUpdateMessage,
    StompFrameCallback? onErrorMessage,
  }) {
    // Only process pending subscriptions (rooms queued by onDisconnected or pre-connection requests).
    // Do NOT touch _roomSubscriptions — the BLoC may have already subscribed fresh rooms.
    final pendingRoomIds = _pendingRoomSubscriptions.toList();
    if (kDebugMode && pendingRoomIds.isNotEmpty) {
      debugPrint('[WebSocket] Restoring ${pendingRoomIds.length} pending room subscriptions');
    }

    for (final roomId in pendingRoomIds) {
      if (!_roomSubscriptions.containsKey(roomId)) {
        _doSubscribeToRoom(
          roomId: roomId,
          stompClient: stompClient,
          onMessage: onRoomMessage(roomId),
        );
      } else {
        _pendingRoomSubscriptions.remove(roomId);
      }
    }

    // Restore user channel subscription
    if (subscribedUserId != null) {
      _doSubscribeToUserChannel(
        userId: subscribedUserId!,
        stompClient: stompClient,
        onChatListMessage: onChatListMessage,
        onReadReceiptMessage: onReadReceiptMessage,
        onOnlineStatusMessage: onOnlineStatusMessage,
        onProfileUpdateMessage: onProfileUpdateMessage,
        onErrorMessage: onErrorMessage,
      );
    }
  }

  /// Clears all subscriptions without calling unsubscribe functions.
  ///
  /// Use this when the connection is already closed.
  void clearAll() {
    _roomSubscriptions.clear();
    _pendingRoomSubscriptions.clear();
    _chatListSubscription = null;
    _readReceiptSubscription = null;
    _onlineStatusSubscription = null;
    _profileUpdateSubscription = null;
    _errorSubscription = null;
  }

  /// Disposes all subscriptions properly.
  void dispose() {
    for (final unsubscribe in _roomSubscriptions.values) {
      unsubscribe();
    }
    _roomSubscriptions.clear();
    _pendingRoomSubscriptions.clear();
    _unsubscribeUserChannels();
    subscribedUserId = null;
  }
}
