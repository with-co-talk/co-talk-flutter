import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/constants/app_constants.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/managers/message_cache_manager.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockChatRepository;
  late MessageCacheManager cacheManager;

  setUp(() {
    mockChatRepository = MockChatRepository();
    cacheManager = MessageCacheManager(mockChatRepository);
  });

  Message createMessage({
    required int id,
    int roomId = 1,
    String content = 'test',
    MessageSendStatus sendStatus = MessageSendStatus.sent,
    String? localId,
  }) {
    return Message(
      id: id,
      chatRoomId: roomId,
      senderId: 100,
      content: content,
      createdAt: DateTime.now(),
      sendStatus: sendStatus,
      localId: localId,
    );
  }

  group('refreshFromServer', () {
    const roomId = 1;

    test('merges new messages from server successfully', () async {
      // Arrange: Set up initial cache with messages [id:1, id:2]
      final initialMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
      ];
      cacheManager.syncMessages(initialMessages);

      // Mock getMessages to return [id:1, id:2, id:3] (id:3 is new)
      final serverMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
        createMessage(id: 3, content: 'message 3'),
      ];
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenAnswer((_) async => (serverMessages, 100, true));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert
      expect(hasNewMessages, true, reason: 'Should return true for new messages');
      expect(cacheManager.messages.length, 3, reason: 'Should contain all 3 messages');
      expect(cacheManager.messages.map((m) => m.id).toList(), containsAll([1, 2, 3]));
      expect(cacheManager.isOfflineData, false, reason: 'Should mark as online data');
    });

    test('deduplicates messages by id', () async {
      // Arrange: Set up initial cache with [id:1, id:2]
      final initialMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
      ];
      cacheManager.syncMessages(initialMessages);

      // Mock getMessages to return [id:1, id:2] (same messages, no new ones)
      final serverMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
      ];
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenAnswer((_) async => (serverMessages, 100, false));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert
      expect(hasNewMessages, false, reason: 'Should return false when no new messages');
      expect(cacheManager.messages.length, 2, reason: 'Should have no duplicates');
      expect(cacheManager.messages.map((m) => m.id).toList(), [2, 1]);
    });

    test('preserves pending messages during merge', () async {
      // Arrange: Add a pending message
      final pendingMessage = createMessage(
        id: -1,
        content: 'pending message',
        sendStatus: MessageSendStatus.pending,
        localId: 'local-1',
      );
      cacheManager.addPendingMessage(pendingMessage);

      // Set up cache with [pending(-1), sent(1), sent(2)]
      final sentMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
      ];
      cacheManager.syncMessages([pendingMessage, ...sentMessages]);

      // Mock getMessages to return [id:1, id:2, id:3]
      final serverMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
        createMessage(id: 3, content: 'message 3'),
      ];
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenAnswer((_) async => (serverMessages, 100, true));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert
      expect(hasNewMessages, true, reason: 'Should return true for new messages');
      expect(
        cacheManager.messages.any((m) => m.isPending && m.localId == 'local-1'),
        true,
        reason: 'Pending message should still be in the list',
      );
      expect(
        cacheManager.messages.where((m) => !m.isPending).length,
        3,
        reason: 'Should have 3 server messages',
      );
      expect(
        cacheManager.messages.where((m) => m.isPending).length,
        1,
        reason: 'Should have 1 pending message',
      );
    });

    test(
        'preserves older paginated messages not in the latest server page',
        () async {
      // Arrange: User scrolled up and loaded older pages, so the cache holds
      // ids [1..5]. The server's "latest page" (size-limited) only returns the
      // newest slice [3, 4, 5]. The older messages [1, 2] must NOT be dropped.
      final cachedMessages = [
        createMessage(id: 5, content: 'message 5'),
        createMessage(id: 4, content: 'message 4'),
        createMessage(id: 3, content: 'message 3'),
        createMessage(id: 2, content: 'message 2'),
        createMessage(id: 1, content: 'message 1'),
      ];
      // hasMore=false because we've paginated to the very first message.
      cacheManager.syncMessages(cachedMessages, nextCursor: 1, hasMore: false);

      final serverPage = [
        createMessage(id: 5, content: 'message 5'),
        createMessage(id: 4, content: 'message 4'),
        createMessage(id: 3, content: 'message 3'),
      ];
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenAnswer((_) async => (serverPage, 3, true));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert: older messages preserved, no data loss.
      expect(hasNewMessages, false,
          reason: 'No genuinely new server message arrived');
      expect(cacheManager.messages.map((m) => m.id).toList(), [5, 4, 3, 2, 1],
          reason: 'Older paginated messages [2, 1] must be preserved');
      // Pagination invariant: cursor must still point past the oldest message,
      // and hasMore must reflect the older cache, not the (smaller) server page.
      expect(cacheManager.hasMore, false,
          reason: 'We already paginated to the first message; still no more');
      expect(cacheManager.nextCursor, 1,
          reason: 'Cursor must remain at the oldest preserved message');
    });

    test(
        'preserves older messages AND merges a new latest server message',
        () async {
      // Arrange: cache holds older pages [1..4]; server returns latest page
      // [3, 4, 5] where id:5 is brand new.
      final cachedMessages = [
        createMessage(id: 4, content: 'message 4'),
        createMessage(id: 3, content: 'message 3'),
        createMessage(id: 2, content: 'message 2'),
        createMessage(id: 1, content: 'message 1'),
      ];
      cacheManager.syncMessages(cachedMessages, nextCursor: 1, hasMore: false);

      final serverPage = [
        createMessage(id: 5, content: 'message 5'),
        createMessage(id: 4, content: 'message 4'),
        createMessage(id: 3, content: 'message 3'),
      ];
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenAnswer((_) async => (serverPage, 3, true));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert
      expect(hasNewMessages, true, reason: 'id:5 is a new server message');
      expect(cacheManager.messages.map((m) => m.id).toList(),
          [5, 4, 3, 2, 1],
          reason: 'New message prepended, older messages preserved, desc order');
    });

    test('keeps existing cache on network error', () async {
      // Arrange: Set up initial cache with [id:1, id:2]
      final initialMessages = [
        createMessage(id: 1, content: 'message 1'),
        createMessage(id: 2, content: 'message 2'),
      ];
      cacheManager.syncMessages(initialMessages);

      // Mock getMessages to throw exception
      when(() => mockChatRepository.getMessages(
            roomId,
            size: AppConstants.messagePageSize,
          )).thenThrow(Exception('Network error'));

      // Act
      final hasNewMessages = await cacheManager.refreshFromServer(roomId);

      // Assert
      expect(hasNewMessages, false, reason: 'Should return false on error');
      expect(cacheManager.messages.length, 2, reason: 'Cache should remain unchanged');
      expect(cacheManager.messages.map((m) => m.id).toList(), [1, 2]);
    });
  });
}
