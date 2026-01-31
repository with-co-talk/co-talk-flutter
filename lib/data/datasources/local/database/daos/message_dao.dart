import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages, MessageReactions])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  /// Insert or update a single message
  Future<void> upsertMessage(MessagesCompanion message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Insert or update multiple messages
  Future<void> upsertMessages(List<MessagesCompanion> messageList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(messages, messageList);
    });
  }

  /// Get all messages for a chat room, ordered by createdAt descending
  Future<List<Message>> getMessagesByChatRoom(
    int chatRoomId, {
    int? limit,
    int? beforeMessageId,
  }) async {
    final query = select(messages)
      ..where((m) => m.chatRoomId.equals(chatRoomId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    if (beforeMessageId != null) {
      query.where((m) => m.id.isSmallerThanValue(beforeMessageId));
    }

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Get a single message by ID
  Future<Message?> getMessageById(int messageId) async {
    final query = select(messages)..where((m) => m.id.equals(messageId));
    return query.getSingleOrNull();
  }

  /// Delete a message by ID
  Future<int> deleteMessageById(int messageId) async {
    return (delete(messages)..where((m) => m.id.equals(messageId))).go();
  }

  /// Delete all messages for a chat room
  Future<int> deleteMessagesByChatRoom(int chatRoomId) async {
    return (delete(messages)..where((m) => m.chatRoomId.equals(chatRoomId)))
        .go();
  }

  /// Mark a message as deleted (soft delete)
  Future<void> markMessageAsDeleted(int messageId) async {
    await (update(messages)..where((m) => m.id.equals(messageId)))
        .write(const MessagesCompanion(isDeleted: Value(true)));
  }

  /// Search messages using FTS5 full-text search
  /// Returns messages matching the query, optionally filtered by chatRoomId
  Future<List<Message>> searchMessages(
    String query, {
    int? chatRoomId,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    // Escape double quotes for FTS5 query
    final escaped = query.replaceAll('"', '""');

    // Build the SQL query with FTS5
    String sql = '''
      SELECT m.* FROM messages m
      INNER JOIN messages_fts ON m.id = messages_fts.rowid
      WHERE messages_fts MATCH ?
    ''';

    final variables = <Variable>[Variable.withString('"$escaped"*')];

    if (chatRoomId != null) {
      sql += ' AND m.chat_room_id = ?';
      variables.add(Variable.withInt(chatRoomId));
    }

    sql += ' ORDER BY m.created_at DESC LIMIT ?';
    variables.add(Variable.withInt(limit));

    final results = await customSelect(
      sql,
      variables: variables,
      readsFrom: {messages},
    ).get();

    return results.map((row) => Message(
      id: row.read<int>('id'),
      chatRoomId: row.read<int>('chat_room_id'),
      senderId: row.read<int>('sender_id'),
      senderNickname: row.readNullable<String>('sender_nickname'),
      senderAvatarUrl: row.readNullable<String>('sender_avatar_url'),
      content: row.read<String>('content'),
      type: row.read<String>('type'),
      fileUrl: row.readNullable<String>('file_url'),
      fileName: row.readNullable<String>('file_name'),
      fileSize: row.readNullable<int>('file_size'),
      fileContentType: row.readNullable<String>('file_content_type'),
      thumbnailUrl: row.readNullable<String>('thumbnail_url'),
      replyToMessageId: row.readNullable<int>('reply_to_message_id'),
      forwardedFromMessageId: row.readNullable<int>('forwarded_from_message_id'),
      isDeleted: row.read<bool>('is_deleted'),
      createdAt: row.read<int>('created_at'),
      updatedAt: row.readNullable<int>('updated_at'),
      unreadCount: row.read<int>('unread_count'),
      syncStatus: row.read<String>('sync_status'),
    )).toList();
  }

  /// Get the latest message ID for a chat room
  Future<int?> getLatestMessageId(int chatRoomId) async {
    final query = select(messages)
      ..where((m) => m.chatRoomId.equals(chatRoomId))
      ..orderBy([(m) => OrderingTerm.desc(m.id)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.id;
  }

  /// Update sync status for a message
  Future<void> updateSyncStatus(int messageId, String status) async {
    await (update(messages)..where((m) => m.id.equals(messageId)))
        .write(MessagesCompanion(syncStatus: Value(status)));
  }

  /// Get messages with pending sync status
  Future<List<Message>> getPendingMessages() async {
    final query = select(messages)
      ..where((m) => m.syncStatus.equals('pending'));
    return query.get();
  }

  /// Insert or update reactions for a message
  Future<void> upsertReactions(List<MessageReactionsCompanion> reactions) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(messageReactions, reactions);
    });
  }

  /// Get reactions for a message
  Future<List<MessageReaction>> getReactionsByMessageId(int messageId) async {
    final query = select(messageReactions)
      ..where((r) => r.messageId.equals(messageId));
    return query.get();
  }

  /// Delete all reactions for a message
  Future<int> deleteReactionsByMessageId(int messageId) async {
    return (delete(messageReactions)
          ..where((r) => r.messageId.equals(messageId)))
        .go();
  }

  /// Watch messages for a chat room (for real-time updates)
  Stream<List<Message>> watchMessagesByChatRoom(int chatRoomId) {
    final query = select(messages)
      ..where((m) => m.chatRoomId.equals(chatRoomId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    return query.watch();
  }
}
