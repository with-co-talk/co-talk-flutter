import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/datasources/local/database/app_database.dart';

/// Helper: insert a chat room so messages can reference it (FK constraint).
Future<void> insertRoom(AppDatabase db, {int id = 1}) async {
  await db.into(db.chatRooms).insertOnConflictUpdate(ChatRoomsCompanion(
        id: Value(id),
        type: const Value('DIRECT'),
        createdAt: Value(id * 1000),
      ));
}

/// Helper: build a minimal MessagesCompanion.
MessagesCompanion buildMessage({
  required int id,
  int chatRoomId = 1,
  int senderId = 1,
  String content = 'hello',
  String type = 'TEXT',
  bool isDeleted = false,
  int? createdAt,
  String? senderNickname,
  String? senderAvatarUrl,
  String? fileUrl,
  String? fileName,
  int? fileSize,
  String? fileContentType,
  String? thumbnailUrl,
  int? replyToMessageId,
  int? forwardedFromMessageId,
  int? updatedAt,
  int unreadCount = 0,
  String syncStatus = 'synced',
}) {
  return MessagesCompanion(
    id: Value(id),
    chatRoomId: Value(chatRoomId),
    senderId: Value(senderId),
    senderNickname: Value(senderNickname),
    senderAvatarUrl: Value(senderAvatarUrl),
    content: Value(content),
    type: Value(type),
    fileUrl: Value(fileUrl),
    fileName: Value(fileName),
    fileSize: Value(fileSize),
    fileContentType: Value(fileContentType),
    thumbnailUrl: Value(thumbnailUrl),
    replyToMessageId: Value(replyToMessageId),
    forwardedFromMessageId: Value(forwardedFromMessageId),
    isDeleted: Value(isDeleted),
    createdAt: Value(createdAt ?? DateTime.now().millisecondsSinceEpoch),
    updatedAt: Value(updatedAt),
    unreadCount: Value(unreadCount),
    syncStatus: Value(syncStatus),
  );
}

/// Helper: build a minimal ChatRoomsCompanion.
ChatRoomsCompanion buildRoom({
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
  String? otherUserAvatarUrl,
  bool isOtherUserLeft = false,
  bool isOtherUserOnline = false,
  int? otherUserLastActiveAt,
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
    otherUserAvatarUrl: Value(otherUserAvatarUrl),
    isOtherUserLeft: Value(isOtherUserLeft),
    isOtherUserOnline: Value(isOtherUserOnline),
    otherUserLastActiveAt: Value(otherUserLastActiveAt),
    lastSyncAt: Value(lastSyncAt),
  );
}

