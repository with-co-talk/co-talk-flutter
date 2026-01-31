import 'package:injectable/injectable.dart';

import '../../../domain/entities/chat_room.dart' as domain;
import '../../../domain/entities/message.dart' as domain;
import 'database/app_database.dart';
import 'database/converters/entity_converters.dart';

/// Interface for local chat data operations
abstract class ChatLocalDataSource {
  /// Save messages to local database
  Future<void> saveMessages(List<domain.Message> messages);

  /// Save a single message to local database
  Future<void> saveMessage(domain.Message message, {String syncStatus = 'synced'});

  /// Get messages for a chat room from local database
  Future<List<domain.Message>> getMessages(
    int chatRoomId, {
    int? limit,
    int? beforeMessageId,
  });

  /// Search messages using full-text search
  Future<List<domain.Message>> searchMessages(
    String query, {
    int? chatRoomId,
    int limit = 50,
  });

  /// Get the latest message ID for a chat room
  Future<int?> getLatestMessageId(int chatRoomId);

  /// Delete a message locally
  Future<void> deleteMessage(int messageId);

  /// Mark a message as deleted (soft delete)
  Future<void> markMessageAsDeleted(int messageId);

  /// Save chat rooms to local database
  Future<void> saveChatRooms(List<domain.ChatRoom> chatRooms);

  /// Save a single chat room to local database
  Future<void> saveChatRoom(domain.ChatRoom chatRoom);

  /// Get all chat rooms from local database
  Future<List<domain.ChatRoom>> getChatRooms();

  /// Get a single chat room from local database
  Future<domain.ChatRoom?> getChatRoom(int roomId);

  /// Update last message info for a chat room
  Future<void> updateLastMessage({
    required int roomId,
    required String? lastMessage,
    required String? lastMessageType,
    required DateTime? lastMessageAt,
  });

  /// Update unread count for a chat room
  Future<void> updateUnreadCount(int roomId, int count);

  /// Reset unread count to 0 for a chat room
  Future<void> resetUnreadCount(int roomId);

  /// Update other user left status
  Future<void> updateOtherUserLeftStatus(int roomId, bool isLeft);

  /// Delete a chat room and its messages
  Future<void> deleteChatRoom(int roomId);

  /// Clear all local data (for logout)
  Future<void> clearAllData();

  /// Watch messages for a chat room (real-time updates)
  Stream<List<domain.Message>> watchMessages(int chatRoomId);

  /// Watch all chat rooms (real-time updates)
  Stream<List<domain.ChatRoom>> watchChatRooms();
}

