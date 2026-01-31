import 'package:drift/drift.dart';

/// Messages table for storing chat messages locally
class Messages extends Table {
  IntColumn get id => integer()();
  IntColumn get chatRoomId => integer()();
  IntColumn get senderId => integer()();
  TextColumn get senderNickname => text().nullable()();
  TextColumn get senderAvatarUrl => text().nullable()();
  TextColumn get content => text()();
  TextColumn get type => text().withDefault(const Constant('TEXT'))();
  TextColumn get fileUrl => text().nullable()();
  TextColumn get fileName => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get fileContentType => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get replyToMessageId => integer().nullable()();
  IntColumn get forwardedFromMessageId => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()(); // Unix timestamp in milliseconds
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))(); // synced, pending, failed

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE',
      ];
}

/// ChatRooms table for storing chat room metadata locally
class ChatRooms extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get type =>
      text().withDefault(const Constant('DIRECT'))(); // DIRECT, GROUP
  IntColumn get createdAt => integer()(); // Unix timestamp in milliseconds
  TextColumn get lastMessage => text().nullable()();
  TextColumn get lastMessageType => text().nullable()();
  IntColumn get lastMessageAt => integer().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get otherUserId => integer().nullable()(); // For 1:1 chats
  TextColumn get otherUserNickname => text().nullable()();
  TextColumn get otherUserAvatarUrl => text().nullable()();
  BoolColumn get isOtherUserLeft =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isOtherUserOnline =>
      boolean().withDefault(const Constant(false))();
  IntColumn get otherUserLastActiveAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()(); // Last sync timestamp

  @override
  Set<Column> get primaryKey => {id};
}

/// MessageReactions table for storing message reactions
class MessageReactions extends Table {
  IntColumn get id => integer()();
  IntColumn get messageId => integer()();
  IntColumn get userId => integer()();
  TextColumn get userNickname => text().nullable()();
  TextColumn get emoji => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE',
      ];
}
