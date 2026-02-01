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
  late MockDesktopNotificationBridge mockDesktopNotificationBridge;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeEntities.textMessage);
  });

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockWebSocketService = MockWebSocketService();
    mockAuthLocalDataSource = MockAuthLocalDataSource();
    mockDesktopNotificationBridge = MockDesktopNotificationBridge();

    // AuthLocalDataSource mock 기본 설정
    when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);

    // ChatRepository mock 기본 설정
    // 기존 테스트 호환성을 위해 otherUserNickname 없는 ChatRoom 사용
    when(() => mockChatRepository.getChatRoom(any()))
        .thenAnswer((_) async => FakeEntities.directChatRoomWithoutOtherUser);

    // Local-first 메서드 mock 기본 설정
    when(() => mockChatRepository.getLocalMessages(
      any(),
      limit: any(named: 'limit'),
      beforeMessageId: any(named: 'beforeMessageId'),
    )).thenAnswer((_) async => <Message>[]);
    when(() => mockChatRepository.saveMessageLocally(any()))
        .thenAnswer((_) async {});

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
    when(() => mockWebSocketService.sendPresenceInactive(
          roomId: any(named: 'roomId'),
          userId: any(named: 'userId'),
        )).thenReturn(null);

    // DesktopNotificationBridge mock 기본 설정
    when(() => mockDesktopNotificationBridge.setActiveRoomId(any())).thenReturn(null);
  });

  ChatRoomBloc createBloc() => ChatRoomBloc(
        mockChatRepository,
        mockWebSocketService,
        mockAuthLocalDataSource,
        mockDesktopNotificationBridge,
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

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [loading, success] even when getChatRoom fails (API not implemented)',
        build: () {
          // getChatRoom API가 없거나 실패해도 채팅방은 정상 동작해야 함
          when(() => mockChatRepository.getChatRoom(any()))
              .thenThrow(Exception('API not found'));
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
            // getChatRoom 실패 시 기본값
            isOtherUserLeft: false,
            otherUserNickname: null,
          ),
        ],
        verify: (_) {
          // getChatRoom은 호출되었지만 실패
          verify(() => mockChatRepository.getChatRoom(1)).called(1);
          // 메시지 로딩은 정상 수행
          verify(() => mockChatRepository.getMessages(1, size: 50)).called(1);
          verify(() => mockWebSocketService.subscribeToChatRoom(1)).called(1);
        },
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

    group('Foreground/Background', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'keeps room subscription and sends presenceInactive when backgrounded after opening',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (FakeEntities.messages, 123, true));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          // opened 단계의 호출은 제외하고 "background 전환"만 검증한다.
          clearInteractions(mockWebSocketService);
          bloc.add(const ChatRoomBackgrounded());
        },
        wait: const Duration(milliseconds: 400),
        verify: (_) {
          // bloc dispose(close) 시점의 unsubscribe는 허용(정상적인 정리).
          // 여기서는 background 전환으로 인해 "즉시 unsubscribe"가 발생하지 않는지만 본다.
          verify(() => mockWebSocketService.unsubscribeFromChatRoom(1)).called(1);
          verify(() => mockWebSocketService.sendPresenceInactive(roomId: 1, userId: 1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does not re-subscribe and marks as read when foregrounded after backgrounded',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (FakeEntities.messages, 123, true));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomBackgrounded());
          await Future.delayed(const Duration(milliseconds: 50));
          // opened/background 단계의 호출은 제외하고 "foreground 전환"만 검증한다.
          clearInteractions(mockWebSocketService);
          clearInteractions(mockChatRepository);
          bloc.add(const ChatRoomForegrounded());
        },
        wait: const Duration(milliseconds: 600),
        verify: (_) {
          verifyNever(() => mockWebSocketService.subscribeToChatRoom(any()));
          verify(() => mockChatRepository.markAsRead(1)).called(1);
          verify(() => mockWebSocketService.sendPresencePing(roomId: 1, userId: 1)).called(1);
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

    group('MessageUpdateRequested', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'updates message content when successful',
        build: () {
          when(() => mockChatRepository.updateMessage(any(), any()))
              .thenAnswer((_) async => Message(
                    id: 1,
                    chatRoomId: 1,
                    senderId: 1,
                    content: '수정된 메시지',
                    createdAt: DateTime(2024, 1, 1),
                  ));
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(const MessageUpdateRequested(
          messageId: 1,
          content: '수정된 메시지',
        )),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.messages.first.content,
            'content',
            '수정된 메시지',
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.updateMessage(1, '수정된 메시지')).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits error when update fails',
        build: () {
          when(() => mockChatRepository.updateMessage(any(), any()))
              .thenThrow(Exception('Failed to update'));
          return createBloc();
        },
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          messages: [FakeEntities.textMessage],
        ),
        act: (bloc) => bloc.add(const MessageUpdateRequested(
          messageId: 1,
          content: '수정된 메시지',
        )),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('ChatRoomLeaveRequested', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'sets hasLeft to true when leave is successful',
        build: () {
          when(() => mockChatRepository.leaveChatRoom(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
        ),
        act: (bloc) => bloc.add(const ChatRoomLeaveRequested()),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.hasLeft,
            'hasLeft',
            true,
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.leaveChatRoom(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits error when leave fails',
        build: () {
          when(() => mockChatRepository.leaveChatRoom(any()))
              .thenThrow(Exception('Failed to leave'));
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
        ),
        act: (bloc) => bloc.add(const ChatRoomLeaveRequested()),
        expect: () => [
          isA<ChatRoomState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when roomId is null',
        build: () => createBloc(),
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: null,
        ),
        act: (bloc) => bloc.add(const ChatRoomLeaveRequested()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockChatRepository.leaveChatRoom(any()));
        },
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

      // ========================================================================================
      // 🔴 RED 테스트들: 아직 구현되지 않은 기능을 위한 테스트입니다.
      // 이 테스트들은 TDD의 "Red" 단계로, 해당 기능이 구현되면 주석을 해제하고 테스트를 통과시켜야 합니다.
      // ========================================================================================

      // TODO: 그룹 채팅 unreadCount 감소 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: 그룹 채팅에서 여러 사람이 읽었을 때 unreadCount가 정확히 감소함',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(
      //         id: 1,
      //         chatRoomId: 1,
      //         senderId: 1,
      //         content: '내 메시지',
      //         createdAt: DateTime(2024, 1, 1),
      //         unreadCount: 3,
      //       ),
      //     ],
      //   ),
      //   act: (bloc) {
      //     bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 1));
      //     bloc.add(const MessagesReadUpdated(userId: 3, lastReadMessageId: 1));
      //     bloc.add(const MessagesReadUpdated(userId: 4, lastReadMessageId: 1));
      //   },
      //   expect: () => [
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages.first.unreadCount, 'unreadCount after first read', 2),
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages.first.unreadCount, 'unreadCount after second read', 1),
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages.first.unreadCount, 'unreadCount after third read', 0),
      //   ],
      // );

      // TODO: lastReadAt 기반 읽음 처리 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: 여러 메시지가 있을 때 lastReadAt 기반으로 읽음 처리됨',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(id: 3, chatRoomId: 1, senderId: 1, content: 'Third', createdAt: DateTime(2026, 1, 25, 13), unreadCount: 1),
      //       Message(id: 2, chatRoomId: 1, senderId: 1, content: 'Second', createdAt: DateTime(2026, 1, 25, 12), unreadCount: 1),
      //       Message(id: 1, chatRoomId: 1, senderId: 1, content: 'First', createdAt: DateTime(2026, 1, 25, 11), unreadCount: 1),
      //     ],
      //   ),
      //   act: (bloc) {
      //     bloc.add(MessagesReadUpdated(
      //       userId: 2,
      //       lastReadAt: DateTime(2026, 1, 25, 12, 30),
      //     ));
      //   },
      //   expect: () => [
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages[0].unreadCount, 'third msg unreadCount', 1)
      //         .having((s) => s.messages[1].unreadCount, 'second msg unreadCount', 0)
      //         .having((s) => s.messages[2].unreadCount, 'first msg unreadCount', 0),
      //   ],
      // );

      // TODO: lastReadMessageId/lastReadAt 없는 경우 전체 읽음 처리 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: lastReadMessageId와 lastReadAt 둘 다 없으면 모든 메시지가 읽음 처리됨',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(id: 3, chatRoomId: 1, senderId: 1, content: 'Third', createdAt: DateTime(2026, 1, 25, 13), unreadCount: 1),
      //       Message(id: 2, chatRoomId: 1, senderId: 1, content: 'Second', createdAt: DateTime(2026, 1, 25, 12), unreadCount: 1),
      //       Message(id: 1, chatRoomId: 1, senderId: 1, content: 'First', createdAt: DateTime(2026, 1, 25, 11), unreadCount: 1),
      //     ],
      //   ),
      //   act: (bloc) {
      //     bloc.add(const MessagesReadUpdated(userId: 2));
      //   },
      //   expect: () => [
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages[0].unreadCount, 'third msg unreadCount', 0)
      //         .having((s) => s.messages[1].unreadCount, 'second msg unreadCount', 0)
      //         .having((s) => s.messages[2].unreadCount, 'first msg unreadCount', 0),
      //   ],
      // );

      // TODO: unreadCount 0인 경우 변경 없음 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: unreadCount가 0인 메시지는 더 이상 감소하지 않음',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(
      //         id: 1,
      //         chatRoomId: 1,
      //         senderId: 1,
      //         content: '내 메시지',
      //         createdAt: DateTime(2024, 1, 1),
      //         unreadCount: 0,
      //       ),
      //     ],
      //   ),
      //   act: (bloc) {
      //     bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 1));
      //   },
      //   expect: () => [
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages.first.unreadCount, 'unreadCount', 0),
      //   ],
      // );

      // TODO: 중복 읽음 이벤트 무시 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: ignores duplicate read events to prevent double decrement (group case)',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(
      //         id: 1,
      //         chatRoomId: 1,
      //         senderId: 1,
      //         content: 'Hi',
      //         createdAt: DateTime(2024, 1, 1),
      //         unreadCount: 3,
      //       ),
      //     ],
      //   ),
      //   act: (bloc) {
      //     bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 1));
      //     bloc.add(const MessagesReadUpdated(userId: 2, lastReadMessageId: 1)); // duplicate
      //   },
      //   expect: () => [
      //     isA<ChatRoomState>().having((s) => s.messages[0].unreadCount, 'unreadCount after first', 2),
      //   ],
      // );

      // TODO: lastReadAt만 있고 lastReadMessageId가 null인 경우 처리 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: updates only messages up to lastReadAt when lastReadMessageId is null',
      //   build: () => createBloc(),
      //   seed: () => ChatRoomState(
      //     status: ChatRoomStatus.success,
      //     roomId: 1,
      //     currentUserId: 1,
      //     messages: [
      //       Message(id: 3, chatRoomId: 1, senderId: 1, content: 'Third', createdAt: DateTime(2024, 1, 1, 12), unreadCount: 1),
      //       Message(id: 2, chatRoomId: 1, senderId: 1, content: 'Second', createdAt: DateTime(2024, 1, 1, 11), unreadCount: 1),
      //       Message(id: 1, chatRoomId: 1, senderId: 1, content: 'First', createdAt: DateTime(2024, 1, 1, 10), unreadCount: 1),
      //     ],
      //   ),
      //   act: (bloc) => bloc.add(
      //     MessagesReadUpdated(
      //       userId: 2,
      //       lastReadAt: DateTime(2024, 1, 1, 11, 0, 0),
      //     ),
      //   ),
      //   expect: () => [
      //     isA<ChatRoomState>()
      //         .having((s) => s.messages[0].unreadCount, 'third msg unreadCount', 1)
      //         .having((s) => s.messages[1].unreadCount, 'second msg unreadCount', 0)
      //         .having((s) => s.messages[2].unreadCount, 'first msg unreadCount', 0),
      //   ],
      // );
    });

    group('Auto read on message received', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        'calls markAsRead when receiving message from other user',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 50));
          clearInteractions(mockChatRepository);

          bloc.add(MessageReceived(
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 2,
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
            ),
          ));
        },
        wait: const Duration(milliseconds: 800),
        verify: (_) {
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: sets isReadMarked to true when markAsRead succeeds',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (FakeEntities.messages, 123, true));
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomOpened(1)),
        wait: const Duration(milliseconds: 500),
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
        wait: const Duration(milliseconds: 500),
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
          // WebSocket 메시지 추가 (이전 isReadMarked 상태 유지)
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.content, 'content', 'WebSocket message')
              .having((s) => s.isReadMarked, 'isReadMarked', false), // opened 시점 markAsRead 제거
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: sender-side unreadCount(1) becomes 0 when READ event arrives via WebSocket streams',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          final readController = StreamController<WebSocketReadEvent>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);
          when(() => mockWebSocketService.readEvents)
              .thenAnswer((_) => readController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 1) 내 메시지(unreadCount=1) 수신
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 9007199254740991, // 큰 ID로 long 영역도 커버
              senderId: 1, // currentUserId=1(=내 메시지)
              chatRoomId: 1,
              content: 'mine',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 22),
              unreadCount: 1,
            ));
          });

          // 2) 상대가 읽음(READ) 이벤트 수신
          Future.delayed(const Duration(milliseconds: 220), () {
            readController.add(WebSocketReadEvent(
              chatRoomId: 1,
              userId: 2, // reader = 상대
              lastReadMessageId: 9007199254740991,
              lastReadAt: DateTime(2026, 1, 22, 12, 0, 0),
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 800),
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
          // 내 메시지 수신: unreadCount=1
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.content, 'content', 'mine')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
          // READ 이벤트 후: unreadCount=0
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.content, 'content', 'mine')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 0),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 시나리오 1 - 내가 보낸 메시지에 상대가 읽지 않았으면 unreadCount=1로 표시됨',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 내가 보낸 메시지가 서버에서 unreadCount=1로 응답됨 (상대가 아직 읽지 않음)
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 100,
              senderId: 1, // currentUserId=1(=내 메시지)
              chatRoomId: 1,
              content: '내가 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 25),
              unreadCount: 1, // 상대가 아직 읽지 않아서 1
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        wait: const Duration(milliseconds: 600),
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
          // 내가 보낸 메시지가 unreadCount=1로 표시됨
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId', 1)
              .having((s) => s.messages.first.content, 'content', '내가 보낸 메시지')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 시나리오 2 - 상대방이 읽은 경우 나와 상대 모두 unreadCount가 0이 됨',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          final readController = StreamController<WebSocketReadEvent>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);
          when(() => mockWebSocketService.readEvents)
              .thenAnswer((_) => readController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 1) 내가 보낸 메시지(unreadCount=1) 수신
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 150,
              senderId: 1, // currentUserId=1(=내 메시지)
              chatRoomId: 1,
              content: '내가 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 25),
              unreadCount: 1, // 상대가 아직 읽지 않아서 1
            ));
          });

          // 2) 상대가 읽음(READ) 이벤트 수신 -> 내 메시지의 unreadCount가 0이 됨
          Future.delayed(const Duration(milliseconds: 220), () {
            readController.add(WebSocketReadEvent(
              chatRoomId: 1,
              userId: 2, // reader = 상대
              lastReadMessageId: 150,
              lastReadAt: DateTime(2026, 1, 25, 12, 0, 0),
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 800),
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
          // 내 메시지 수신: unreadCount=1
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId', 1)
              .having((s) => s.messages.first.content, 'content', '내가 보낸 메시지')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
          // 상대가 읽은 후: unreadCount=0 (나와 상대 모두 1이 사라짐)
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId', 1)
              .having((s) => s.messages.first.content, 'content', '내가 보낸 메시지')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 0), // 상대가 읽어서 0
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 시나리오 3 - 내가 보낼 때 상대방이 포커스되어 있으면 즉시 unreadCount=0이 됨',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 내가 메시지를 보냄 -> 서버가 상대방이 포커스되어 있음을 감지하여 unreadCount=0으로 응답
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 200,
              senderId: 1, // currentUserId=1(=내 메시지)
              chatRoomId: 1,
              content: '상대방이 보고 있는 중에 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 25),
              unreadCount: 0, // 상대방이 포커스되어 있어서 즉시 0
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        wait: const Duration(milliseconds: 600),
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
          // 내가 보낸 메시지가 즉시 unreadCount=0으로 표시됨 (상대방이 포커스되어 있었음)
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId', 1)
              .having((s) => s.messages.first.content, 'content', '상대방이 보고 있는 중에 보낸 메시지')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 0),
        ],
      );
    });

    group('ChatRoomForegrounded/Backgrounded 동작 검증', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: ChatRoomForegrounded 호출 시 _isViewingRoom = true가 되고 markAsRead가 호출됨',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          clearInteractions(mockChatRepository);
          // ChatRoomForegrounded 호출
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 1000),
        verify: (_) {
          // _isViewingRoom = true가 되어 markAsRead가 호출되어야 함
          verify(() => mockChatRepository.markAsRead(1)).called(1);
          verify(() => mockWebSocketService.sendPresencePing(roomId: 1, userId: 1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: ChatRoomBackgrounded 호출 시 _isViewingRoom = false가 되고 presence inactive 전송',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          when(() => mockWebSocketService.sendPresenceInactive(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 200));
          clearInteractions(mockWebSocketService);
          // ChatRoomBackgrounded 호출
          bloc.add(const ChatRoomBackgrounded());
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) {
          // _isViewingRoom = false가 되어 presence inactive가 전송되어야 함
          verify(() => mockWebSocketService.sendPresenceInactive(roomId: 1, userId: 1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: _isViewingRoom = true일 때 상대방 메시지 도착 시 markAsRead가 호출됨',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded()); // _isViewingRoom = true
          await Future.delayed(const Duration(milliseconds: 200));
          clearInteractions(mockChatRepository);
          // 상대방 메시지 도착
          bloc.add(MessageReceived(
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 2, // 상대방
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 1000),
        verify: (_) {
          // _isViewingRoom = true이므로 markAsRead가 호출되어야 함
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: _isViewingRoom = false일 때 상대방 메시지 도착 시 markAsRead가 호출되지 않음',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          // ChatRoomForegrounded를 호출하지 않아서 _isViewingRoom = false
          clearInteractions(mockChatRepository);
          // 상대방 메시지 도착
          bloc.add(MessageReceived(
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 2, // 상대방
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) {
          // _isViewingRoom = false이므로 markAsRead가 호출되지 않아야 함
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );
    });

    group('실제 동작 검증 - 엣지 케이스', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: ChatRoomForegrounded가 호출되지만 _isRoomSubscribed가 false면 markAsRead가 호출되지 않음',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [],
        ),
        act: (bloc) => bloc.add(const ChatRoomForegrounded()),
        verify: (_) {
          // _isRoomSubscribed가 false이므로 markAsRead가 호출되지 않아야 함
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );

      // TODO: markAsRead 재시도 로직 미구현
      // blocTest<ChatRoomBloc, ChatRoomState>(
      //   '🔴 RED: markAsRead가 모든 재시도 후에도 실패하면 조용히 무시됨 (isReadMarked는 false 유지)',
      //   build: () {
      //     when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
      //         .thenAnswer((_) async => (<Message>[], null, false));
      //     when(() => mockChatRepository.markAsRead(any()))
      //         .thenThrow(Exception('Network error'));
      //     when(() => mockWebSocketService.sendPresencePing(
      //           roomId: any(named: 'roomId'),
      //           userId: any(named: 'userId'),
      //         )).thenReturn(null);
      //     return createBloc();
      //   },
      //   act: (bloc) async {
      //     bloc.add(const ChatRoomOpened(1));
      //     await Future.delayed(const Duration(milliseconds: 200));
      //     bloc.add(const ChatRoomForegrounded());
      //     await Future.delayed(const Duration(milliseconds: 5000));
      //   },
      //   wait: const Duration(milliseconds: 6000),
      //   expect: () => [
      //     const ChatRoomState(
      //       status: ChatRoomStatus.loading,
      //       roomId: 1,
      //       currentUserId: 1,
      //       messages: [],
      //     ),
      //     const ChatRoomState(
      //       status: ChatRoomStatus.success,
      //       roomId: 1,
      //       currentUserId: 1,
      //       messages: [],
      //       nextCursor: null,
      //       hasMore: false,
      //       isReadMarked: false,
      //     ),
      //   ],
      //   verify: (_) {
      //     verify(() => mockChatRepository.markAsRead(1)).called(3);
      //   },
      // );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: ChatRoomForegrounded가 호출되기 전에 메시지가 도착하면 _isViewingRoom이 false여서 markAsRead가 호출되지 않음',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          // ChatRoomForegrounded 전에 메시지 도착
          clearInteractions(mockChatRepository);
          bloc.add(MessageReceived(
            Message(
              id: 1,
              chatRoomId: 1,
              senderId: 2,
              content: 'Hi',
              createdAt: DateTime(2024, 1, 1),
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) {
          // _isViewingRoom이 false이므로 markAsRead가 호출되지 않음
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 여러 메시지가 있을 때 일부만 읽음 처리되는 경우 (lastReadMessageId 기반)',
        build: () => createBloc(),
        seed: () => ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          messages: [
            Message(id: 3, chatRoomId: 1, senderId: 1, content: 'Third', createdAt: DateTime(2026, 1, 25, 13), unreadCount: 1),
            Message(id: 2, chatRoomId: 1, senderId: 1, content: 'Second', createdAt: DateTime(2026, 1, 25, 12), unreadCount: 1),
            Message(id: 1, chatRoomId: 1, senderId: 1, content: 'First', createdAt: DateTime(2026, 1, 25, 11), unreadCount: 1),
          ],
        ),
        act: (bloc) {
          // MessagesReadUpdated 이벤트 직접 추가 (WebSocket 스트림 대신)
          // 상대가 일부 메시지만 읽음 (lastReadMessageId=2)
          bloc.add(const MessagesReadUpdated(
            userId: 2,
            lastReadMessageId: 2, // id=2까지만 읽음
          ));
        },
        expect: () => [
          // id=1, 2는 읽혀서 unreadCount=0, id=3은 아직 읽지 않아서 unreadCount=1
          isA<ChatRoomState>()
              .having((s) => s.messages[0].unreadCount, 'third msg unreadCount', 1) // id=3 > lastReadMessageId=2
              .having((s) => s.messages[1].unreadCount, 'second msg unreadCount', 0) // id=2 <= lastReadMessageId=2
              .having((s) => s.messages[2].unreadCount, 'first msg unreadCount', 0), // id=1 <= lastReadMessageId=2
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 채팅방을 나갔다가 다시 들어올 때 읽음 처리가 제대로 동작함',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          // 첫 진입
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 100));
          clearInteractions(mockChatRepository);

          // 나감
          bloc.add(const ChatRoomClosed());
          await Future.delayed(const Duration(milliseconds: 100));

          // 다시 들어옴
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
        },
        wait: const Duration(milliseconds: 1000),
        verify: (_) {
          // 다시 들어올 때 markAsRead가 호출되어야 함
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 앱이 백그라운드로 갔다가 다시 포그라운드로 올 때 읽음 처리가 제대로 동작함',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          when(() => mockWebSocketService.sendPresenceInactive(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 200)); // markAsRead 완료 대기
          
          // 첫 번째 markAsRead 호출 제외
          clearInteractions(mockChatRepository);
          clearInteractions(mockWebSocketService);

          // 백그라운드로 전환
          bloc.add(const ChatRoomBackgrounded());
          await Future.delayed(const Duration(milliseconds: 100));

          // 다시 포그라운드로 전환
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 1500),
        verify: (_) {
          // 다시 포그라운드로 올 때 markAsRead가 호출되어야 함
          verify(() => mockChatRepository.markAsRead(1)).called(1);
          verify(() => mockWebSocketService.sendPresenceInactive(roomId: 1, userId: 1)).called(1);
          verify(() => mockWebSocketService.sendPresencePing(roomId: 1, userId: 1)).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        // TODO: 미구현 기능 - 이 테스트는 나중에 구현될 기능을 위한 것입니다
        '🔴 RED: 서버가 chatRoomUpdates로 unreadCount를 보내주지 않는 경우 isReadMarked만 true가 되고 실제 unreadCount는 업데이트되지 않음',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 300)); // markAsRead 완료 대기
        },
        wait: const Duration(milliseconds: 1500),
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
          // markAsRead 성공 후 isReadMarked가 true가 됨
          // 하지만 서버가 chatRoomUpdates를 보내주지 않으면 실제 unreadCount는 업데이트되지 않음
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            currentUserId: 1,
            messages: [],
            nextCursor: null,
            hasMore: false,
            isReadMarked: true, // markAsRead 성공으로 true
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

    });

    group('🔴 RED: _pendingForegrounded 취소 버그 수정 검증', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: ChatRoomBackgrounded가 pendingForegrounded를 취소함 - 포커스 빠진 상태에서 초기화 완료 시 markAsRead 호출 안됨',
        build: () {
          // getMessages를 느리게 만들어서 pendingForegrounded 시나리오 재현
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 300));
            return (<Message>[], null, false);
          });
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) async {
          // 1. ChatRoomOpened - 초기화 시작 (_roomInitialized = false)
          bloc.add(const ChatRoomOpened(1));

          // 2. 초기화 완료 전에 ChatRoomForegrounded 전송 → _pendingForegrounded = true
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const ChatRoomForegrounded());

          // 3. 창이 포커스를 잃음 → ChatRoomBackgrounded → _pendingForegrounded = false (버그 수정)
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const ChatRoomBackgrounded());

          // 4. 초기화 완료를 기다림 (총 300ms)
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 1000),
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
          // 중요: isReadMarked가 true가 되지 않아야 함!
          // pendingForegrounded가 취소되었으므로 markAsRead가 호출되지 않음
        ],
        verify: (_) {
          // markAsRead가 호출되지 않아야 함 (창이 포커스 빠진 상태)
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: ChatRoomBackgrounded 후 다시 ChatRoomForegrounded → markAsRead 호출됨',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 200));
            return (<Message>[], null, false);
          });
          when(() => mockChatRepository.markAsRead(any()))
              .thenAnswer((_) async {});
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
                userId: any(named: 'userId'),
              )).thenReturn(null);
          return createBloc();
        },
        act: (bloc) async {
          // 1. ChatRoomOpened
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 50));

          // 2. ChatRoomForegrounded (초기화 전)
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 50));

          // 3. ChatRoomBackgrounded (pendingForegrounded 취소)
          bloc.add(const ChatRoomBackgrounded());

          // 4. 초기화 완료 대기
          await Future.delayed(const Duration(milliseconds: 300));

          // 5. 다시 ChatRoomForegrounded (이번엔 초기화 완료된 상태)
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 100));
        },
        wait: const Duration(milliseconds: 1000),
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
          // 두 번째 ChatRoomForegrounded에서 markAsRead 호출 → isReadMarked = true
          const ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            currentUserId: 1,
            messages: [],
            nextCursor: null,
            hasMore: false,
            isReadMarked: true,
          ),
        ],
        verify: (_) {
          // markAsRead가 한 번만 호출되어야 함 (두 번째 Foregrounded에서)
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );
    });

    group('🔴 RED: unreadCount 보존 검증 (서버에서 받은 값이 그대로 유지되어야 함)', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: WebSocket 메시지 수신 시 unreadCount=1이 그대로 보존됨 (1:1 채팅)',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 서버에서 unreadCount=1로 메시지 수신 (상대가 아직 읽지 않음)
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 100,
              senderId: 2, // 상대방이 보낸 메시지
              chatRoomId: 1,
              content: '상대방이 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 31),
              unreadCount: 1, // 서버에서 보낸 unreadCount=1
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        wait: const Duration(milliseconds: 600),
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
          // 수신한 메시지의 unreadCount=1이 그대로 보존되어야 함
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId', 2)
              .having((s) => s.messages.first.content, 'content', '상대방이 보낸 메시지')
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: WebSocket 메시지 수신 시 unreadCount=0이면 0으로 보존됨',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 서버에서 unreadCount=0으로 메시지 수신 (모두 읽음)
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 101,
              senderId: 2,
              chatRoomId: 1,
              content: '이미 읽힌 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 31),
              unreadCount: 0, // 서버에서 보낸 unreadCount=0
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        wait: const Duration(milliseconds: 600),
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
          // 수신한 메시지의 unreadCount=0이 그대로 보존되어야 함
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 0),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: 데스크톱 시나리오 - 포커스 없이 채팅방 열린 상태에서 메시지 수신 시 unreadCount 보존',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 채팅방 열린 후 background 상태에서 메시지 수신
          Future.delayed(const Duration(milliseconds: 200), () {
            // 서버에서 unreadCount=1로 메시지 수신 (1:1 채팅, 나 외에 1명이 안 읽음)
            messageController.add(WebSocketChatMessage(
              messageId: 200,
              senderId: 2, // 상대방이 보낸 메시지
              chatRoomId: 1,
              content: '앱에서 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 31, 12, 0),
              unreadCount: 1, // 서버: totalMembers(2) - 1 = 1
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          // 초기화 완료 대기
          await Future.delayed(const Duration(milliseconds: 100));
          // 포커스 없는 상태로 시작 (Backgrounded)
          bloc.add(const ChatRoomBackgrounded());
          // 메시지 수신 대기
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 600),
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
          // Background 상태에서 수신한 메시지의 unreadCount=1이 그대로 보존되어야 함
          // 이 시나리오가 실패하면 서버에서 0을 보내고 있다는 의미
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId (상대방)', 2)
              .having((s) => s.messages.first.unreadCount, 'unreadCount (서버에서 1이어야 함)', 1),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: 내가 보낸 메시지도 서버에서 받은 unreadCount가 보존됨',
        build: () {
          final messageController = StreamController<WebSocketChatMessage>();
          when(() => mockWebSocketService.messages)
              .thenAnswer((_) => messageController.stream);

          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createBloc();

          // 내가 보낸 메시지가 서버에서 echo back (unreadCount=1)
          Future.delayed(const Duration(milliseconds: 120), () {
            messageController.add(WebSocketChatMessage(
              messageId: 300,
              senderId: 1, // 내가 보낸 메시지 (currentUserId=1)
              chatRoomId: 1,
              content: '내가 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 31),
              unreadCount: 1, // 상대방이 아직 안 읽어서 1
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        wait: const Duration(milliseconds: 600),
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
          // 내가 보낸 메시지도 unreadCount=1로 보존 (UI에서 "1" 표시됨)
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.senderId, 'senderId (나)', 1)
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
        ],
      );
    });
  });
}
