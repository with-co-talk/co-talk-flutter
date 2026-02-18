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
