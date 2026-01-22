import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
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

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockWebSocketService = MockWebSocketService();

    // WebSocketService mock 기본 설정
    when(() => mockWebSocketService.subscribeToChatRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.unsubscribeFromChatRoom(any())).thenReturn(null);
    when(() => mockWebSocketService.messages).thenAnswer(
      (_) => const Stream<WebSocketChatMessage>.empty(),
    );
  });

  ChatRoomBloc createBloc() => ChatRoomBloc(mockChatRepository, mockWebSocketService);

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
            messages: [],
          ),
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
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
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomOpened(1)),
        expect: () => [
          const ChatRoomState(
            status: ChatRoomStatus.loading,
            roomId: 1,
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
        'emits [isSending=true, isSending=false with new message] when send succeeds',
        build: () {
          when(() => mockChatRepository.sendMessage(any(), any()))
              .thenAnswer((_) async => FakeEntities.textMessage);
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
          ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            messages: [FakeEntities.textMessage],
            isSending: false,
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.sendMessage(1, '안녕하세요!')).called(1);
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'emits [isSending=true, isSending=false with error] when send fails',
        build: () {
          when(() => mockChatRepository.sendMessage(any(), any()))
              .thenThrow(Exception('Failed to send'));
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
          isA<ChatRoomState>().having((s) => s.isSending, 'isSending', false),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        'does nothing when roomId is null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MessageSent('test')),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockChatRepository.sendMessage(any(), any()));
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
    });
  });
}
