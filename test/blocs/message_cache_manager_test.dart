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
      cacheManager.addMessage(originalMsg);

      // Capture current list reference
      final listBefore = cacheManager.messages;

      // Update the same message (should trigger update path)
      final updatedMsg = originalMsg.copyWith(
        content: 'Hello Updated',
      );
      cacheManager.addMessage(updatedMsg);

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

    test('replacePendingMessageWithReal preserves localId so list-key stays stable (이중 애니메이션 방지)', () {
      // Pending 메시지가 확정 메시지로 교체될 때 localId 가 유지돼야
      // _keyOf 가 동일한 키를 반환 → MessageEntryTracker 가 재애니메이션 방지
      final pendingMsg = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
        sendStatus: MessageSendStatus.pending,
        localId: 'local-uuid-1',
      );
      cacheManager.addPendingMessage(pendingMsg);

      final realMsg = Message(
        id: 200,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: DateTime.now(),
      );
      final replaced = cacheManager.replacePendingMessageWithReal('Hello', realMsg);

      expect(replaced, isTrue);
      final confirmed = cacheManager.messages.first;
      expect(confirmed.id, 200);
      expect(confirmed.sendStatus, MessageSendStatus.sent);
      // localId 는 반드시 보존돼야 한다 — 이것이 핵심 regression guard
      expect(confirmed.localId, 'local-uuid-1',
          reason: 'localId must be carried over so the list key stays stable '
              'and the bubble does not animate a second time');
    });

    // ── H1: clientMessageId 기반 정확 매칭 ──────────────────────────────
    test(
        'echo with matching clientMessageId replaces the CORRECT pending '
        'message even when two pending messages share identical content', () {
      final now = DateTime.now();

      // 동일 내용("ㅇㅇ")의 pending 메시지 2개 (실제 사용자가 연속 전송하는 상황).
      final pending1 = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'ㅇㅇ',
        createdAt: now,
        sendStatus: MessageSendStatus.sending,
        localId: 'cmid-1',
      );
      final pending2 = Message(
        id: -2,
        chatRoomId: 1,
        senderId: 42,
        content: 'ㅇㅇ',
        createdAt: now.add(const Duration(seconds: 1)),
        sendStatus: MessageSendStatus.sending,
        localId: 'cmid-2',
      );
      cacheManager.addPendingMessage(pending1);
      cacheManager.addPendingMessage(pending2);

      // 서버 echo가 두 번째 메시지(cmid-2)의 clientMessageId를 되돌려준다.
      // convertToMessage가 이를 localId 슬롯에 담는다.
      final echo = Message(
        id: 500,
        chatRoomId: 1,
        senderId: 42,
        content: 'ㅇㅇ',
        // FIFO content 매칭이라면 가장 오래된 cmid-1을 골랐겠지만,
        // clientMessageId 정확 매칭이면 cmid-2가 교체돼야 한다.
        createdAt: now.add(const Duration(seconds: 3)),
        localId: 'cmid-2',
      );
      final replaced =
          cacheManager.replacePendingMessageWithReal('ㅇㅇ', echo);

      expect(replaced, isTrue);
      expect(cacheManager.messages.length, 2);

      // cmid-2가 확정(sent, id=500)으로 교체됐는지 정확히 검증.
      final confirmed = cacheManager.messages
          .firstWhere((m) => m.localId == 'cmid-2');
      expect(confirmed.id, 500);
      expect(confirmed.sendStatus, MessageSendStatus.sent);

      // cmid-1은 그대로 미확정(여전히 로컬 임시 ID)으로 남아 있어야 한다.
      final stillPending = cacheManager.messages
          .firstWhere((m) => m.localId == 'cmid-1');
      expect(stillPending.id, -1);
      expect(stillPending.isPending, isTrue);
    });

    test(
        'falls back to content+window matching when echo lacks clientMessageId',
        () {
      final now = DateTime.now();
      final pending = Message(
        id: -1,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: now,
        sendStatus: MessageSendStatus.sending,
        localId: 'cmid-1',
      );
      cacheManager.addPendingMessage(pending);

      // 백엔드 미지원: echo에 clientMessageId(localId)가 없다.
      final echo = Message(
        id: 600,
        chatRoomId: 1,
        senderId: 42,
        content: 'Hello',
        createdAt: now.add(const Duration(seconds: 2)),
        // localId 없음 → fallback 경로
      );
      final replaced =
          cacheManager.replacePendingMessageWithReal('Hello', echo);

      expect(replaced, isTrue, reason: 'fallback content match should succeed');
      final confirmed = cacheManager.messages.first;
      expect(confirmed.id, 600);
      expect(confirmed.sendStatus, MessageSendStatus.sent);
      // fallback이어도 로컬 localId는 보존된다.
      expect(confirmed.localId, 'cmid-1');
    });

    test('addMessage adds new message at the beginning', () async {
      final msg1 = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 42,
        content: 'First',
        createdAt: DateTime.now(),
      );
      cacheManager.addMessage(msg1);

      final msg2 = Message(
        id: 2,
        chatRoomId: 1,
        senderId: 42,
        content: 'Second',
        createdAt: DateTime.now(),
      );
      cacheManager.addMessage(msg2);

      expect(cacheManager.messages.length, 2);
      expect(cacheManager.messages.first.id, 2);
      expect(cacheManager.messages.last.id, 1);
    });
  });
}
