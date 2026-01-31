import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'chat_room_dao.g.dart';

@DriftAccessor(tables: [ChatRooms])
class ChatRoomDao extends DatabaseAccessor<AppDatabase> with _$ChatRoomDaoMixin {
  ChatRoomDao(super.db);

  /// Insert or update a single chat room
  Future<void> upsertChatRoom(ChatRoomsCompanion chatRoom) async {
    await into(chatRooms).insertOnConflictUpdate(chatRoom);
  }

  /// Insert or update multiple chat rooms
  Future<void> upsertChatRooms(List<ChatRoomsCompanion> chatRoomList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(chatRooms, chatRoomList);
    });
  }

  /// Get all chat rooms, ordered by lastMessageAt descending
  Future<List<ChatRoom>> getAllChatRooms() async {
    final query = select(chatRooms)
      ..orderBy([
        (r) => OrderingTerm.desc(r.lastMessageAt),
        (r) => OrderingTerm.desc(r.createdAt),
      ]);
    return query.get();
  }

  /// Get a single chat room by ID
  Future<ChatRoom?> getChatRoomById(int roomId) async {
    final query = select(chatRooms)..where((r) => r.id.equals(roomId));
    return query.getSingleOrNull();
  }

  /// Delete a chat room by ID (also deletes associated messages via cascade)
  Future<int> deleteChatRoomById(int roomId) async {
    return (delete(chatRooms)..where((r) => r.id.equals(roomId))).go();
  }

  /// Update the last message info for a chat room
  Future<void> updateLastMessage({
    required int roomId,
    required String? lastMessage,
    required String? lastMessageType,
    required int? lastMessageAt,
  }) async {
    await (update(chatRooms)..where((r) => r.id.equals(roomId))).write(
      ChatRoomsCompanion(
        lastMessage: Value(lastMessage),
        lastMessageType: Value(lastMessageType),
        lastMessageAt: Value(lastMessageAt),
      ),
    );
  }

  /// Update unread count for a chat room
  Future<void> updateUnreadCount(int roomId, int count) async {
    await (update(chatRooms)..where((r) => r.id.equals(roomId)))
        .write(ChatRoomsCompanion(unreadCount: Value(count)));
  }

  /// Reset unread count to 0 for a chat room
  Future<void> resetUnreadCount(int roomId) async {
    await updateUnreadCount(roomId, 0);
  }

  /// Increment unread count for a chat room
  Future<void> incrementUnreadCount(int roomId) async {
    final room = await getChatRoomById(roomId);
    if (room != null) {
      await updateUnreadCount(roomId, room.unreadCount + 1);
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncAt(int roomId, int timestamp) async {
    await (update(chatRooms)..where((r) => r.id.equals(roomId)))
        .write(ChatRoomsCompanion(lastSyncAt: Value(timestamp)));
  }

  /// Update other user left status
  Future<void> updateOtherUserLeftStatus(int roomId, bool isLeft) async {
    await (update(chatRooms)..where((r) => r.id.equals(roomId)))
        .write(ChatRoomsCompanion(isOtherUserLeft: Value(isLeft)));
  }

  /// Update other user online status
  Future<void> updateOtherUserOnlineStatus(int roomId, bool isOnline) async {
    await (update(chatRooms)..where((r) => r.id.equals(roomId)))
        .write(ChatRoomsCompanion(isOtherUserOnline: Value(isOnline)));
  }

  /// Watch all chat rooms (for real-time updates)
  Stream<List<ChatRoom>> watchAllChatRooms() {
    final query = select(chatRooms)
      ..orderBy([
        (r) => OrderingTerm.desc(r.lastMessageAt),
        (r) => OrderingTerm.desc(r.createdAt),
      ]);
    return query.watch();
  }

  /// Watch a single chat room
  Stream<ChatRoom?> watchChatRoomById(int roomId) {
    final query = select(chatRooms)..where((r) => r.id.equals(roomId));
    return query.watchSingleOrNull();
  }
}
