// WebSocket event models for real-time chat communication.
//
// This file contains all event types that can be received via WebSocket:
// - Chat messages
// - Reactions
// - Read receipts
// - Typing indicators
// - Online status
// - Message deletions
// - Profile updates

/// WebSocket connection state.
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  /// All reconnection attempts exhausted. User action required.
  failed,
}

/// WebSocket chat message event.
class WebSocketChatMessage {
  final int? schemaVersion;
  final String? eventId;
  final int messageId;
  final int? senderId;
  final String? senderNickname;
  final String? senderAvatarUrl;
  final int chatRoomId;
  final String content;
  final String type;
  final DateTime createdAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileContentType;
  final String? thumbnailUrl;
  final int? replyToMessageId;
  final int? forwardedFromMessageId;
  final int unreadCount;
  final String? eventType;
  final int? relatedUserId;
  final String? relatedUserNickname;

  WebSocketChatMessage({
    this.schemaVersion,
    this.eventId,
    required this.messageId,
    this.senderId,
    this.senderNickname,
    this.senderAvatarUrl,
    required this.chatRoomId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileContentType,
    this.thumbnailUrl,
    this.replyToMessageId,
    this.forwardedFromMessageId,
    this.unreadCount = 0,
    this.eventType,
    this.relatedUserId,
    this.relatedUserNickname,
  });

  factory WebSocketChatMessage.fromJson(Map<String, dynamic> json, int roomId) {
    return WebSocketChatMessage(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      messageId: json['messageId'] as int,
      senderId: json['senderId'] as int?,
      senderNickname: json['senderNickname'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      chatRoomId: json['roomId'] as int? ?? roomId,
      content: json['content'] as String? ?? '',
      type: json['type'] as String,
      createdAt: _parseDateTime(json['createdAt']),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      fileContentType: (json['fileContentType'] ?? json['contentType']) as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      replyToMessageId: json['replyToMessageId'] as int?,
      forwardedFromMessageId: json['forwardedFromMessageId'] as int?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      eventType: json['eventType'] as String?,
      relatedUserId: json['relatedUserId'] as int?,
      relatedUserNickname: json['relatedUserNickname'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is List && value.length >= 6) {
      final year = value[0] as int;
      final month = value[1] as int;
      final day = value[2] as int;
      final hour = value[3] as int;
      final minute = value[4] as int;
      final second = value[5] as int;
      final nano = value.length > 6 ? value[6] as int : 0;
      final millisecond = nano ~/ 1000000;
      final microsecond = (nano ~/ 1000) % 1000;
      return DateTime.utc(year, month, day, hour, minute, second, millisecond, microsecond);
    }
    return DateTime.now();
  }
}

/// WebSocket reaction event.
class WebSocketReactionEvent {
  final int? schemaVersion;
  final String? eventId;
  final int? reactionId;
  final int messageId;
  final int userId;
  final String emoji;
  final String eventType;
  final int timestamp;

  WebSocketReactionEvent({
    this.schemaVersion,
    this.eventId,
    this.reactionId,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.eventType,
    required this.timestamp,
  });

  factory WebSocketReactionEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketReactionEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      reactionId: json['reactionId'] as int?,
      messageId: json['messageId'] as int,
      userId: json['userId'] as int,
      emoji: json['emoji'] as String,
      eventType: json['eventType'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

/// WebSocket read receipt event.
class WebSocketReadEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int userId;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;

  WebSocketReadEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.userId,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  factory WebSocketReadEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketReadEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      userId: json['userId'] as int? ?? json['readerId'] as int,
      lastReadMessageId: json['lastReadMessageId'] as int?,
      lastReadAt: json['lastReadAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['lastReadAt'])
          : null,
    );
  }
}

/// WebSocket chat room update event (for chat list).
class WebSocketChatRoomUpdateEvent {
  final int? schemaVersion;
  final String? eventId;
  final String? eventType;
  final int chatRoomId;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int? unreadCount;
  final int? senderId;
  final String? senderNickname;

  WebSocketChatRoomUpdateEvent({
    this.schemaVersion,
    this.eventId,
    this.eventType,
    required this.chatRoomId,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount,
    this.senderId,
    this.senderNickname,
  });

  factory WebSocketChatRoomUpdateEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketChatRoomUpdateEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      eventType: json['eventType'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      lastMessage: json['lastMessage'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] as int?,
      senderId: json['senderId'] as int?,
      senderNickname: json['senderNickname'] as String?,
    );
  }
}

/// WebSocket typing indicator event.
class WebSocketTypingEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int userId;
  final String? userNickname;
  final bool isTyping;

  WebSocketTypingEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.userId,
    this.userNickname,
    required this.isTyping,
  });

  factory WebSocketTypingEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketTypingEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      userId: json['userId'] as int,
      userNickname: json['userNickname'] as String?,
      isTyping: json['isTyping'] as bool? ?? json['eventType'] == 'TYPING',
    );
  }
}

/// WebSocket online status event.
class WebSocketOnlineStatusEvent {
  final int? schemaVersion;
  final String? eventId;
  final int userId;
  final bool isOnline;
  final DateTime? lastActiveAt;

  WebSocketOnlineStatusEvent({
    this.schemaVersion,
    this.eventId,
    required this.userId,
    required this.isOnline,
    this.lastActiveAt,
  });

  factory WebSocketOnlineStatusEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketOnlineStatusEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      userId: json['userId'] as int,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['lastActiveAt'])
          : null,
    );
  }
}

/// WebSocket message updated event.
class WebSocketMessageUpdatedEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int messageId;
  final int updatedBy;
  final String newContent;
  final DateTime updatedAt;

  WebSocketMessageUpdatedEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.messageId,
    required this.updatedBy,
    required this.newContent,
    required this.updatedAt,
  });

  factory WebSocketMessageUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketMessageUpdatedEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: (json['chatRoomId'] as num).toInt(),
      messageId: (json['messageId'] as num).toInt(),
      updatedBy: (json['updatedBy'] as num).toInt(),
      newContent: json['newContent'] as String? ?? '',
      updatedAt: json['updatedAtMillis'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['updatedAtMillis'] as num).toInt())
          : DateTime.now(),
    );
  }
}

/// WebSocket message deleted event.
class WebSocketMessageDeletedEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int messageId;
  final int deletedBy;
  final DateTime deletedAt;

  WebSocketMessageDeletedEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.messageId,
    required this.deletedBy,
    required this.deletedAt,
  });

  factory WebSocketMessageDeletedEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketMessageDeletedEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: (json['chatRoomId'] as num).toInt(),
      messageId: (json['messageId'] as num).toInt(),
      deletedBy: (json['deletedBy'] as num).toInt(),
      deletedAt: json['deletedAtMillis'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['deletedAtMillis'] as num).toInt())
          : DateTime.now(),
    );
  }
}

/// WebSocket error event from backend @SendToUser("/queue/errors").
class WebSocketErrorEvent {
  final String code;
  final String message;
  final DateTime timestamp;

  WebSocketErrorEvent({
    required this.code,
    required this.message,
    required this.timestamp,
  });

  factory WebSocketErrorEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketErrorEvent(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }
}

/// WebSocket profile update event.
class WebSocketProfileUpdateEvent {
  final int? schemaVersion;
  final String? eventId;
  final int userId;
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? statusMessage;
  final DateTime? updatedAt;

  WebSocketProfileUpdateEvent({
    this.schemaVersion,
    this.eventId,
    required this.userId,
    this.avatarUrl,
    this.backgroundUrl,
    this.statusMessage,
    this.updatedAt,
  });

  factory WebSocketProfileUpdateEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketProfileUpdateEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      userId: json['userId'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      backgroundUrl: json['backgroundUrl'] as String?,
      statusMessage: json['statusMessage'] as String?,
      updatedAt: json['updatedAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['updatedAt'])
          : null,
    );
  }
}
