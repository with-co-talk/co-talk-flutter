import 'package:injectable/injectable.dart';

/// Tracks the currently active (open) chat room.
///
/// Used by FCM service and notification click handler to:
/// - Suppress notifications for the room the user is currently viewing
/// - Handle same-room push notification taps with refresh instead of navigation
@lazySingleton
class ActiveRoomTracker {
  /// The ID of the currently active chat room, or null if no room is open.
  ///
  /// Set to the room ID when entering a chat room,
  /// and to null when leaving.
  int? activeRoomId;
}
