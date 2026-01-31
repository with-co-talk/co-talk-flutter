import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/message_dao.dart';
import 'daos/chat_room_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Messages, ChatRooms, MessageReactions],
  daos: [MessageDao, ChatRoomDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create FTS5 virtual table for full-text search
        await _createFtsTable(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations here
      },
    );
  }

  /// Creates the FTS5 virtual table and triggers for full-text search
  Future<void> _createFtsTable(Migrator m) async {
    // Create FTS5 virtual table
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
        content,
        file_name,
        content='messages',
        content_rowid='id'
      )
    ''');

    // Trigger to keep FTS table in sync on INSERT
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages BEGIN
        INSERT INTO messages_fts(rowid, content, file_name)
        VALUES (NEW.id, NEW.content, NEW.file_name);
      END
    ''');

    // Trigger to keep FTS table in sync on DELETE
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
        INSERT INTO messages_fts(messages_fts, rowid, content, file_name)
        VALUES('delete', OLD.id, OLD.content, OLD.file_name);
      END
    ''');

    // Trigger to keep FTS table in sync on UPDATE
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
        INSERT INTO messages_fts(messages_fts, rowid, content, file_name)
        VALUES('delete', OLD.id, OLD.content, OLD.file_name);
        INSERT INTO messages_fts(rowid, content, file_name)
        VALUES (NEW.id, NEW.content, NEW.file_name);
      END
    ''');
  }

  /// Clears all data from the database (for logout)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(messageReactions).go();
      await delete(messages).go();
      await delete(chatRooms).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'co_talk.db'));

    if (kDebugMode) {
      debugPrint('[AppDatabase] Opening database at: ${file.path}');
    }

    return NativeDatabase.createInBackground(file);
  });
}