@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final AppDatabase _database;

  ChatLocalDataSourceImpl(this._database);

  @override
  Future<void> saveMessages(List<domain.Message> messages) async {
    final companions = messages.map((m) => messageToCompanion(m)).toList();
    await _database.messageDao.upsertMessages(companions);

    // Save reactions for each message
    for (final message in messages) {
      if (message.reactions.isNotEmpty) {
        final reactionCompanions =
            message.reactions.map((r) => reactionToCompanion(r)).toList();
        await _database.messageDao.upsertReactions(reactionCompanions);
      }
    }
  }

  @override
  Future<void> saveMessage(domain.Message message, {String syncStatus = 'synced'}) async {
    final companion = messageToCompanion(message, syncStatus: syncStatus);
    await _database.messageDao.upsertMessage(companion);

    if (message.reactions.isNotEmpty) {
      final reactionCompanions =
          message.reactions.map((r) => reactionToCompanion(r)).toList();
      await _database.messageDao.upsertReactions(reactionCompanions);
    }
  }

  @override
  Future<List<domain.Message>> getMessages(
    int chatRoomId, {
    int? limit,
    int? beforeMessageId,
  }) async {
    final rows = await _database.messageDao.getMessagesByChatRoom(
      chatRoomId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );

    final messages = <domain.Message>[];
    for (final row in rows) {
      final reactions = await _database.messageDao.getReactionsByMessageId(row.id);
      final reactionEntities = reactions.map((r) => dbReactionToEntity(r)).toList();
      messages.add(dbMessageToEntity(row, reactionEntities));
    }

    return messages;
  }

  @override
  Future<List<domain.Message>> searchMessages(
    String query, {
    int? chatRoomId,
    int limit = 50,
  }) async {
    final rows = await _database.messageDao.searchMessages(
      query,
      chatRoomId: chatRoomId,
      limit: limit,
    );

    final messages = <domain.Message>[];
    for (final row in rows) {
      final reactions = await _database.messageDao.getReactionsByMessageId(row.id);
      final reactionEntities = reactions.map((r) => dbReactionToEntity(r)).toList();
      messages.add(dbMessageToEntity(row, reactionEntities));
    }

    return messages;
  }

  @override
  Future<int?> getLatestMessageId(int chatRoomId) async {
    return _database.messageDao.getLatestMessageId(chatRoomId);
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await _database.messageDao.deleteMessageById(messageId);
  }

  @override
  Future<void> markMessageAsDeleted(int messageId) async {
    await _database.messageDao.markMessageAsDeleted(messageId);
  }

  @override
  Future<void> saveChatRooms(List<domain.ChatRoom> chatRooms) async {
    final companions = chatRooms.map((r) => chatRoomToCompanion(r)).toList();
    await _database.chatRoomDao.upsertChatRooms(companions);
  }

  @override
  Future<void> saveChatRoom(domain.ChatRoom chatRoom) async {
    final companion = chatRoomToCompanion(chatRoom);
    await _database.chatRoomDao.upsertChatRoom(companion);
  }

  @override
  Future<List<domain.ChatRoom>> getChatRooms() async {
    final rows = await _database.chatRoomDao.getAllChatRooms();
    return rows.map((r) => dbChatRoomToEntity(r)).toList();
  }

  @override
  Future<domain.ChatRoom?> getChatRoom(int roomId) async {
    final row = await _database.chatRoomDao.getChatRoomById(roomId);
    if (row == null) return null;
    return dbChatRoomToEntity(row);
  }

  @override
  Future<void> updateLastMessage({
    required int roomId,
    required String? lastMessage,
    required String? lastMessageType,
    required DateTime? lastMessageAt,
  }) async {
    await _database.chatRoomDao.updateLastMessage(
      roomId: roomId,
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageAt: lastMessageAt?.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> updateUnreadCount(int roomId, int count) async {
    await _database.chatRoomDao.updateUnreadCount(roomId, count);
  }

  @override
  Future<void> resetUnreadCount(int roomId) async {
    await _database.chatRoomDao.resetUnreadCount(roomId);
  }

  @override
  Future<void> updateOtherUserLeftStatus(int roomId, bool isLeft) async {
    await _database.chatRoomDao.updateOtherUserLeftStatus(roomId, isLeft);
  }

  @override
  Future<void> deleteChatRoom(int roomId) async {
    // Messages will be deleted automatically due to cascade
    await _database.chatRoomDao.deleteChatRoomById(roomId);
  }

  @override
  Future<void> clearAllData() async {
    await _database.clearAllData();
  }

  @override
  Stream<List<domain.Message>> watchMessages(int chatRoomId) {
    return _database.messageDao.watchMessagesByChatRoom(chatRoomId).asyncMap(
      (rows) async {
        final messages = <domain.Message>[];
        for (final row in rows) {
          final reactions =
              await _database.messageDao.getReactionsByMessageId(row.id);
          final reactionEntities =
              reactions.map((r) => dbReactionToEntity(r)).toList();
          messages.add(dbMessageToEntity(row, reactionEntities));
        }
        return messages;
      },
    );
  }

  @override
  Stream<List<domain.ChatRoom>> watchChatRooms() {
    return _database.chatRoomDao
        .watchAllChatRooms()
        .map((rows) => rows.map((r) => dbChatRoomToEntity(r)).toList());
  }
}
