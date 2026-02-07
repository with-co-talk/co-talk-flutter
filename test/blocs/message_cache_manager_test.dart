import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/managers/message_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_repositories.dart';

class FakeMessage extends Fake implements Message {}

void main() {
  late MockChatRepository mockChatRepository;
  late MessageCacheManager cacheManager;

  setUpAll(() {
    // Register fallback value for Message
    registerFallbackValue(FakeMessage());
  });

  setUp(() {
    mockChatRepository = MockChatRepository();
    cacheManager = MessageCacheManager(mockChatRepository);

    // Set up default stub for saveMessageLocally
    when(() => mockChatRepository.saveMessageLocally(any()))
        .thenAnswer((_) async {});
  });

  group('MessageCacheManager - Equatable Compatibility', () {
    test('replacePendingMessageWithReal creates new list for Equatable compatibility', () {
      // Add a pending message
      final pendingMsg = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
        sendStatus: MessageSendStatus.pending,
        localId: 'local-1',
      );
      cacheManager.addPendingMessage(pendingMsg);

      // Capture current list reference
      final listBefore = cacheManager.messages;

      // Replace pending message with real message
      final realMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
      );
      final replaced = cacheManager.replacePendingMessageWithReal('Hello', realMsg);

      expect(replaced, isTrue);

      // CRITICAL: Must be a different list reference for Equatable to detect change
      expect(identical(cacheManager.messages, listBefore), isFalse,
          reason: 'replacePendingMessageWithReal must create a NEW list instance');

      // Verify the message was replaced correctly
      expect(cacheManager.messages.first.id, 100);
      expect(cacheManager.messages.first.sendStatus, MessageSendStatus.sent);
    });

    test('addMessage update path creates new list for Equatable compatibility', () async {
      // Add a message
      final originalMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
        sendStatus: MessageSendStatus.sent,
      );
      await cacheManager.addMessage(originalMsg);

      // Capture current list reference
      final listBefore = cacheManager.messages;

      // Update the same message (should trigger update path)
      final updatedMsg = originalMsg.copyWith(
        content: 'Hello Updated',
      );
      await cacheManager.addMessage(updatedMsg);

      // CRITICAL: Must be a different list reference for Equatable to detect change
      expect(identical(cacheManager.messages, listBefore), isFalse,
          reason: 'addMessage update path must create a NEW list instance');

      // Verify the message was updated correctly
      expect(cacheManager.messages.first.content, 'Hello Updated');
    });

    test('replacePendingMessageWithReal replaces correct pending message', () {
      // Add a pending message
      final pendingMsg = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
        sendStatus: MessageSendStatus.pending,
        localId: 'local-1',
      );
      cacheManager.addPendingMessage(pendingMsg);

      // Replace pending message with real message
      final realMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
      );
      final replaced = cacheManager.replacePendingMessageWithReal('Hello', realMsg);

      expect(replaced, isTrue);
      expect(cacheManager.messages.length, 1);
      expect(cacheManager.messages.first.id, 100);
      expect(cacheManager.messages.first.sendStatus, MessageSendStatus.sent);
      expect(cacheManager.messages.first.content, 'Hello');
    });

    test('replacePendingMessageWithReal returns false if no pending message found', () {
      final realMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
      );
      final replaced = cacheManager.replacePendingMessageWithReal('Hello', realMsg);

      expect(replaced, isFalse);
    });

    test('replacePendingMessageWithReal replaces oldest pending message (FIFO)', () {
      final now = DateTime.now();

      // Add multiple pending messages with same content
      final pendingMsg1 = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: now,
        sendStatus: MessageSendStatus.pending,
        localId: 'local-1',
      );
      final pendingMsg2 = Message(
        id: -2,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: now.add(const Duration(seconds: 5)),
        sendStatus: MessageSendStatus.pending,
        localId: 'local-2',
      );

      cacheManager.addPendingMessage(pendingMsg1);
      cacheManager.addPendingMessage(pendingMsg2);

      // Replace - should select the oldest (pendingMsg1)
      final realMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: now.add(const Duration(seconds: 2)),
      );
      final replaced = cacheManager.replacePendingMessageWithReal('Hello', realMsg);

      expect(replaced, isTrue);
      expect(cacheManager.messages.length, 2);

      // The oldest pending message should be replaced
      // Since messages are added at the beginning, the oldest is at the end
      expect(cacheManager.messages.last.id, 100);
      expect(cacheManager.messages.last.sendStatus, MessageSendStatus.sent);

      // The newer pending message should still be pending
      expect(cacheManager.messages.first.id, -2);
      expect(cacheManager.messages.first.sendStatus, MessageSendStatus.pending);
    });

    test('addMessage adds new message at the beginning', () async {
      final msg1 = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 42,
        content: 'First',
        createdAt: DateTime.now(),
      );
      await cacheManager.addMessage(msg1);

      final msg2 = Message(
        id: 2,
        chatRoomId: 1,
        senderId: 42,
        content: 'Second',
        createdAt: DateTime.now(),
      );
      await cacheManager.addMessage(msg2);

      expect(cacheManager.messages.length, 2);
      expect(cacheManager.messages.first.id, 2);
      expect(cacheManager.messages.last.id, 1);
    });
  });
}
