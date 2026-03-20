import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co_talk_flutter/data/datasources/local/database/app_database.dart';
import 'package:co_talk_flutter/data/datasources/local/database/converters/entity_converters.dart';
import 'package:co_talk_flutter/domain/entities/message.dart' as domain;
import 'package:co_talk_flutter/domain/entities/chat_room.dart' as domain;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Inserts a chat room row needed to satisfy FK for messages.
  Future<void> insertChatRoom(int id) async {
    await database.into(database.chatRooms).insert(
          ChatRoomsCompanion(
            id: Value(id),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
          ),
        );
  }

  domain.Message buildDomainMessage({
    int id = 1,
    int chatRoomId = 1,
    int senderId = 10,
    String senderNickname = 'Alice',
    String content = 'Hello',
    domain.MessageType type = domain.MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileContentType,
    String? thumbnailUrl,
    int? replyToMessageId,
    int? forwardedFromMessageId,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<domain.MessageReaction> reactions = const [],
    int unreadCount = 0,
  }) {
    return domain.Message(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderNickname: senderNickname,
      content: content,
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileContentType: fileContentType,
      thumbnailUrl: thumbnailUrl,
      replyToMessageId: replyToMessageId,
      forwardedFromMessageId: forwardedFromMessageId,
      isDeleted: isDeleted,
      createdAt: createdAt ?? DateTime(2024, 1, 1, 10, 0),
      updatedAt: updatedAt,
      reactions: reactions,
      unreadCount: unreadCount,
    );
  }

  domain.ChatRoom buildDomainChatRoom({
    int id = 1,
    String? name,
    domain.ChatRoomType type = domain.ChatRoomType.direct,
    DateTime? createdAt,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int unreadCount = 0,
    int? otherUserId,
    String? otherUserNickname,
    String? otherUserAvatarUrl,
    bool isOtherUserLeft = false,
    bool isOtherUserOnline = false,
    DateTime? otherUserLastActiveAt,
  }) {
    return domain.ChatRoom(
      id: id,
      name: name,
      type: type,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      otherUserId: otherUserId,
      otherUserNickname: otherUserNickname,
      otherUserAvatarUrl: otherUserAvatarUrl,
      isOtherUserLeft: isOtherUserLeft,
      isOtherUserOnline: isOtherUserOnline,
      otherUserLastActiveAt: otherUserLastActiveAt,
    );
  }

  // ---------------------------------------------------------------------------
  // messageToCompanion
  // ---------------------------------------------------------------------------

  group('messageToCompanion', () {
    test('maps basic text message fields correctly', () async {
      final message = buildDomainMessage();
      final companion = messageToCompanion(message);

      expect(companion.id.value, 1);
      expect(companion.chatRoomId.value, 1);
      expect(companion.senderId.value, 10);
      expect(companion.senderNickname.value, 'Alice');
      expect(companion.content.value, 'Hello');
      expect(companion.type.value, 'TEXT');
      expect(companion.isDeleted.value, false);
      expect(companion.unreadCount.value, 0);
      expect(companion.syncStatus.value, 'synced');
    });

    test('maps syncStatus parameter correctly', () {
      final message = buildDomainMessage();
      final companion = messageToCompanion(message, syncStatus: 'pending');
      expect(companion.syncStatus.value, 'pending');
    });

    test('maps MessageType.image to IMAGE string', () {
      final message = buildDomainMessage(type: domain.MessageType.image);
      final companion = messageToCompanion(message);
      expect(companion.type.value, 'IMAGE');
    });

    test('maps MessageType.file to FILE string', () {
      final message = buildDomainMessage(type: domain.MessageType.file);
      final companion = messageToCompanion(message);
      expect(companion.type.value, 'FILE');
    });

    test('maps MessageType.system to SYSTEM string', () {
      final message = buildDomainMessage(type: domain.MessageType.system);
      final companion = messageToCompanion(message);
      expect(companion.type.value, 'SYSTEM');
    });

    test('maps createdAt to millisecondsSinceEpoch', () {
      final ts = DateTime(2024, 6, 15, 12, 30);
      final message = buildDomainMessage(createdAt: ts);
      final companion = messageToCompanion(message);
      expect(companion.createdAt.value, ts.millisecondsSinceEpoch);
    });

    test('maps updatedAt to millisecondsSinceEpoch when present', () {
      final ts = DateTime(2024, 6, 15, 13, 0);
      final message = buildDomainMessage(updatedAt: ts);
      final companion = messageToCompanion(message);
      expect(companion.updatedAt.value, ts.millisecondsSinceEpoch);
    });

    test('maps updatedAt to null when absent', () {
      final message = buildDomainMessage(updatedAt: null);
      final companion = messageToCompanion(message);
      expect(companion.updatedAt.value, isNull);
    });

    test('maps optional file fields', () {
      final message = buildDomainMessage(
        type: domain.MessageType.image,
        fileUrl: 'https://example.com/img.jpg',
        fileName: 'img.jpg',
        fileSize: 2048,
        fileContentType: 'image/jpeg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );
      final companion = messageToCompanion(message);
      expect(companion.fileUrl.value, 'https://example.com/img.jpg');
      expect(companion.fileName.value, 'img.jpg');
      expect(companion.fileSize.value, 2048);
      expect(companion.fileContentType.value, 'image/jpeg');
      expect(companion.thumbnailUrl.value, 'https://example.com/thumb.jpg');
    });

    test('maps reply and forward IDs', () {
      final message = buildDomainMessage(
        replyToMessageId: 5,
        forwardedFromMessageId: 7,
      );
      final companion = messageToCompanion(message);
      expect(companion.replyToMessageId.value, 5);
      expect(companion.forwardedFromMessageId.value, 7);
    });

    test('maps isDeleted flag', () {
      final message = buildDomainMessage(isDeleted: true);
      final companion = messageToCompanion(message);
      expect(companion.isDeleted.value, true);
    });
  });

  // ---------------------------------------------------------------------------
  // dbMessageToEntity - requires actual DB rows
  // ---------------------------------------------------------------------------

  group('dbMessageToEntity', () {
    test('converts db row to domain Message with basic fields', () async {
      await insertChatRoom(1);
      final companion = MessagesCompanion(
        id: const Value(1),
        chatRoomId: const Value(1),
        senderId: const Value(10),
        senderNickname: const Value('Alice'),
        content: const Value('Hello'),
        type: const Value('TEXT'),
        isDeleted: const Value(false),
        createdAt: Value(DateTime(2024, 1, 1, 10, 0).millisecondsSinceEpoch),
        unreadCount: const Value(3),
        syncStatus: const Value('synced'),
      );
      await database.into(database.messages).insert(companion);

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(1)))
          .getSingle();

      final entity = dbMessageToEntity(row, []);
      expect(entity.id, 1);
      expect(entity.chatRoomId, 1);
      expect(entity.senderId, 10);
      expect(entity.senderNickname, 'Alice');
      expect(entity.content, 'Hello');
      expect(entity.type, domain.MessageType.text);
      expect(entity.isDeleted, false);
      expect(entity.unreadCount, 3);
      expect(entity.reactions, isEmpty);
    });

    test('parses IMAGE type from db row', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(2),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('img'),
            type: const Value('IMAGE'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(2)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.type, domain.MessageType.image);
    });

    test('parses FILE type from db row', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(3),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('doc'),
            type: const Value('FILE'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(3)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.type, domain.MessageType.file);
    });

    test('parses SYSTEM type from db row', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(4),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('sys'),
            type: const Value('SYSTEM'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(4)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.type, domain.MessageType.system);
    });

    test('unknown type string defaults to text', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(5),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('unknown'),
            type: const Value('UNKNOWN_TYPE'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(5)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.type, domain.MessageType.text);
    });

    test('converts updatedAt milliseconds to DateTime', () async {
      await insertChatRoom(1);
      final updatedAt = DateTime(2024, 6, 15, 13, 0);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(6),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('edited'),
            type: const Value('TEXT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            updatedAt: Value(updatedAt.millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(6)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt.millisecondsSinceEpoch));
    });

    test('updatedAt is null when not set', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(7),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('no update'),
            type: const Value('TEXT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(7)))
          .getSingle();
      final entity = dbMessageToEntity(row, []);
      expect(entity.updatedAt, isNull);
    });

    test('includes provided reactions in entity', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(8),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('react me'),
            type: const Value('TEXT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(8)))
          .getSingle();

      const reactions = [
        domain.MessageReaction(id: 1, messageId: 8, userId: 99, emoji: '👍'),
      ];
      final entity = dbMessageToEntity(row, reactions);
      expect(entity.reactions.length, 1);
      expect(entity.reactions.first.emoji, '👍');
    });
  });

  // ---------------------------------------------------------------------------
  // chatRoomToCompanion
  // ---------------------------------------------------------------------------

  group('chatRoomToCompanion', () {
    test('maps direct chat room fields correctly', () {
      final chatRoom = buildDomainChatRoom(
        id: 1,
        type: domain.ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
        otherUserId: 2,
        otherUserNickname: 'Bob',
      );
      final companion = chatRoomToCompanion(chatRoom);

      expect(companion.id.value, 1);
      expect(companion.type.value, 'DIRECT');
      expect(companion.createdAt.value, DateTime(2024, 1, 1).millisecondsSinceEpoch);
      expect(companion.otherUserId.value, 2);
      expect(companion.otherUserNickname.value, 'Bob');
    });

    test('maps group chat room type to GROUP string', () {
      final chatRoom = buildDomainChatRoom(
        id: 2,
        name: 'Team Chat',
        type: domain.ChatRoomType.group,
      );
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.type.value, 'GROUP');
      expect(companion.name.value, 'Team Chat');
    });

    test('maps self chat room type to SELF string', () {
      final chatRoom = buildDomainChatRoom(
        id: 3,
        type: domain.ChatRoomType.self,
      );
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.type.value, 'SELF');
    });

    test('maps lastMessageAt to millisecondsSinceEpoch when present', () {
      final ts = DateTime(2024, 6, 15, 14, 0);
      final chatRoom = buildDomainChatRoom(lastMessageAt: ts);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.lastMessageAt.value, ts.millisecondsSinceEpoch);
    });

    test('maps lastMessageAt to null when absent', () {
      final chatRoom = buildDomainChatRoom(lastMessageAt: null);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.lastMessageAt.value, isNull);
    });

    test('maps otherUserLastActiveAt to millisecondsSinceEpoch when present', () {
      final ts = DateTime(2024, 6, 15, 9, 0);
      final chatRoom = buildDomainChatRoom(otherUserLastActiveAt: ts);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.otherUserLastActiveAt.value, ts.millisecondsSinceEpoch);
    });

    test('maps otherUserLastActiveAt to null when absent', () {
      final chatRoom = buildDomainChatRoom(otherUserLastActiveAt: null);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.otherUserLastActiveAt.value, isNull);
    });

    test('maps isOtherUserLeft flag', () {
      final chatRoom = buildDomainChatRoom(isOtherUserLeft: true);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.isOtherUserLeft.value, true);
    });

    test('maps isOtherUserOnline flag', () {
      final chatRoom = buildDomainChatRoom(isOtherUserOnline: true);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.isOtherUserOnline.value, true);
    });

    test('maps lastMessage and lastMessageType', () {
      final chatRoom = buildDomainChatRoom(
        lastMessage: 'See you',
        lastMessageType: 'TEXT',
      );
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.lastMessage.value, 'See you');
      expect(companion.lastMessageType.value, 'TEXT');
    });

    test('maps unreadCount', () {
      final chatRoom = buildDomainChatRoom(unreadCount: 7);
      final companion = chatRoomToCompanion(chatRoom);
      expect(companion.unreadCount.value, 7);
    });
  });

  // ---------------------------------------------------------------------------
  // dbChatRoomToEntity - requires actual DB rows
  // ---------------------------------------------------------------------------

  group('dbChatRoomToEntity', () {
    test('converts basic direct chat room row to entity', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(1),
            name: const Value(null),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            otherUserId: const Value(2),
            otherUserNickname: const Value('Bob'),
            unreadCount: const Value(5),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(1)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.id, 1);
      expect(entity.type, domain.ChatRoomType.direct);
      expect(entity.otherUserId, 2);
      expect(entity.otherUserNickname, 'Bob');
      expect(entity.unreadCount, 5);
      expect(entity.name, isNull);
    });

    test('parses GROUP type from db row', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(2),
            name: const Value('Team'),
            type: const Value('GROUP'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(2)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.type, domain.ChatRoomType.group);
      expect(entity.name, 'Team');
    });

    test('parses SELF type from db row', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(3),
            type: const Value('SELF'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(3)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.type, domain.ChatRoomType.self);
    });

    test('unknown type string defaults to direct', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(4),
            type: const Value('UNKNOWN'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(4)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.type, domain.ChatRoomType.direct);
    });

    test('converts lastMessageAt milliseconds to DateTime', () async {
      final ts = DateTime(2024, 6, 15, 14, 0);
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(5),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            lastMessageAt: Value(ts.millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(5)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.lastMessageAt, DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch));
    });

    test('lastMessageAt is null when not set', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(6),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(6)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.lastMessageAt, isNull);
    });

    test('converts otherUserLastActiveAt milliseconds to DateTime', () async {
      final ts = DateTime(2024, 6, 15, 9, 30);
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(7),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            otherUserLastActiveAt: Value(ts.millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(7)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.otherUserLastActiveAt, DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch));
    });

    test('otherUserLastActiveAt is null when not set', () async {
      await database.into(database.chatRooms).insert(ChatRoomsCompanion(
            id: const Value(8),
            type: const Value('DIRECT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
          ));

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(8)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.otherUserLastActiveAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // reactionToCompanion
  // ---------------------------------------------------------------------------

  group('reactionToCompanion', () {
    test('maps reaction fields correctly', () {
      const reaction = domain.MessageReaction(
        id: 1,
        messageId: 42,
        userId: 7,
        userNickname: 'Charlie',
        emoji: '❤️',
      );
      final companion = reactionToCompanion(reaction);

      expect(companion.id.value, 1);
      expect(companion.messageId.value, 42);
      expect(companion.userId.value, 7);
      expect(companion.userNickname.value, 'Charlie');
      expect(companion.emoji.value, '❤️');
    });

    test('maps reaction with null userNickname', () {
      const reaction = domain.MessageReaction(
        id: 2,
        messageId: 10,
        userId: 5,
        userNickname: null,
        emoji: '👍',
      );
      final companion = reactionToCompanion(reaction);
      expect(companion.userNickname.value, isNull);
      expect(companion.emoji.value, '👍');
    });
  });

  // ---------------------------------------------------------------------------
  // dbReactionToEntity
  // ---------------------------------------------------------------------------

  group('dbReactionToEntity', () {
    test('converts db row to domain MessageReaction', () async {
      await insertChatRoom(1);
      // Insert parent message first
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(1),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('msg'),
            type: const Value('TEXT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      await database.into(database.messageReactions).insert(
            MessageReactionsCompanion(
              id: const Value(1),
              messageId: const Value(1),
              userId: const Value(7),
              userNickname: const Value('Charlie'),
              emoji: const Value('❤️'),
            ),
          );

      final row = await (database.select(database.messageReactions)
            ..where((t) => t.id.equals(1)))
          .getSingle();

      final entity = dbReactionToEntity(row);
      expect(entity.id, 1);
      expect(entity.messageId, 1);
      expect(entity.userId, 7);
      expect(entity.userNickname, 'Charlie');
      expect(entity.emoji, '❤️');
    });

    test('converts db row with null userNickname', () async {
      await insertChatRoom(1);
      await database.into(database.messages).insert(MessagesCompanion(
            id: const Value(2),
            chatRoomId: const Value(1),
            senderId: const Value(10),
            content: const Value('msg2'),
            type: const Value('TEXT'),
            createdAt: Value(DateTime(2024, 1, 1).millisecondsSinceEpoch),
            unreadCount: const Value(0),
            syncStatus: const Value('synced'),
          ));

      await database.into(database.messageReactions).insert(
            MessageReactionsCompanion(
              id: const Value(2),
              messageId: const Value(2),
              userId: const Value(9),
              emoji: const Value('😂'),
            ),
          );

      final row = await (database.select(database.messageReactions)
            ..where((t) => t.id.equals(2)))
          .getSingle();

      final entity = dbReactionToEntity(row);
      expect(entity.userNickname, isNull);
      expect(entity.emoji, '😂');
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: messageToCompanion -> insert -> dbMessageToEntity
  // ---------------------------------------------------------------------------

  group('round-trip: message', () {
    test('message survives a full write-read cycle', () async {
      await insertChatRoom(1);

      final original = buildDomainMessage(
        id: 100,
        chatRoomId: 1,
        senderId: 20,
        senderNickname: 'Dave',
        content: 'Round-trip test',
        type: domain.MessageType.image,
        fileUrl: 'https://example.com/img.png',
        fileName: 'img.png',
        fileSize: 4096,
        fileContentType: 'image/png',
        unreadCount: 2,
      );

      final companion = messageToCompanion(original, syncStatus: 'synced');
      await database.into(database.messages).insert(companion);

      final row = await (database.select(database.messages)
            ..where((t) => t.id.equals(100)))
          .getSingle();

      final entity = dbMessageToEntity(row, []);
      expect(entity.id, original.id);
      expect(entity.chatRoomId, original.chatRoomId);
      expect(entity.senderId, original.senderId);
      expect(entity.senderNickname, original.senderNickname);
      expect(entity.content, original.content);
      expect(entity.type, original.type);
      expect(entity.fileUrl, original.fileUrl);
      expect(entity.fileName, original.fileName);
      expect(entity.fileSize, original.fileSize);
      expect(entity.fileContentType, original.fileContentType);
      expect(entity.unreadCount, original.unreadCount);
      expect(entity.createdAt.millisecondsSinceEpoch,
          original.createdAt.millisecondsSinceEpoch);
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: chatRoomToCompanion -> insert -> dbChatRoomToEntity
  // ---------------------------------------------------------------------------

  group('round-trip: chat room', () {
    test('chat room survives a full write-read cycle', () async {
      final lastMessageAt = DateTime(2024, 6, 1, 8, 0);
      final original = buildDomainChatRoom(
        id: 200,
        name: 'Book Club',
        type: domain.ChatRoomType.group,
        createdAt: DateTime(2024, 1, 1),
        lastMessage: 'See you tomorrow',
        lastMessageType: 'TEXT',
        lastMessageAt: lastMessageAt,
        unreadCount: 3,
        isOtherUserLeft: false,
        isOtherUserOnline: true,
      );

      final companion = chatRoomToCompanion(original);
      await database.into(database.chatRooms).insert(companion);

      final row = await (database.select(database.chatRooms)
            ..where((t) => t.id.equals(200)))
          .getSingle();

      final entity = dbChatRoomToEntity(row);
      expect(entity.id, original.id);
      expect(entity.name, original.name);
      expect(entity.type, original.type);
      expect(entity.lastMessage, original.lastMessage);
      expect(entity.lastMessageType, original.lastMessageType);
      expect(entity.unreadCount, original.unreadCount);
      expect(entity.isOtherUserOnline, original.isOtherUserOnline);
      expect(entity.lastMessageAt?.millisecondsSinceEpoch,
          lastMessageAt.millisecondsSinceEpoch);
    });
  });
}
