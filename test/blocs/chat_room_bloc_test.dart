import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

void main() {
  late MockChatRepository mockChatRepository;
  late MockWebSocketService mockWebSocketService;
  late MockAuthLocalDataSource mockAuthLocalDataSource;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockWebSocketService = MockWebSocketService();
    mockAuthLocalDataSource = MockAuthLocalDataSource();

    // AuthLocalDataSource mock 기본 설정
    when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);

    // WebSocketService mock 기본 설정
    when(() => mockWebSocketService.subscribeToChatRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.unsubscribeFromChatRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.messages).thenAnswer(
      (_) => const Stream<WebSocketChatMessage>.empty(),
    );
    when(() => mockWebSocketService.readEvents).thenAnswer(
      (_) => const Stream<WebSocketReadEvent>.empty(),
    );
    when(() => mockWebSocketService.typingEvents).thenAnswer(
      (_) => const Stream<WebSocketTypingEvent>.empty(),
    );
    when(() => mockWebSocketService.sendMessage(
          roomId: any(named: 'roomId'),
          senderId: any(named: 'senderId'),
          content: any(named: 'content'),
        )).thenReturn(null);
  });

  ChatRoomBloc createBloc() => ChatRoomBloc(
        mockChatRepository,
        mockWebSocketService,
        mockAuthLocalDataSource,
      );

  group('ChatRoomBloc', () {
    test('initial state is ChatRoomState with initial status', () {
      final bloc = createBloc();
      expect(bloc.state.status, ChatRoomStatus.initial);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.roomId, isNull);
    });

    group('ChatRoomOpened', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [loading, success] with messages when room opens',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (FakeEntities.messages, 123, true));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomOpened(1)),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.loading,
            roomId: 1,
            currentUserId: 1,
            messages: [],
          ),
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            currentUserId: 1,
            messages: FakeEntities.messages,
            nextCursor: 123,
            hasMore: true,
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.getMessages(1, size: 50)).called(1);
          verify(() => mockChatRepository.markAsRead(1)).called(1);
          verify(() => mockWebSocketService.subscribeToChatRoom(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [loading, failure] when getMessages fails',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenThrow(Exception('Failed to load messages'));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomOpened(1)),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.loading,
            roomId: 1,
            currentUserId: 1,
            messages: [],
          ),
          isA<ChatRoomState>().having(
            (s) => s.status,
            'status',
            ChatRoomStatus.failure,
          ),
        ],
      );
    });

    group('ChatRoomClosed', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'resets state when room is closed',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: FakeEntities.messages,
        ),
        act: (bloc) => bloc.add(const ChatRoomClosed()),
        expect: () => [const ChatRoomState()],
        verify: (_) {
          verify(() => mockWebSocketService.unsubscribeFromChatRoom(1)).called(1);
        },
      );
    });

    group('MessageSent', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [isSending=true, isSending=false] and sends via WebSocket when successful',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId())
              .thenAnswer((_) async => 42);
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(const MessageSent('안녕하세요!')),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [],
            isSending: true,
          ),
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [],
            isSending: false,
          ),
        ],
        verify: (_) {
          verify(() => mockAuthLocalDataSource.getUserId()).called(1);
          verify(() => mockWebSocketService.sendMessage(
                roomId: 1,
                senderId: 42,
                content: '안녕하세요!',
              )).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits error when userId is null',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(const MessageSent('안녕하세요!')),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [],
            isSending: true,
          ),
          isA<ChatRoomState>()
              .having((s) => s.isSending, 'isSending', false)
              .having((s) => s.errorMessage, 'errorMessage', '사용자 정보를 찾을 수 없습니다.'),
        ],
        verify: (_) {
          verify(() => mockAuthLocalDataSource.getUserId()).called(1);
          verifyNever(() => mockWebSocketService.sendMessage(
                roomId: any(named: 'roomId'),
                senderId: any(named: 'senderId'),
                content: any(named: 'content'),
              ));
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [isSending=true, isSending=false with error] when exception occurs',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId())
              .thenThrow(Exception('Failed to get user'));
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(const MessageSent('안녕하세요!')),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [],
            isSending: true,
          ),
          isA<ChatRoomState>()
              .having((s) => s.isSending, 'isSending', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when roomId is null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MessageSent('test')),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockAuthLocalDataSource.getUserId());
          verifyNever(() => mockWebSocketService.sendMessage(
                roomId: any(named: 'roomId'),
                senderId: any(named: 'senderId'),
                content: any(named: 'content'),
              ));
        },
      );
    });

    group('MessageReceived', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'adds message to list when received for current room',
        build: () => createBloc(),
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(MessageReceived(FakeEntities.textMessage)),
        expect: () => [
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [FakeEntities.textMessage],
          ),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'ignores message for different room',
        build: () => createBloc(),
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 2,
          messages: [],
        ),
        act: (bloc) => bloc.add(MessageReceived(FakeEntities.textMessage)), // roomId: 1
        expect: () => [],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'ignores duplicate message',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(MessageReceived(FakeEntities.textMessage)),
        expect: () => [],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'prepends new message to existing messages',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(MessageReceived(FakeEntities.imageMessage)),
        expect: () => [
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [FakeEntities.imageMessage, FakeEntities.textMessage],
          ),
        ],
      );
    });

    group('MessageDeleted', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'marks message as deleted',
        build: () {
          when(() => mockChatRepository.deleteMessage(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(const MessageDeleted(1)),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.messages.first.isDeleted,
            'isDeleted',
            true,
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.deleteMessage(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits error when delete fails',
        build: () {
          when(() => mockChatRepository.deleteMessage(any()))
              .thenThrow(Exception('Failed to delete'));
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(const MessageDeleted(1)),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('MessagesLoadMoreRequested', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'loads more messages when hasMore is true',
        build: () {
          when(() => mockChatRepository.getMessages(
                any(),
                size: any(named: 'size'),
                beforeMessageId: any(named: 'beforeMessageId'),
              )).thenAnswer((_) async => ([FakeEntities.imageMessage], null, false));
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
          nextCursor: 123,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const MessagesLoadMoreRequested()),
        expect: () => [
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 2)
              .having((s) => s.hasMore, 'hasMore', false),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when hasMore is false',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
          hasMore: false,
        ),
        act: (bloc) => bloc.add(const MessagesLoadMoreRequested()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockChatRepository.getMessages(
                any(),
                size: any(named: 'size'),
                beforeMessageId: any(named: 'beforeMessageId'),
              ));
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when nextCursor is null',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
          nextCursor: null,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const MessagesLoadMoreRequested()),
        expect: () => [],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when roomId is null',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: null,
          messages: [FakeEntities.textMessage],
          nextCursor: 123,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const MessagesLoadMoreRequested()),
        expect: () => [],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits error when load more fails',
        build: () {
          when(() => mockChatRepository.getMessages(
                any(),
                size: any(named: 'size'),
                beforeMessageId: any(named: 'beforeMessageId'),
              )).thenThrow(Exception('Failed to load more'));
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
          nextCursor: 123,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const MessagesLoadMoreRequested()),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('MessagesReadUpdated', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'decreases unreadCount only for my messages when other user reads',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId())
              .thenAnswer((_) async => 1);
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [
            // 내 메시지 (unreadCount 감소 대상)
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 1,
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
              unreadCount: 1,
            ),
            // 상대 메시지 (unreadCount 변경 없음)
            Message(
              id: 2,
              chatRoomId: 1,
              senderId: 2,
              content: 'Hello',
              createdAt: DateTime(2024, 1, 1),
              unreadCount: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 2)),
        expect: () => [
          isA<ChatRoomState>()
              .having((s) => s.messages[0].unreadCount, 'my msg unreadCount', 0)
              .having((s) => s.messages[1].unreadCount, 'other msg unreadCount', 1),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does not decrease unreadCount when I read my own messages',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 1,
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
              unreadCount: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const MessagesReadUpdated(userId: 1, lastReadMessageId: 1)),
        expect: () => [], // 내가 읽은 거면 변경 없음
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'only updates messages up to lastReadMessageId',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [
            Message(id: 3, chatRoomId: 1, senderId: 1, content: 'Third', createdAt: DateTime(2024, 1, 1, 12), unreadCount: 1),
            Message(id: 2, chatRoomId: 1, senderId: 1, content: 'Second', createdAt: DateTime(2024, 1, 1, 11), unreadCount: 1),
            Message(id: 1, chatRoomId: 1, senderId: 1, content: 'First', createdAt: DateTime(2024, 1, 1, 10), unreadCount: 1),
          ],
        ),
        act: (bloc) => bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 2)),
        expect: () => [
          isA<ChatRoomState>()
              .having((s) => s.messages[0].unreadCount, 'third msg unreadCount', 1) // id=3 > lastReadMessageId=2
              .having((s) => s.messages[1].unreadCount, 'second msg unreadCount', 0) // id=2 <= lastReadMessageId=2
              .having((s) => s.messages[2].unreadCount, 'first msg unreadCount', 0), // id=1 <= lastReadMessageId=2
        ],
      );
    });

    group('Auto read on message received', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'calls markAsRead when receiving message from other user',
        build: () {
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(MessageReceived(
          Message(
            id: 1,
            chatRoomId: 1,
            senderId: 2,
            content: 'Hi',
            createdAt: DateTime(2024, 1, 1),
          ),
        )),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does not call markAsRead when receiving my own message',
        build: () => createBloc(),
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(MessageReceived(
          Message(
            id: 1,
            chatRoomId: 1,
            senderId: 1,
            content: 'Hi',
            createdAt: DateTime(2024, 1, 1),
          ),
        )),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );
    });

    group('WebSocket integration', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'receives messages from WebSocket stream',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});

          final bloc = createBloc();

          // Schedule message emission after bloc processes ChatRoomOpened
          Future.delayed(const Duration(milliseconds: 100), () {
            messageController.add(WebSocketChatMessage(
              messageId: 999,
              senderId: 42,
              chatRoomId: 1,
              content: 'WebSocket message',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 22),
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          // Wait for WebSocket message to be processed
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.loading,
            roomId: 1,
            currentUserId: 1,
            messages: [],
          ),
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            currentUserId: 1,
            messages: [],
            nextCursor: null,
            hasMore: false,
          ),
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.content, 'content', 'WebSocket message'),
        ],
      );
    });
  });
}
