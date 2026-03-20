import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/datasources/local/database/app_database.dart';
import 'package:co_talk_flutter/data/datasources/local/chat_local_datasource.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart' as domain;
import 'package:co_talk_flutter/domain/entities/message.dart' as domain;

void main() {
  late AppDatabase database;
  late ChatLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = ChatLocalDataSourceImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  // ---------- helpers ----------

  domain.Message makeMessage({
    required int id,
    required int chatRoomId,
    int senderId = 1,
    String content = 'Hello',
    domain.MessageType type = domain.MessageType.text,
    bool isDeleted = false,
    DateTime? createdAt,
    List<domain.MessageReaction> reactions = const [],
  }) {
    return domain.Message(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content,
      type: type,
      isDeleted: isDeleted,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(id * 1000),
      reactions: reactions,
    );
  }

  domain.ChatRoom makeChatRoom({
    required int id,
    String? name,
    domain.ChatRoomType type = domain.ChatRoomType.direct,
    DateTime? createdAt,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int unreadCount = 0,
    int? otherUserId,
    String? otherUserNickname,
    bool isOtherUserLeft = false,
    bool isOtherUserOnline = false,
  }) {
    return domain.ChatRoom(
      id: id,
      name: name,
      type: type,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(id * 1000),
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      otherUserId: otherUserId,
      otherUserNickname: otherUserNickname,
      isOtherUserLeft: isOtherUserLeft,
      isOtherUserOnline: isOtherUserOnline,
    );
  }

  // We need to insert a chat room before inserting messages (foreign key constraint).
  Future<void> insertRoomForMessages(int chatRoomId) async {
    await database.chatRoomDao.upsertChatRoom(
      ChatRoomsCompanion(
        id: Value(chatRoomId),
        type: const Value('DIRECT'),
        createdAt: Value(chatRoomId * 1000),
      ),
    );
  }

  // ---------- saveMessages ----------

  group('saveMessages', () {
    test('saves a list of messages to the database', () async {
      await insertRoomForMessages(1);
      final messages = [
        makeMessage(id: 1, chatRoomId: 1, content: 'msg 1'),
        makeMessage(id: 2, chatRoomId: 1, content: 'msg 2'),
      ];

      await dataSource.saveMessages(messages);

      final result = await dataSource.getMessages(1);
      expect(result.length, 2);
    });

    test('saves messages with reactions', () async {
      await insertRoomForMessages(1);
      final reaction = const domain.MessageReaction(
        id: 1,
        messageId: 1,
        userId: 10,
        emoji: '👍',
      );
      final message = makeMessage(id: 1, chatRoomId: 1, reactions: [reaction]);

      await dataSource.saveMessages([message]);

      final result = await dataSource.getMessages(1);
      expect(result.length, 1);
      expect(result.first.reactions.length, 1);
      expect(result.first.reactions.first.emoji, '👍');
    });
  });

  // ---------- saveMessage ----------

  group('saveMessage', () {
    test('saves a single message', () async {
      await insertRoomForMessages(1);
      final message = makeMessage(id: 10, chatRoomId: 1, content: 'single');

      await dataSource.saveMessage(message);

      final result = await dataSource.getMessages(1);
      expect(result.length, 1);
      expect(result.first.content, 'single');
    });

    test('upserts an existing message', () async {
      await insertRoomForMessages(1);
      final original = makeMessage(id: 1, chatRoomId: 1, content: 'original');
      await dataSource.saveMessage(original);

      final updated = makeMessage(id: 1, chatRoomId: 1, content: 'updated');
      await dataSource.saveMessage(updated);

      final result = await dataSource.getMessages(1);
      expect(result.length, 1);
      expect(result.first.content, 'updated');
    });

    test('saves message with syncStatus parameter', () async {
      await insertRoomForMessages(1);
      final message = makeMessage(id: 5, chatRoomId: 1);

      await dataSource.saveMessage(message, syncStatus: 'pending');

      // Verify it was inserted (no exception thrown and retrieval works)
      final result = await dataSource.getMessages(1);
      expect(result.length, 1);
    });
  });

  // ---------- getMessages ----------

  group('getMessages', () {
    test('returns empty list when no messages exist', () async {
      final result = await dataSource.getMessages(999);
      expect(result, isEmpty);
    });

    test('returns messages only for the specified chatRoomId', () async {
      await insertRoomForMessages(1);
      await insertRoomForMessages(2);
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1),
        makeMessage(id: 2, chatRoomId: 2),
        makeMessage(id: 3, chatRoomId: 1),
      ]);

      final result = await dataSource.getMessages(1);
      expect(result.length, 2);
      expect(result.every((m) => m.chatRoomId == 1), isTrue);
    });

    test('applies limit parameter', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(1000)),
        makeMessage(id: 2, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(2000)),
        makeMessage(id: 3, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(3000)),
      ]);

      final result = await dataSource.getMessages(1, limit: 2);
      expect(result.length, 2);
    });

    test('applies beforeMessageId for pagination', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(1000)),
        makeMessage(id: 2, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(2000)),
        makeMessage(id: 3, chatRoomId: 1, createdAt: DateTime.fromMillisecondsSinceEpoch(3000)),
      ]);

      final result = await dataSource.getMessages(1, beforeMessageId: 3);
      expect(result.length, 2);
      expect(result.every((m) => m.id < 3), isTrue);
    });

    test('returns domain Message entities with correct fields', () async {
      await insertRoomForMessages(1);
      final ts = DateTime.fromMillisecondsSinceEpoch(5000);
      await dataSource.saveMessage(
        domain.Message(
          id: 7,
          chatRoomId: 1,
          senderId: 99,
          senderNickname: 'Alice',
          content: 'test content',
          type: domain.MessageType.text,
          createdAt: ts,
        ),
      );

      final result = await dataSource.getMessages(1);
      expect(result.first.id, 7);
      expect(result.first.senderId, 99);
      expect(result.first.senderNickname, 'Alice');
      expect(result.first.content, 'test content');
    });
  });

  // ---------- searchMessages ----------

  group('searchMessages', () {
    test('returns empty list for empty query', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessage(makeMessage(id: 1, chatRoomId: 1, content: 'hello'));

      final result = await dataSource.searchMessages('');
      expect(result, isEmpty);
    });

    test('returns empty list for whitespace-only query', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessage(makeMessage(id: 1, chatRoomId: 1, content: 'hello'));

      final result = await dataSource.searchMessages('   ');
      expect(result, isEmpty);
    });
  });

  // ---------- getLatestMessageId ----------

  group('getLatestMessageId', () {
    test('returns null when no messages exist', () async {
      final result = await dataSource.getLatestMessageId(1);
      expect(result, isNull);
    });

    test('returns the highest message id in the chat room', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1),
        makeMessage(id: 10, chatRoomId: 1),
        makeMessage(id: 5, chatRoomId: 1),
      ]);

      final result = await dataSource.getLatestMessageId(1);
      expect(result, 10);
    });
  });

  // ---------- deleteMessage ----------

  group('deleteMessage', () {
    test('removes message from database', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessage(makeMessage(id: 1, chatRoomId: 1));

      await dataSource.deleteMessage(1);

      final result = await dataSource.getMessages(1);
      expect(result, isEmpty);
    });

    test('does not throw when deleting non-existent message', () async {
      await expectLater(dataSource.deleteMessage(999), completes);
    });
  });

  // ---------- markMessageAsDeleted ----------

  group('markMessageAsDeleted', () {
    test('sets isDeleted flag to true', () async {
      await insertRoomForMessages(1);
      await dataSource.saveMessage(makeMessage(id: 1, chatRoomId: 1, isDeleted: false));

      await dataSource.markMessageAsDeleted(1);

      final result = await dataSource.getMessages(1);
      expect(result.first.isDeleted, isTrue);
    });
  });

  // ---------- saveChatRooms ----------

  group('saveChatRooms', () {
    test('saves multiple chat rooms', () async {
      final rooms = [
        makeChatRoom(id: 1, name: 'Room A'),
        makeChatRoom(id: 2, name: 'Room B'),
      ];

      await dataSource.saveChatRooms(rooms);

      final result = await dataSource.getChatRooms();
      expect(result.length, 2);
    });
  });

  // ---------- saveChatRoom ----------

  group('saveChatRoom', () {
    test('saves a single chat room', () async {
      final room = makeChatRoom(id: 42, name: 'My Room');

      await dataSource.saveChatRoom(room);

      final result = await dataSource.getChatRoom(42);
      expect(result, isNotNull);
      expect(result!.name, 'My Room');
    });

    test('upserts an existing chat room', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, name: 'Original'));
      await dataSource.saveChatRoom(makeChatRoom(id: 1, name: 'Updated'));

      final result = await dataSource.getChatRoom(1);
      expect(result!.name, 'Updated');
    });
  });

  // ---------- getChatRooms ----------

  group('getChatRooms', () {
    test('returns empty list when no rooms exist', () async {
      final result = await dataSource.getChatRooms();
      expect(result, isEmpty);
    });

    test('returns all saved rooms', () async {
      await dataSource.saveChatRooms([
        makeChatRoom(id: 1),
        makeChatRoom(id: 2),
        makeChatRoom(id: 3),
      ]);

      final result = await dataSource.getChatRooms();
      expect(result.length, 3);
    });
  });

  // ---------- getChatRoom ----------

  group('getChatRoom', () {
    test('returns null for non-existent room', () async {
      final result = await dataSource.getChatRoom(999);
      expect(result, isNull);
    });

    test('returns the correct room', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 5, name: 'Test Room', otherUserId: 77));

      final result = await dataSource.getChatRoom(5);
      expect(result, isNotNull);
      expect(result!.id, 5);
      expect(result.otherUserId, 77);
    });
  });

  // ---------- updateLastMessage ----------

  group('updateLastMessage', () {
    test('updates last message fields', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1));
      final ts = DateTime(2024, 1, 1, 12, 0, 0);

      await dataSource.updateLastMessage(
        roomId: 1,
        lastMessage: 'Hello!',
        lastMessageType: 'TEXT',
        lastMessageAt: ts,
      );

      final result = await dataSource.getChatRoom(1);
      expect(result!.lastMessage, 'Hello!');
      expect(result.lastMessageType, 'TEXT');
      expect(result.lastMessageAt?.millisecondsSinceEpoch, ts.millisecondsSinceEpoch);
    });

    test('can set last message to null', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, lastMessage: 'old'));

      await dataSource.updateLastMessage(
        roomId: 1,
        lastMessage: null,
        lastMessageType: null,
        lastMessageAt: null,
      );

      final result = await dataSource.getChatRoom(1);
      expect(result!.lastMessage, isNull);
    });
  });

  // ---------- updateUnreadCount ----------

  group('updateUnreadCount', () {
    test('sets unread count to specified value', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, unreadCount: 0));

      await dataSource.updateUnreadCount(1, 5);

      final result = await dataSource.getChatRoom(1);
      expect(result!.unreadCount, 5);
    });
  });

  // ---------- resetUnreadCount ----------

  group('resetUnreadCount', () {
    test('resets unread count to 0', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, unreadCount: 3));
      await dataSource.updateUnreadCount(1, 3);

      await dataSource.resetUnreadCount(1);

      final result = await dataSource.getChatRoom(1);
      expect(result!.unreadCount, 0);
    });
  });

  // ---------- updateOtherUserLeftStatus ----------

  group('updateOtherUserLeftStatus', () {
    test('sets isOtherUserLeft to true', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, isOtherUserLeft: false));

      await dataSource.updateOtherUserLeftStatus(1, true);

      final result = await dataSource.getChatRoom(1);
      expect(result!.isOtherUserLeft, isTrue);
    });

    test('sets isOtherUserLeft to false', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1, isOtherUserLeft: true));

      await dataSource.updateOtherUserLeftStatus(1, false);

      final result = await dataSource.getChatRoom(1);
      expect(result!.isOtherUserLeft, isFalse);
    });
  });

  // ---------- deleteChatRoom ----------

  group('deleteChatRoom', () {
    test('removes chat room from database', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1));

      await dataSource.deleteChatRoom(1);

      final result = await dataSource.getChatRoom(1);
      expect(result, isNull);
    });

    test('deletes messages when chat room is removed (clearAllData path)', () async {
      await dataSource.saveChatRoom(makeChatRoom(id: 1));
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1),
        makeMessage(id: 2, chatRoomId: 1),
      ]);

      // Verify messages exist before clearing
      final before = await dataSource.getMessages(1);
      expect(before.length, 2);

      // clearAllData removes all rooms AND messages atomically
      await dataSource.clearAllData();

      final rooms = await dataSource.getChatRooms();
      expect(rooms, isEmpty);
      final messages = await dataSource.getMessages(1);
      expect(messages, isEmpty);
    });

    test('does not throw when deleting non-existent room', () async {
      await expectLater(dataSource.deleteChatRoom(999), completes);
    });
  });

  // ---------- clearAllData ----------

  group('clearAllData', () {
    test('removes all chat rooms and messages', () async {
      await dataSource.saveChatRooms([
        makeChatRoom(id: 1),
        makeChatRoom(id: 2),
      ]);
      await dataSource.saveMessages([
        makeMessage(id: 1, chatRoomId: 1),
        makeMessage(id: 2, chatRoomId: 2),
      ]);

      await dataSource.clearAllData();

      final rooms = await dataSource.getChatRooms();
      expect(rooms, isEmpty);
      final msgs1 = await dataSource.getMessages(1);
      expect(msgs1, isEmpty);
    });
  });

  // ---------- watchMessages ----------

  group('watchMessages', () {
    test('emits initial empty list when no messages', () async {
      final stream = dataSource.watchMessages(1);
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emits updated list after saving a message', () async {
      await insertRoomForMessages(1);

      final stream = dataSource.watchMessages(1);
      // Consume the initial empty emission.
      final initialList = await stream.first;
      expect(initialList, isEmpty);

      await dataSource.saveMessage(makeMessage(id: 1, chatRoomId: 1, content: 'watch test'));

      final updated = await stream.first;
      expect(updated.length, 1);
      expect(updated.first.content, 'watch test');
    });
  });

  // ---------- watchChatRooms ----------

  group('watchChatRooms', () {
    test('emits initial empty list when no rooms', () async {
      final stream = dataSource.watchChatRooms();
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emits updated list after saving a chat room', () async {
      final stream = dataSource.watchChatRooms();
      final initialList = await stream.first;
      expect(initialList, isEmpty);

      await dataSource.saveChatRoom(makeChatRoom(id: 1, name: 'Watched Room'));

      final updated = await stream.first;
      expect(updated.length, 1);
      expect(updated.first.name, 'Watched Room');
    });
  });
}
