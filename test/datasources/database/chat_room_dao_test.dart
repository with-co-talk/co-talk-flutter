import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/datasources/local/database/app_database.dart';
import 'package:co_talk_flutter/data/datasources/local/database/daos/chat_room_dao.dart';

void main() {
  late AppDatabase database;
  late ChatRoomDao chatRoomDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    chatRoomDao = database.chatRoomDao;
  });

  tearDown(() async {
    await database.close();
  });

  ChatRoomsCompanion createTestRoom({
    required int id,
    String? name,
    String type = 'DIRECT',
    int? createdAt,
    String? lastMessage,
    String? lastMessageType,
    int? lastMessageAt,
    int unreadCount = 0,
    int? otherUserId,
    String? otherUserNickname,
    bool isOtherUserLeft = false,
    bool isOtherUserOnline = false,
    int? lastSyncAt,
  }) {
    return ChatRoomsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      createdAt: Value(createdAt ?? id * 1000),
      lastMessage: Value(lastMessage),
      lastMessageType: Value(lastMessageType),
      lastMessageAt: Value(lastMessageAt),
      unreadCount: Value(unreadCount),
      otherUserId: Value(otherUserId),
      otherUserNickname: Value(otherUserNickname),
      isOtherUserLeft: Value(isOtherUserLeft),
      isOtherUserOnline: Value(isOtherUserOnline),
      lastSyncAt: Value(lastSyncAt),
    );
  }

  // ---------- upsertChatRoom ----------

  group('upsertChatRoom', () {
    test('inserts a new chat room', () async {
      final room = createTestRoom(id: 1, name: 'Test Room');

      await chatRoomDao.upsertChatRoom(room);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.name, 'Test Room');
    });

    test('updates an existing chat room on conflict', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'Original'));

      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'Updated'));

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.name, 'Updated');
    });
  });

  // ---------- upsertChatRooms ----------

  group('upsertChatRooms', () {
    test('inserts multiple rooms at once', () async {
      final rooms = [
        createTestRoom(id: 1, name: 'Room 1'),
        createTestRoom(id: 2, name: 'Room 2'),
        createTestRoom(id: 3, name: 'Room 3'),
      ];

      await chatRoomDao.upsertChatRooms(rooms);

      final result = await chatRoomDao.getAllChatRooms();
      expect(result.length, 3);
    });

    test('upserts on conflict when batch-inserting', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'Old'));

      await chatRoomDao.upsertChatRooms([
        createTestRoom(id: 1, name: 'New'),
        createTestRoom(id: 2, name: 'Another'),
      ]);

      final room1 = await chatRoomDao.getChatRoomById(1);
      expect(room1!.name, 'New');
      final all = await chatRoomDao.getAllChatRooms();
      expect(all.length, 2);
    });
  });

  // ---------- getAllChatRooms ----------

  group('getAllChatRooms', () {
    test('returns empty list when no rooms exist', () async {
      final result = await chatRoomDao.getAllChatRooms();
      expect(result, isEmpty);
    });

    test('returns all inserted rooms', () async {
      await chatRoomDao.upsertChatRooms([
        createTestRoom(id: 1),
        createTestRoom(id: 2),
      ]);

      final result = await chatRoomDao.getAllChatRooms();
      expect(result.length, 2);
    });

    test('orders by lastMessageAt descending', () async {
      await chatRoomDao.upsertChatRooms([
        createTestRoom(id: 1, lastMessageAt: 1000, createdAt: 1000),
        createTestRoom(id: 2, lastMessageAt: 3000, createdAt: 2000),
        createTestRoom(id: 3, lastMessageAt: 2000, createdAt: 3000),
      ]);

      final result = await chatRoomDao.getAllChatRooms();
      expect(result[0].id, 2);
      expect(result[1].id, 3);
      expect(result[2].id, 1);
    });

    test('orders by createdAt descending when lastMessageAt is null', () async {
      await chatRoomDao.upsertChatRooms([
        createTestRoom(id: 1, createdAt: 1000),
        createTestRoom(id: 2, createdAt: 3000),
        createTestRoom(id: 3, createdAt: 2000),
      ]);

      final result = await chatRoomDao.getAllChatRooms();
      expect(result[0].id, 2);
      expect(result[1].id, 3);
      expect(result[2].id, 1);
    });
  });

  // ---------- getChatRoomById ----------

  group('getChatRoomById', () {
    test('returns the correct room', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 5, name: 'Room 5'));

      final result = await chatRoomDao.getChatRoomById(5);

      expect(result, isNotNull);
      expect(result!.id, 5);
      expect(result.name, 'Room 5');
    });

    test('returns null for non-existent id', () async {
      final result = await chatRoomDao.getChatRoomById(999);
      expect(result, isNull);
    });
  });

  // ---------- deleteChatRoomById ----------

  group('deleteChatRoomById', () {
    test('deletes the room and returns 1', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1));

      final count = await chatRoomDao.deleteChatRoomById(1);

      expect(count, 1);
      final result = await chatRoomDao.getChatRoomById(1);
      expect(result, isNull);
    });

    test('returns 0 when room does not exist', () async {
      final count = await chatRoomDao.deleteChatRoomById(999);
      expect(count, 0);
    });

    test('does not delete other rooms', () async {
      await chatRoomDao.upsertChatRooms([
        createTestRoom(id: 1),
        createTestRoom(id: 2),
      ]);

      await chatRoomDao.deleteChatRoomById(1);

      final remaining = await chatRoomDao.getAllChatRooms();
      expect(remaining.length, 1);
      expect(remaining.first.id, 2);
    });
  });

  // ---------- updateLastMessage ----------

  group('updateLastMessage', () {
    test('updates lastMessage, lastMessageType, and lastMessageAt', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1));

      await chatRoomDao.updateLastMessage(
        roomId: 1,
        lastMessage: 'Hello World',
        lastMessageType: 'TEXT',
        lastMessageAt: 99999,
      );

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.lastMessage, 'Hello World');
      expect(result.lastMessageType, 'TEXT');
      expect(result.lastMessageAt, 99999);
    });

    test('can set fields to null', () async {
      await chatRoomDao.upsertChatRoom(
        createTestRoom(id: 1, lastMessage: 'old', lastMessageType: 'TEXT', lastMessageAt: 1000),
      );

      await chatRoomDao.updateLastMessage(
        roomId: 1,
        lastMessage: null,
        lastMessageType: null,
        lastMessageAt: null,
      );

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.lastMessage, isNull);
      expect(result.lastMessageType, isNull);
      expect(result.lastMessageAt, isNull);
    });
  });

  // ---------- updateUnreadCount ----------

  group('updateUnreadCount', () {
    test('sets unread count to given value', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, unreadCount: 0));

      await chatRoomDao.updateUnreadCount(1, 7);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.unreadCount, 7);
    });

    test('can set unread count to 0', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, unreadCount: 5));
      await chatRoomDao.updateUnreadCount(1, 5);

      await chatRoomDao.updateUnreadCount(1, 0);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.unreadCount, 0);
    });
  });

  // ---------- resetUnreadCount ----------

  group('resetUnreadCount', () {
    test('sets unread count to 0', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, unreadCount: 10));
      await chatRoomDao.updateUnreadCount(1, 10);

      await chatRoomDao.resetUnreadCount(1);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.unreadCount, 0);
    });
  });

  // ---------- incrementUnreadCount ----------

  group('incrementUnreadCount', () {
    test('increments unread count by 1', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, unreadCount: 2));

      await chatRoomDao.incrementUnreadCount(1);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.unreadCount, 3);
    });

    test('does not throw when room does not exist', () async {
      await expectLater(chatRoomDao.incrementUnreadCount(999), completes);
    });

    test('increments multiple times', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, unreadCount: 0));

      await chatRoomDao.incrementUnreadCount(1);
      await chatRoomDao.incrementUnreadCount(1);
      await chatRoomDao.incrementUnreadCount(1);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.unreadCount, 3);
    });
  });

  // ---------- updateLastSyncAt ----------

  group('updateLastSyncAt', () {
    test('sets lastSyncAt timestamp', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1));

      await chatRoomDao.updateLastSyncAt(1, 123456789);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.lastSyncAt, 123456789);
    });
  });

  // ---------- updateOtherUserLeftStatus ----------

  group('updateOtherUserLeftStatus', () {
    test('sets isOtherUserLeft to true', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, isOtherUserLeft: false));

      await chatRoomDao.updateOtherUserLeftStatus(1, true);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.isOtherUserLeft, isTrue);
    });

    test('sets isOtherUserLeft to false', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, isOtherUserLeft: true));

      await chatRoomDao.updateOtherUserLeftStatus(1, false);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.isOtherUserLeft, isFalse);
    });
  });

  // ---------- updateOtherUserOnlineStatus ----------

  group('updateOtherUserOnlineStatus', () {
    test('sets isOtherUserOnline to true', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, isOtherUserOnline: false));

      await chatRoomDao.updateOtherUserOnlineStatus(1, true);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.isOtherUserOnline, isTrue);
    });

    test('sets isOtherUserOnline to false', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, isOtherUserOnline: true));

      await chatRoomDao.updateOtherUserOnlineStatus(1, false);

      final result = await chatRoomDao.getChatRoomById(1);
      expect(result!.isOtherUserOnline, isFalse);
    });
  });

  // ---------- watchAllChatRooms ----------

  group('watchAllChatRooms', () {
    test('emits empty list initially', () async {
      final stream = chatRoomDao.watchAllChatRooms();
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emits updated list after upsert', () async {
      final stream = chatRoomDao.watchAllChatRooms();
      final initial = await stream.first;
      expect(initial, isEmpty);

      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'Live Room'));

      final updated = await stream.first;
      expect(updated.length, 1);
      expect(updated.first.name, 'Live Room');
    });
  });

  // ---------- watchChatRoomById ----------

  group('watchChatRoomById', () {
    test('emits null when room does not exist', () async {
      final stream = chatRoomDao.watchChatRoomById(99);
      final first = await stream.first;
      expect(first, isNull);
    });

    test('emits room after it is inserted', () async {
      final stream = chatRoomDao.watchChatRoomById(1);
      final initial = await stream.first;
      expect(initial, isNull);

      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'Watched'));

      final updated = await stream.first;
      expect(updated, isNotNull);
      expect(updated!.name, 'Watched');
    });

    test('emits null after room is deleted', () async {
      await chatRoomDao.upsertChatRoom(createTestRoom(id: 1, name: 'To Delete'));
      final stream = chatRoomDao.watchChatRoomById(1);
      final existing = await stream.first;
      expect(existing, isNotNull);

      await chatRoomDao.deleteChatRoomById(1);

      final afterDelete = await stream.first;
      expect(afterDelete, isNull);
    });
  });
}
