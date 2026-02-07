import '../../constants/api_constants.dart';

/// WebSocket configuration settings.
///
/// Centralizes all WebSocket-related configuration including:
/// - Endpoint URLs
/// - Timeout settings
/// - Reconnection parameters
class WebSocketConfig {
  const WebSocketConfig._();

  /// WebSocket base URL derived from API base URL.
  static String get wsBaseUrl => ApiConstants.wsBaseUrl;

  /// Maximum reconnection attempts before giving up.
  static const int maxReconnectAttempts = 20;

  /// Initial delay for reconnection (exponential backoff base).
  static const Duration initialReconnectDelay = Duration(seconds: 1);

  /// Maximum delay between reconnection attempts.
  static const Duration maxReconnectDelay = Duration(seconds: 30);

  /// Timeout for a single connection attempt.
  /// If connecting state persists beyond this duration, the attempt is
  /// considered stale and a fresh connection is started.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Delay after connection before processing subscriptions.
  /// Prevents StompBadStateException.
  static const Duration subscriptionDelay = Duration(milliseconds: 100);

  /// STOMP destinations for sending messages.
  static const String sendMessageDestination = '/app/chat/message';
  static const String sendFileMessageDestination = '/app/chat/message/file';
  static const String sendReactionAddDestination = '/app/chat/reaction/add';
  static const String sendReactionRemoveDestination = '/app/chat/reaction/remove';
  static const String sendTypingDestination = '/app/chat/typing';
  static const String sendPresenceDestination = '/app/chat/presence';
  static const String sendPresenceInactiveDestination = '/app/chat/presence/inactive';
  static const String sendMarkAsReadDestination = '/app/chat/read';

  /// STOMP topic patterns for subscriptions.
  static String chatRoomTopic(int roomId) => '/topic/chat/room/$roomId';
  static String userChatListTopic(int userId) => '/topic/user/$userId/chat-list';
  static String userReadReceiptTopic(int userId) => '/topic/user/$userId/read-receipt';
  static String userOnlineStatusTopic(int userId) => '/topic/user/$userId/online-status';
  static String userProfileUpdateTopic(int userId) => '/topic/user/$userId/profile-update';

  /// Event dedupe cache settings.
  static const Duration dedupeCacheTtl = Duration(seconds: 15);
  static const int dedupeCacheMaxSize = 500;
}
