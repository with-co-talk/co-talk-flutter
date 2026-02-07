import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

void main() {
  group('WebSocket 통합 테스트 - 읽음 처리', () {
    late MockChatRepository mockChatRepository;
    late MockWebSocketService mockWebSocketService;
    late MockAuthLocalDataSource mockAuthLocalDataSource;
    late MockDesktopNotificationBridge mockDesktopNotificationBridge;
    late MockActiveRoomTracker mockActiveRoomTracker;
    late StreamController<WebSocketChatMessage> messageController;
    late StreamController<WebSocketReadEvent> readEventController;
    late StreamController<WebSocketChatRoomUpdateEvent> chatRoomUpdateController;

    setUp(() {
      mockChatRepository = MockChatRepository();
      mockWebSocketService = MockWebSocketService();
      mockAuthLocalDataSource = MockAuthLocalDataSource();
      mockDesktopNotificationBridge = MockDesktopNotificationBridge();
      mockActiveRoomTracker = MockActiveRoomTracker();

      messageController = StreamController<WebSocketChatMessage>.broadcast();
      readEventController = StreamController<WebSocketReadEvent>.broadcast();
      chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>.broadcast();

      when(() => mockWebSocketService.messages)
          .thenAnswer((_) => messageController.stream);
      when(() => mockWebSocketService.readEvents)
          .thenAnswer((_) => readEventController.stream);
      when(() => mockWebSocketService.chatRoomUpdates)
          .thenAnswer((_) => chatRoomUpdateController.stream);
      when(() => mockWebSocketService.typingEvents)
          .thenAnswer((_) => const Stream<WebSocketTypingEvent>.empty());
      when(() => mockWebSocketService.isConnected).thenReturn(true);
      when(() => mockWebSocketService.currentConnectionState)
          .thenReturn(WebSocketConnectionState.connected);
      when(() => mockWebSocketService.subscribeToUserChannel(any())).thenReturn(null);
      when(() => mockWebSocketService.subscribeToChatRoom(any())).thenReturn(null);
      when(() => mockWebSocketService.unsubscribeFromChatRoom(any())).thenReturn(null);
      when(() => mockWebSocketService.unsubscribeFromUserChannel()).thenReturn(null);
      when(() => mockWebSocketService.sendPresencePing(
            roomId: any(named: 'roomId'),
          )).thenReturn(null);
      when(() => mockWebSocketService.sendPresenceInactive(
            roomId: any(named: 'roomId'),
          )).thenReturn(null);
      when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
      when(() => mockDesktopNotificationBridge.setActiveRoomId(any())).thenReturn(null);
      when(() => mockActiveRoomTracker.activeRoomId).thenReturn(null);
      when(() => mockActiveRoomTracker.activeRoomId = any()).thenReturn(null);

      // ChatRoomBloc에서 구독하는 추가 WebSocket 스트림 mock
      when(() => mockWebSocketService.messageDeletedEvents).thenAnswer(
        (_) => const Stream<WebSocketMessageDeletedEvent>.empty(),
      );
      when(() => mockWebSocketService.reactions).thenAnswer(
        (_) => const Stream<WebSocketReactionEvent>.empty(),
      );
      when(() => mockWebSocketService.resetReconnectAttempts()).thenReturn(null);
      when(() => mockWebSocketService.ensureConnected(
        timeout: any(named: 'timeout'),
      )).thenAnswer((_) async => true);
      when(() => mockWebSocketService.disconnect()).thenReturn(null);

      // ChatRoomBloc._onOpened에서 호출하는 ChatRepository mock
      when(() => mockChatRepository.getChatRoom(any()))
          .thenAnswer((_) async => FakeEntities.directChatRoomWithoutOtherUser);
      when(() => mockChatRepository.getLocalMessages(
        any(),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
      )).thenAnswer((_) async => <Message>[]);
      when(() => mockChatRepository.saveMessageLocally(any()))
          .thenAnswer((_) async {});

      // ChatListBloc._onSubscriptionStarted에서 구독하는 추가 WebSocket 스트림 mock
      when(() => mockWebSocketService.onlineStatusEvents).thenAnswer(
        (_) => const Stream<WebSocketOnlineStatusEvent>.empty(),
      );
      when(() => mockWebSocketService.connect()).thenAnswer((_) async => {});
    });

    tearDown(() {
      messageController.close();
      readEventController.close();
      chatRoomUpdateController.close();
    });

    ChatRoomBloc createChatRoomBloc() => ChatRoomBloc(
          mockChatRepository,
          mockWebSocketService,
          mockAuthLocalDataSource,
          mockDesktopNotificationBridge,
          mockActiveRoomTracker,
        );

    ChatListBloc createChatListBloc() => ChatListBloc(
          mockChatRepository,
          mockWebSocketService,
          mockAuthLocalDataSource,
        );

    setUpAll(() {
      registerFallbackValue(FakeEntities.textMessage);
      registerFallbackValue(const Duration(seconds: 5));
    });

    group('실제 WebSocket 스트림 시뮬레이션', () {
      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: markAsRead 후 서버가 chatRoomUpdates로 unreadCount=0을 보내면 ChatListBloc이 업데이트됨',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom.copyWith(unreadCount: 5)],
          );

          final chatRoomBloc = createChatRoomBloc();
          final chatListBloc = createChatListBloc();

          // ChatListBloc 구독 시작
          chatListBloc.add(const ChatListSubscriptionStarted(1));
          chatListBloc.add(const ChatListLoadRequested());

          // ChatRoomBloc에서 markAsRead 호출 후 서버가 chatRoomUpdates를 보내는 시뮬레이션
          Future.delayed(const Duration(milliseconds: 300), () {
            // 서버가 markAsRead 완료 후 unreadCount=0으로 업데이트된 chatRoomUpdate 전송
            chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
              chatRoomId: 1,
              eventType: 'READ',
              lastMessage: 'Test message',
              lastMessageAt: DateTime(2026, 1, 25),
              unreadCount: 0, // 읽음 처리 후 0으로 업데이트
              senderId: 1,
            ));
          });

          return chatRoomBloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 1000),
        verify: (_) {
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: 서버가 chatRoomUpdates로 unreadCount를 보내면 ChatListBloc이 정확히 업데이트함',
        build: () {
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom.copyWith(unreadCount: 5)],
          );

          final bloc = createChatListBloc();

          // 구독 시작
          bloc.add(const ChatListSubscriptionStarted(1));
          bloc.add(const ChatListLoadRequested());

          // 서버가 chatRoomUpdates를 보내는 시뮬레이션
          Future.delayed(const Duration(milliseconds: 200), () {
            chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
              chatRoomId: 1,
              eventType: 'READ',
              lastMessage: 'Test message',
              lastMessageAt: DateTime(2026, 1, 25),
              unreadCount: 0, // 읽음 처리 후 0으로 업데이트
              senderId: 1,
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 800),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading, cachedTotalUnreadCount: 0),
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom.copyWith(unreadCount: 5)],
            cachedTotalUnreadCount: 5,
          ),
          // 서버가 보낸 unreadCount=0으로 업데이트됨, lastMessage와 lastMessageAt도 업데이트됨
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [
              FakeEntities.directChatRoom.copyWith(
                unreadCount: 0,
                lastMessage: 'Test message',
                lastMessageAt: DateTime(2026, 1, 25),
              ),
            ],
            cachedTotalUnreadCount: 0,
          ),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: 내가 메시지를 보내면 서버가 unreadCount=1로 응답하고, 상대가 읽으면 0으로 업데이트됨',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});

          final bloc = createChatRoomBloc();

          // 내가 메시지를 보냄 -> 서버가 unreadCount=1로 응답
          Future.delayed(const Duration(milliseconds: 200), () {
            messageController.add(WebSocketChatMessage(
              messageId: 100,
              senderId: 1, // 내 메시지
              chatRoomId: 1,
              content: '내가 보낸 메시지',
              type: 'TEXT',
              createdAt: DateTime(2026, 1, 25),
              unreadCount: 1, // 상대가 아직 읽지 않음
            ));
          });

          // 상대가 읽음 -> 서버가 READ 이벤트 전송
          Future.delayed(const Duration(milliseconds: 400), () {
            readEventController.add(WebSocketReadEvent(
              chatRoomId: 1,
              userId: 2, // 상대방
              lastReadMessageId: 100,
              lastReadAt: DateTime(2026, 1, 25, 12, 0, 0),
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 600));
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
          // 내 메시지 수신: unreadCount=1
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 1),
          // 상대가 읽은 후: unreadCount=0
          isA<ChatRoomState>()
              .having((s) => s.messages.length, 'messages length', 1)
              .having((s) => s.messages.first.unreadCount, 'unreadCount', 0),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: 여러 채팅방이 있을 때 특정 채팅방의 unreadCount만 업데이트됨',
        build: () {
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [
              FakeEntities.directChatRoom.copyWith(id: 1, unreadCount: 3),
              FakeEntities.groupChatRoom.copyWith(id: 2, unreadCount: 5),
            ],
          );

          final bloc = createChatListBloc();

          bloc.add(const ChatListSubscriptionStarted(1));
          bloc.add(const ChatListLoadRequested());

          // roomId=1의 unreadCount만 업데이트
          Future.delayed(const Duration(milliseconds: 200), () {
            chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
              chatRoomId: 1,
              eventType: 'READ',
              lastMessage: 'Test message',
              lastMessageAt: DateTime(2026, 1, 25),
              unreadCount: 0, // roomId=1만 0으로 업데이트
              senderId: 1,
            ));
          });

          return bloc;
        },
        act: (bloc) async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 800),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading, cachedTotalUnreadCount: 0),
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [
              FakeEntities.directChatRoom.copyWith(id: 1, unreadCount: 3),
              FakeEntities.groupChatRoom.copyWith(id: 2, unreadCount: 5),
            ],
            cachedTotalUnreadCount: 8, // 3 + 5
          ),
          // roomId=1만 unreadCount=0으로 업데이트, lastMessage와 lastMessageAt도 업데이트됨
          // roomId=2는 그대로 5
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [
              FakeEntities.directChatRoom.copyWith(
                id: 1,
                unreadCount: 0,
                lastMessage: 'Test message',
                lastMessageAt: DateTime(2026, 1, 25),
              ),
              FakeEntities.groupChatRoom.copyWith(id: 2, unreadCount: 5),
            ],
            cachedTotalUnreadCount: 5, // 0 + 5
          ),
        ],
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: 데스크탑 초기화 실패 시나리오 - ChatRoomForegrounded가 호출되지 않으면 전체 플로우 실패',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom.copyWith(unreadCount: 5)],
          );

          final chatRoomBloc = createChatRoomBloc();
          final chatListBloc = createChatListBloc();

          chatListBloc.add(const ChatListSubscriptionStarted(1));
          chatListBloc.add(const ChatListLoadRequested());

          return chatRoomBloc;
        },
        act: (bloc) async {
          // ChatRoomOpened만 호출하고 ChatRoomForegrounded를 호출하지 않음
          // (데스크탑 초기화 실패 시나리오)
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          // ChatRoomForegrounded를 호출하지 않음 -> _isViewingRoom = false
          
          // 상대방 메시지 도착
          messageController.add(WebSocketChatMessage(
            messageId: 1,
            senderId: 2,
            chatRoomId: 1,
            content: 'Hi',
            type: 'TEXT',
            createdAt: DateTime(2026, 1, 25),
            unreadCount: 0,
          ));
          await Future.delayed(const Duration(milliseconds: 200));
        },
        wait: const Duration(milliseconds: 1000),
        verify: (_) {
          // ChatRoomForegrounded가 호출되지 않았으므로 markAsRead가 호출되지 않아야 함
          verifyNever(() => mockChatRepository.markAsRead(any()));
        },
      );

      blocTest<ChatRoomBloc, ChatRoomState>(
        '🔴 RED: 데스크탑 초기화 성공 시나리오 - ChatRoomForegrounded가 호출되면 전체 플로우 성공',
        build: () {
          when(() => mockChatRepository.getMessages(any(), size: any(named: 'size')))
              .thenAnswer((_) async => (<Message>[], null, false));
          when(() => mockChatRepository.markAsRead(any())).thenAnswer((_) async {});
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom.copyWith(unreadCount: 5)],
          );
          when(() => mockWebSocketService.sendPresencePing(
                roomId: any(named: 'roomId'),
              )).thenReturn(null);

          final chatRoomBloc = createChatRoomBloc();
          final chatListBloc = createChatListBloc();

          chatListBloc.add(const ChatListSubscriptionStarted(1));
          chatListBloc.add(const ChatListLoadRequested());

          // markAsRead 성공 후 서버가 chatRoomUpdates를 보내는 시뮬레이션
          Future.delayed(const Duration(milliseconds: 500), () {
            chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
              chatRoomId: 1,
              eventType: 'READ',
              lastMessage: 'Test message',
              lastMessageAt: DateTime(2026, 1, 25),
              unreadCount: 0,
              senderId: 1,
            ));
          });

          return chatRoomBloc;
        },
        act: (bloc) async {
          bloc.add(const ChatRoomOpened(1));
          await Future.delayed(const Duration(milliseconds: 200));
          // ChatRoomForegrounded 호출 -> _isViewingRoom = true
          bloc.add(const ChatRoomForegrounded());
          await Future.delayed(const Duration(milliseconds: 400));
        },
        wait: const Duration(milliseconds: 1500),
        verify: (_) {
          // ChatRoomForegrounded가 호출되었으므로 markAsRead가 호출되어야 함
          verify(() => mockChatRepository.markAsRead(1)).called(1);
        },
      );
    });
  });
}
