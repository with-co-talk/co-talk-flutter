import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/network/websocket_service.dart';

/// Manages user presence in a chat room.
///
/// Handles:
/// - Presence ping/pong heartbeat
/// - Online/offline status tracking
/// - Typing indicator management
/// - View state tracking
class PresenceManager {
  final WebSocketService _webSocketService;

  Timer? _presencePingTimer;
  Timer? _typingDebounceTimer;

  bool _isViewingRoom = false;

  PresenceManager(this._webSocketService);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PresenceManager] $message');
    }
  }

  /// Starts sending presence pings to indicate the user is actively viewing the room.
  void startPresencePing(int roomId, int userId) {
    stopPresencePing();

    _webSocketService.sendPresencePing(roomId: roomId);
    _presencePingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _webSocketService.sendPresencePing(
        roomId: roomId,
      );
    });

    _log('Started presence ping for room $roomId');
  }

  /// Stops sending presence pings.
  void stopPresencePing() {
    _presencePingTimer?.cancel();
    _presencePingTimer = null;
    _log('Stopped presence ping');
  }

  /// Sends presence active status.
  void sendPresenceActive(int roomId, int userId) {
    _isViewingRoom = true;
    startPresencePing(roomId, userId);
  }

  /// Sends presence inactive status.
  void sendPresenceInactive(int roomId, int userId) {
    _isViewingRoom = false;
    stopPresencePing();
    _webSocketService.sendPresenceInactive(roomId: roomId);
    _log('Sent presence inactive for room $roomId');
  }

  /// Sends typing status to the server.
  void sendTypingStatus({
    required int roomId,
    required int userId,
    required bool isTyping,
  }) {
    _webSocketService.sendTypingStatus(
      roomId: roomId,
      isTyping: isTyping,
    );
    _log('Sent typing status: isTyping=$isTyping');
  }

  /// Handles user started typing event with debounce.
  void handleUserStartedTyping({
    required int roomId,
    required int userId,
    required VoidCallback onStopTyping,
  }) {
    sendTypingStatus(roomId: roomId, userId: userId, isTyping: true);

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      onStopTyping();
    });
  }

  /// Handles user stopped typing event.
  void handleUserStoppedTyping({
    required int roomId,
    required int userId,
  }) {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    sendTypingStatus(roomId: roomId, userId: userId, isTyping: false);
  }

  bool get isViewingRoom => _isViewingRoom;

  void dispose() {
    _presencePingTimer?.cancel();
    _typingDebounceTimer?.cancel();
  }
}
