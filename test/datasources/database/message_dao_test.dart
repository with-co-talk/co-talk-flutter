import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/datasources/local/database/app_database.dart';
import 'package:co_talk_flutter/data/datasources/local/database/daos/message_dao.dart';

void main() {
  late AppDatabase database;
  late MessageDao messageDao;

  setUp(() {
    // 테스트용 인메모리 데이터베이스 생성
    database = AppDatabase.forTesting(NativeDatabase.memory());
    messageDao = database.messageDao;
  });

  tearDown(() async {
    await database.close();
  });

  MessagesCompanion createTestMessage({
    required int id,
    required int chatRoomId,
    required int senderId,
    String? senderNickname,
    String content = 'Test message',
    String type = 'TEXT',
    bool isDeleted = false,
    int? createdAt,
    String syncStatus = 'synced',
  }) {
    return MessagesCompanion(
      id: Value(id),
      chatRoomId: Value(chatRoomId),
      senderId: Value(senderId),
      senderNickname: Value(senderNickname),
      content: Value(content),
      type: Value(type),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? DateTime.now().millisecondsSinceEpoch),
      unreadCount: const Value(0),
      syncStatus: Value(syncStatus),
    );
  }

  group('MessageDao', () {
    group('upsertMessage', () {
      test('새 메시지를 삽입함', () async {
        final message = createTestMessage(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '안녕하세요',
        );

        await messageDao.upsertMessage(message);

        final result = await messageDao.getMessageById(1);
        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.content, '안녕하세요');
        expect(result.chatRoomId, 1);
      });

      test('기존 메시지를 업데이트함', () async {
        final message = createTestMessage(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '원본 메시지',
        );
        await messageDao.upsertMessage(message);

        final updatedMessage = createTestMessage(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '수정된 메시지',
        );
        await messageDao.upsertMessage(updatedMessage);

        final result = await messageDao.getMessageById(1);
        expect(result!.content, '수정된 메시지');
      });
    });

    group('upsertMessages', () {
      test('여러 메시지를 한번에 삽입함', () async {
        final messages = [
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, content: '메시지 1'),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 2, content: '메시지 2'),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1, content: '메시지 3'),
        ];

        await messageDao.upsertMessages(messages);

        final results = await messageDao.getMessagesByChatRoom(1);
        expect(results.length, 3);
      });
    });

    group('getMessagesByChatRoom', () {
      test('채팅방의 모든 메시지를 가져옴', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, createdAt: 1000),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 2, createdAt: 2000),
          createTestMessage(id: 3, chatRoomId: 2, senderId: 1, createdAt: 3000),
        ]);

        final results = await messageDao.getMessagesByChatRoom(1);
        expect(results.length, 2);
        expect(results.every((m) => m.chatRoomId == 1), isTrue);
      });

      test('createdAt 내림차순으로 정렬됨', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, createdAt: 1000),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 1, createdAt: 3000),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1, createdAt: 2000),
        ]);

        final results = await messageDao.getMessagesByChatRoom(1);
        expect(results[0].createdAt, 3000);
        expect(results[1].createdAt, 2000);
        expect(results[2].createdAt, 1000);
      });

      test('limit 파라미터가 적용됨', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1),
        ]);

        final results = await messageDao.getMessagesByChatRoom(1, limit: 2);
        expect(results.length, 2);
      });

      test('beforeMessageId 파라미터가 적용됨 (페이지네이션)', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, createdAt: 1000),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 1, createdAt: 2000),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1, createdAt: 3000),
        ]);

        final results = await messageDao.getMessagesByChatRoom(1, beforeMessageId: 3);
        expect(results.length, 2);
        expect(results.every((m) => m.id < 3), isTrue);
      });
    });

    group('getMessageById', () {
      test('존재하는 메시지를 반환함', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, content: '테스트'),
        );

        final result = await messageDao.getMessageById(1);
        expect(result, isNotNull);
        expect(result!.content, '테스트');
      });

      test('존재하지 않는 메시지는 null 반환', () async {
        final result = await messageDao.getMessageById(999);
        expect(result, isNull);
      });
    });

    group('deleteMessageById', () {
      test('메시지를 삭제함', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
        );

        final deleteCount = await messageDao.deleteMessageById(1);
        expect(deleteCount, 1);

        final result = await messageDao.getMessageById(1);
        expect(result, isNull);
      });

      test('존재하지 않는 메시지 삭제 시 0 반환', () async {
        final deleteCount = await messageDao.deleteMessageById(999);
        expect(deleteCount, 0);
      });
    });

    group('deleteMessagesByChatRoom', () {
      test('채팅방의 모든 메시지를 삭제함', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 3, chatRoomId: 2, senderId: 1),
        ]);

        final deleteCount = await messageDao.deleteMessagesByChatRoom(1);
        expect(deleteCount, 2);

        final room1Messages = await messageDao.getMessagesByChatRoom(1);
        expect(room1Messages, isEmpty);

        final room2Messages = await messageDao.getMessagesByChatRoom(2);
        expect(room2Messages.length, 1);
      });
    });

    group('markMessageAsDeleted', () {
      test('메시지를 소프트 삭제함 (isDeleted = true)', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, isDeleted: false),
        );

        await messageDao.markMessageAsDeleted(1);

        final result = await messageDao.getMessageById(1);
        expect(result!.isDeleted, isTrue);
      });
    });

    group('searchMessages', () {
      test('빈 쿼리는 빈 결과 반환', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, content: '테스트'),
        );

        final results = await messageDao.searchMessages('');
        expect(results, isEmpty);

        final results2 = await messageDao.searchMessages('   ');
        expect(results2, isEmpty);
      });

      // FTS5 검색 테스트는 인메모리 DB에서 제한적일 수 있음
      // 실제 검색 기능은 통합 테스트에서 검증
    });

    group('getLatestMessageId', () {
      test('채팅방의 최신 메시지 ID를 반환함', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 5, chatRoomId: 1, senderId: 1),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1),
        ]);

        final latestId = await messageDao.getLatestMessageId(1);
        expect(latestId, 5);
      });

      test('메시지가 없으면 null 반환', () async {
        final latestId = await messageDao.getLatestMessageId(1);
        expect(latestId, isNull);
      });
    });

    group('updateSyncStatus', () {
      test('메시지의 syncStatus를 업데이트함', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, syncStatus: 'pending'),
        );

        await messageDao.updateSyncStatus(1, 'synced');

        final result = await messageDao.getMessageById(1);
        expect(result!.syncStatus, 'synced');
      });
    });

    group('getPendingMessages', () {
      test('pending 상태의 메시지만 반환함', () async {
        await messageDao.upsertMessages([
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1, syncStatus: 'pending'),
          createTestMessage(id: 2, chatRoomId: 1, senderId: 1, syncStatus: 'synced'),
          createTestMessage(id: 3, chatRoomId: 1, senderId: 1, syncStatus: 'pending'),
        ]);

        final results = await messageDao.getPendingMessages();
        expect(results.length, 2);
        expect(results.every((m) => m.syncStatus == 'pending'), isTrue);
      });
    });

    group('MessageReactions', () {
      MessageReactionsCompanion createTestReaction({
        required int id,
        required int messageId,
        required int userId,
        String emoji = '👍',
      }) {
        return MessageReactionsCompanion(
          id: Value(id),
          messageId: Value(messageId),
          userId: Value(userId),
          emoji: Value(emoji),
        );
      }

      test('리액션을 삽입하고 조회함', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
        );

        await messageDao.upsertReactions([
          createTestReaction(id: 1, messageId: 1, userId: 1, emoji: '👍'),
          createTestReaction(id: 2, messageId: 1, userId: 2, emoji: '❤️'),
        ]);

        final reactions = await messageDao.getReactionsByMessageId(1);
        expect(reactions.length, 2);
      });

      test('메시지의 모든 리액션을 삭제함', () async {
        await messageDao.upsertMessage(
          createTestMessage(id: 1, chatRoomId: 1, senderId: 1),
        );

        await messageDao.upsertReactions([
          createTestReaction(id: 1, messageId: 1, userId: 1),
          createTestReaction(id: 2, messageId: 1, userId: 2),
        ]);

        final deleteCount = await messageDao.deleteReactionsByMessageId(1);
        expect(deleteCount, 2);

        final reactions = await messageDao.getReactionsByMessageId(1);
        expect(reactions, isEmpty);
      });
    });
  });
}