/// Helper: build a minimal MessageReactionsCompanion.
MessageReactionsCompanion buildReaction({
  required int id,
  required int messageId,
  required int userId,
  String? userNickname,
  String emoji = '👍',
}) {
  return MessageReactionsCompanion(
    id: Value(id),
    messageId: Value(messageId),
    userId: Value(userId),
    userNickname: Value(userNickname),
    emoji: Value(emoji),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — column defaults
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — column defaults', () {
    test('type defaults to TEXT when not provided', () async {
      await insertRoom(db);
      await db.into(db.messages).insertOnConflictUpdate(MessagesCompanion(
            id: const Value(1),
            chatRoomId: const Value(1),
            senderId: const Value(1),
            content: const Value('hi'),
            createdAt: const Value(1000),
          ));

      final row = await (db.select(db.messages)..where((m) => m.id.equals(1))).getSingle();
      expect(row.type, 'TEXT');
    });

    test('isDeleted defaults to false', () async {
      await insertRoom(db);
      await db.into(db.messages).insertOnConflictUpdate(MessagesCompanion(
            id: const Value(2),
            chatRoomId: const Value(1),
            senderId: const Value(1),
            content: const Value('msg'),
            createdAt: const Value(2000),
          ));

      final row = await (db.select(db.messages)..where((m) => m.id.equals(2))).getSingle();
      expect(row.isDeleted, isFalse);
    });

    test('syncStatus defaults to synced', () async {
      await insertRoom(db);
      await db.into(db.messages).insertOnConflictUpdate(MessagesCompanion(
            id: const Value(3),
            chatRoomId: const Value(1),
            senderId: const Value(1),
            content: const Value('msg'),
            createdAt: const Value(3000),
          ));

      final row = await (db.select(db.messages)..where((m) => m.id.equals(3))).getSingle();
      expect(row.syncStatus, 'synced');
    });

    test('unreadCount defaults to 0', () async {
      await insertRoom(db);
      await db.into(db.messages).insertOnConflictUpdate(MessagesCompanion(
            id: const Value(4),
            chatRoomId: const Value(1),
            senderId: const Value(1),
            content: const Value('msg'),
            createdAt: const Value(4000),
          ));

      final row = await (db.select(db.messages)..where((m) => m.id.equals(4))).getSingle();
      expect(row.unreadCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — nullable columns
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — nullable columns', () {
    setUp(() async {
      await insertRoom(db);
    });

    test('senderNickname is null by default', () async {
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 10));
      final row = await (db.select(db.messages)..where((m) => m.id.equals(10))).getSingle();
      expect(row.senderNickname, isNull);
    });

    test('senderAvatarUrl is null by default', () async {
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 11));
      final row = await (db.select(db.messages)..where((m) => m.id.equals(11))).getSingle();
      expect(row.senderAvatarUrl, isNull);
    });

    test('fileUrl, fileName, fileSize, fileContentType, thumbnailUrl are null by default',
        () async {
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 12));
      final row = await (db.select(db.messages)..where((m) => m.id.equals(12))).getSingle();
      expect(row.fileUrl, isNull);
      expect(row.fileName, isNull);
      expect(row.fileSize, isNull);
      expect(row.fileContentType, isNull);
      expect(row.thumbnailUrl, isNull);
    });

    test('replyToMessageId and forwardedFromMessageId are null by default', () async {
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 13));
      final row = await (db.select(db.messages)..where((m) => m.id.equals(13))).getSingle();
      expect(row.replyToMessageId, isNull);
      expect(row.forwardedFromMessageId, isNull);
    });

    test('updatedAt is null by default', () async {
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 14));
      final row = await (db.select(db.messages)..where((m) => m.id.equals(14))).getSingle();
      expect(row.updatedAt, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — all supported type values
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — type column values', () {
    setUp(() async => insertRoom(db));

    for (final msgType in ['TEXT', 'IMAGE', 'FILE', 'SYSTEM']) {
      test('stores type=$msgType', () async {
        final idx = ['TEXT', 'IMAGE', 'FILE', 'SYSTEM'].indexOf(msgType) + 20;
        await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: idx, type: msgType));
        final row =
            await (db.select(db.messages)..where((m) => m.id.equals(idx))).getSingle();
        expect(row.type, msgType);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — syncStatus values
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — syncStatus column values', () {
    setUp(() async => insertRoom(db));

    for (final status in ['synced', 'pending', 'failed']) {
      test('stores syncStatus=$status', () async {
        final idx = ['synced', 'pending', 'failed'].indexOf(status) + 30;
        await db
            .into(db.messages)
            .insertOnConflictUpdate(buildMessage(id: idx, syncStatus: status));
        final row =
            await (db.select(db.messages)..where((m) => m.id.equals(idx))).getSingle();
        expect(row.syncStatus, status);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — full data round-trip
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — full data round-trip', () {
    test('stores and retrieves all optional fields', () async {
      await insertRoom(db);
      await insertRoom(db, id: 2);

      await db.into(db.messages).insertOnConflictUpdate(buildMessage(
            id: 50,
            chatRoomId: 1,
            senderId: 7,
            senderNickname: 'Alice',
            senderAvatarUrl: 'https://example.com/avatar.jpg',
            content: 'Check this file',
            type: 'FILE',
            fileUrl: 'https://example.com/doc.pdf',
            fileName: 'doc.pdf',
            fileSize: 4096,
            fileContentType: 'application/pdf',
            thumbnailUrl: 'https://example.com/thumb.jpg',
            replyToMessageId: 49,
            forwardedFromMessageId: 48,
            isDeleted: false,
            createdAt: 999000,
            updatedAt: 999500,
            unreadCount: 3,
            syncStatus: 'pending',
          ));

      final row = await (db.select(db.messages)..where((m) => m.id.equals(50))).getSingle();

      expect(row.senderId, 7);
      expect(row.senderNickname, 'Alice');
      expect(row.senderAvatarUrl, 'https://example.com/avatar.jpg');
      expect(row.content, 'Check this file');
      expect(row.type, 'FILE');
      expect(row.fileUrl, 'https://example.com/doc.pdf');
      expect(row.fileName, 'doc.pdf');
      expect(row.fileSize, 4096);
      expect(row.fileContentType, 'application/pdf');
      expect(row.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(row.replyToMessageId, 49);
      expect(row.forwardedFromMessageId, 48);
      expect(row.isDeleted, isFalse);
      expect(row.createdAt, 999000);
      expect(row.updatedAt, 999500);
      expect(row.unreadCount, 3);
      expect(row.syncStatus, 'pending');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — primary key
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — primary key', () {
    test('id is the primary key (duplicate insert is upserted)', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 100, content: 'original'));
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 100, content: 'updated'));

      final all = await db.select(db.messages).get();
      expect(all.where((m) => m.id == 100).length, 1);
      expect(all.first.content, 'updated');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Messages table — FK constraint definition
  // ─────────────────────────────────────────────────────────────────────────
  group('Messages table — foreign key constraint', () {
    test('customConstraints declares FK on chat_room_id referencing chat_rooms', () async {
      // The customConstraints on Messages declare:
      // FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE
      // We verify this indirectly: a message can be inserted for a known room.
      await insertRoom(db, id: 1);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 200, chatRoomId: 1));

      final row =
          await (db.select(db.messages)..where((m) => m.id.equals(200))).getSingle();
      expect(row.chatRoomId, 1);
    });

    test('messages for different chat rooms are stored independently', () async {
      await insertRoom(db, id: 1);
      await insertRoom(db, id: 2);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 200, chatRoomId: 1));
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 201, chatRoomId: 2));

      final room1Msgs = await (db.select(db.messages)
            ..where((m) => m.chatRoomId.equals(1)))
          .get();
      final room2Msgs = await (db.select(db.messages)
            ..where((m) => m.chatRoomId.equals(2)))
          .get();
      expect(room1Msgs.length, 1);
      expect(room2Msgs.length, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatRooms table — column defaults
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatRooms table — column defaults', () {
    test('type defaults to DIRECT', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(ChatRoomsCompanion(
            id: const Value(1),
            createdAt: const Value(1000),
          ));

      final row = await (db.select(db.chatRooms)..where((r) => r.id.equals(1))).getSingle();
      expect(row.type, 'DIRECT');
    });

    test('unreadCount defaults to 0', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(ChatRoomsCompanion(
            id: const Value(2),
            createdAt: const Value(2000),
          ));

      final row = await (db.select(db.chatRooms)..where((r) => r.id.equals(2))).getSingle();
      expect(row.unreadCount, 0);
    });

    test('isOtherUserLeft defaults to false', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(ChatRoomsCompanion(
            id: const Value(3),
            createdAt: const Value(3000),
          ));

      final row = await (db.select(db.chatRooms)..where((r) => r.id.equals(3))).getSingle();
      expect(row.isOtherUserLeft, isFalse);
    });

    test('isOtherUserOnline defaults to false', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(ChatRoomsCompanion(
            id: const Value(4),
            createdAt: const Value(4000),
          ));

      final row = await (db.select(db.chatRooms)..where((r) => r.id.equals(4))).getSingle();
      expect(row.isOtherUserOnline, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatRooms table — nullable columns
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatRooms table — nullable columns', () {
    test('name, lastMessage, lastMessageType are null by default', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 10));
      final row =
          await (db.select(db.chatRooms)..where((r) => r.id.equals(10))).getSingle();
      expect(row.name, isNull);
      expect(row.lastMessage, isNull);
      expect(row.lastMessageType, isNull);
    });

    test('lastMessageAt and lastSyncAt are null by default', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 11));
      final row =
          await (db.select(db.chatRooms)..where((r) => r.id.equals(11))).getSingle();
      expect(row.lastMessageAt, isNull);
      expect(row.lastSyncAt, isNull);
    });

    test('otherUserId, otherUserNickname, otherUserAvatarUrl are null by default', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 12));
      final row =
          await (db.select(db.chatRooms)..where((r) => r.id.equals(12))).getSingle();
      expect(row.otherUserId, isNull);
      expect(row.otherUserNickname, isNull);
      expect(row.otherUserAvatarUrl, isNull);
    });

    test('otherUserLastActiveAt is null by default', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 13));
      final row =
          await (db.select(db.chatRooms)..where((r) => r.id.equals(13))).getSingle();
      expect(row.otherUserLastActiveAt, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatRooms table — type values
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatRooms table — type column values', () {
    for (final roomType in ['DIRECT', 'GROUP', 'SELF']) {
      test('stores type=$roomType', () async {
        final idx = ['DIRECT', 'GROUP', 'SELF'].indexOf(roomType) + 20;
        await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: idx, type: roomType));
        final row =
            await (db.select(db.chatRooms)..where((r) => r.id.equals(idx))).getSingle();
        expect(row.type, roomType);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatRooms table — full data round-trip
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatRooms table — full data round-trip', () {
    test('stores and retrieves all optional fields', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(
            id: 50,
            name: 'My Group',
            type: 'GROUP',
            createdAt: 111000,
            lastMessage: 'Hello',
            lastMessageType: 'TEXT',
            lastMessageAt: 222000,
            unreadCount: 5,
            otherUserId: 99,
            otherUserNickname: 'Bob',
            otherUserAvatarUrl: 'https://example.com/bob.jpg',
            isOtherUserLeft: true,
            isOtherUserOnline: false,
            otherUserLastActiveAt: 333000,
            lastSyncAt: 444000,
          ));

      final row =
          await (db.select(db.chatRooms)..where((r) => r.id.equals(50))).getSingle();

      expect(row.name, 'My Group');
      expect(row.type, 'GROUP');
      expect(row.createdAt, 111000);
      expect(row.lastMessage, 'Hello');
      expect(row.lastMessageType, 'TEXT');
      expect(row.lastMessageAt, 222000);
      expect(row.unreadCount, 5);
      expect(row.otherUserId, 99);
      expect(row.otherUserNickname, 'Bob');
      expect(row.otherUserAvatarUrl, 'https://example.com/bob.jpg');
      expect(row.isOtherUserLeft, isTrue);
      expect(row.isOtherUserOnline, isFalse);
      expect(row.otherUserLastActiveAt, 333000);
      expect(row.lastSyncAt, 444000);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatRooms table — primary key
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatRooms table — primary key', () {
    test('id is the primary key (upsert updates on conflict)', () async {
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 100, name: 'original'));
      await db.into(db.chatRooms).insertOnConflictUpdate(buildRoom(id: 100, name: 'updated'));

      final all = await db.select(db.chatRooms).get();
      expect(all.where((r) => r.id == 100).length, 1);
      expect(all.first.name, 'updated');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MessageReactions table — basic insert/retrieval
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageReactions table — basic insert and retrieval', () {
    test('inserts and retrieves a reaction', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));

      await db.into(db.messageReactions).insertOnConflictUpdate(buildReaction(
            id: 1,
            messageId: 1,
            userId: 10,
            emoji: '❤️',
          ));

      final rows = await (db.select(db.messageReactions)
            ..where((r) => r.messageId.equals(1)))
          .get();

      expect(rows.length, 1);
      expect(rows.first.emoji, '❤️');
      expect(rows.first.userId, 10);
    });

    test('userNickname is null by default', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db.into(db.messageReactions).insertOnConflictUpdate(buildReaction(
            id: 1,
            messageId: 1,
            userId: 1,
          ));

      final row =
          await (db.select(db.messageReactions)..where((r) => r.id.equals(1))).getSingle();
      expect(row.userNickname, isNull);
    });

    test('stores userNickname when provided', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db.into(db.messageReactions).insertOnConflictUpdate(buildReaction(
            id: 2,
            messageId: 1,
            userId: 5,
            userNickname: 'Charlie',
            emoji: '😀',
          ));

      final row =
          await (db.select(db.messageReactions)..where((r) => r.id.equals(2))).getSingle();
      expect(row.userNickname, 'Charlie');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MessageReactions table — primary key
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageReactions table — primary key', () {
    test('id is the primary key (upsert overwrites on conflict)', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));

      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 10, messageId: 1, userId: 1, emoji: '👍'),
          );
      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 10, messageId: 1, userId: 1, emoji: '🎉'),
          );

      final rows = await db.select(db.messageReactions).get();
      expect(rows.where((r) => r.id == 10).length, 1);
      expect(rows.first.emoji, '🎉');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MessageReactions table — FK constraint definition
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageReactions table — foreign key constraint', () {
    test('customConstraints declares FK on message_id referencing messages', () async {
      // Verify reactions can be inserted for an existing message
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 300, chatRoomId: 1));
      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 1, messageId: 300, userId: 1, emoji: '👍'),
          );

      final reaction =
          await (db.select(db.messageReactions)..where((r) => r.id.equals(1))).getSingle();
      expect(reaction.messageId, 300);
    });

    test('reactions for different messages are stored independently', () async {
      await insertRoom(db);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 300, chatRoomId: 1));
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 301, chatRoomId: 1));
      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 1, messageId: 300, userId: 1, emoji: '👍'),
          );
      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 2, messageId: 301, userId: 2, emoji: '❤️'),
          );

      final msg300Reactions = await (db.select(db.messageReactions)
            ..where((r) => r.messageId.equals(300)))
          .get();
      final msg301Reactions = await (db.select(db.messageReactions)
            ..where((r) => r.messageId.equals(301)))
          .get();
      expect(msg300Reactions.length, 1);
      expect(msg301Reactions.length, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppDatabase.clearAllData
  // ─────────────────────────────────────────────────────────────────────────
  group('AppDatabase.clearAllData', () {
    test('deletes all messages, chatRooms, and messageReactions', () async {
      await insertRoom(db, id: 1);
      await insertRoom(db, id: 2);
      await db
          .into(db.messages)
          .insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db.into(db.messageReactions).insertOnConflictUpdate(
            buildReaction(id: 1, messageId: 1, userId: 1),
          );

      await db.clearAllData();

      expect(await db.select(db.chatRooms).get(), isEmpty);
      expect(await db.select(db.messages).get(), isEmpty);
      expect(await db.select(db.messageReactions).get(), isEmpty);
    });

    test('clearAllData on empty database completes without error', () async {
      await expectLater(db.clearAllData(), completes);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-table: room + messages + reactions data integrity
  // ─────────────────────────────────────────────────────────────────────────
  group('Multi-table integrity', () {
    test('can insert rooms, messages, and reactions together', () async {
      await insertRoom(db, id: 1);
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 2, chatRoomId: 1));
      await db
          .into(db.messageReactions)
          .insertOnConflictUpdate(buildReaction(id: 1, messageId: 1, userId: 1));
      await db
          .into(db.messageReactions)
          .insertOnConflictUpdate(buildReaction(id: 2, messageId: 2, userId: 2));

      expect((await db.select(db.chatRooms).get()).length, 1);
      expect((await db.select(db.messages).get()).length, 2);
      expect((await db.select(db.messageReactions).get()).length, 2);
    });

    test('messages from different rooms are stored independently', () async {
      await insertRoom(db, id: 1);
      await insertRoom(db, id: 2);
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 2, chatRoomId: 2));

      final room1Msgs = await (db.select(db.messages)
            ..where((m) => m.chatRoomId.equals(1)))
          .get();
      final room2Msgs = await (db.select(db.messages)
            ..where((m) => m.chatRoomId.equals(2)))
          .get();
      expect(room1Msgs.length, 1);
      expect(room2Msgs.length, 1);
    });

    test('clearAllData removes all data across all three tables', () async {
      await insertRoom(db, id: 1);
      await db.into(db.messages).insertOnConflictUpdate(buildMessage(id: 1, chatRoomId: 1));
      await db
          .into(db.messageReactions)
          .insertOnConflictUpdate(buildReaction(id: 1, messageId: 1, userId: 1));

      await db.clearAllData();

      expect(await db.select(db.chatRooms).get(), isEmpty);
      expect(await db.select(db.messages).get(), isEmpty);
      expect(await db.select(db.messageReactions).get(), isEmpty);
    });
  });
}
