import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
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

    // WebSocketService mock 기본 설정
    when(() => mockWebSocketService.chatRoomUpdates).thenAnswer(
      (_) => const Stream<WebSocketChatRoomUpdateEvent>.empty(),
    );
    when(() => mockWebSocketService.readEvents).thenAnswer(
      (_) => const Stream<WebSocketReadEvent>.empty(),
    );
    when(() => mockWebSocketService.isConnected).thenReturn(true);
    when(() => mockWebSocketService.currentConnectionState)
        .thenReturn(WebSocketConnectionState.connected);
    when(() => mockWebSocketService.subscribeToUserChannel(any())).thenReturn(null);
    when(() => mockWebSocketService.unsubscribeFromUserChannel()).thenReturn(null);
    when(() => mockWebSocketService.connect()).thenAnswer((_) async => {});
  });

  ChatListBloc createBloc() => ChatListBloc(
        mockChatRepository,
        mockWebSocketService,
        mockAuthLocalDataSource,
      );

  group('ChatListBloc', () {
    test('initial state is ChatListState with initial status', () {
      final bloc = createBloc();
      expect(bloc.state.status, ChatListStatus.initial);
      expect(bloc.state.chatRooms, isEmpty);
    });

    group('ChatListLoadRequested', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, success] when getChatRooms succeeds',
        build: () {
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom, FakeEntities.groupChatRoom],
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom, FakeEntities.groupChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.getChatRooms()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, success] with empty list when no chat rooms',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => []);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          const ChatListState(status: ChatListStatus.success, chatRooms: []),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, failure] when getChatRooms fails',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('ChatListRefreshRequested', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits [success] with updated chat rooms on refresh',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.groupChatRoom],
        ),
        act: (bloc) => bloc.add(const ChatListRefreshRequested()),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
          ),
        ],
      );
    });

    group('ChatRoomCreated', () {
      blocTest<ChatListBloc, ChatListState>(
        'creates chat room and refreshes list',
        build: () {
          when(() => mockChatRepository.createDirectChatRoom(any()))
              .thenAnswer((_) async => FakeEntities.directChatRoom);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomCreated(2)),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.createDirectChatRoom(2)).called(1);
          verify(() => mockChatRepository.getChatRooms()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits failure when createDirectChatRoom fails',
        build: () {
          when(() => mockChatRepository.createDirectChatRoom(any()))
              .thenThrow(Exception('Failed to create room'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatRoomCreated(2)),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('GroupChatRoomCreated', () {
      blocTest<ChatListBloc, ChatListState>(
        'creates group chat room and refreshes list',
        build: () {
          when(() => mockChatRepository.createGroupChatRoom(any(), any()))
              .thenAnswer((_) async => FakeEntities.groupChatRoom);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.groupChatRoom]);
          return createBloc();
        },
        act: (bloc) => bloc.add(const GroupChatRoomCreated(
          name: '그룹 채팅방',
          memberIds: [1, 2, 3],
        )),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.groupChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.createGroupChatRoom(
                '그룹 채팅방',
                [1, 2, 3],
              )).called(1);
        },
      );
    });

    group('ChatRoomUpdated', () {
      blocTest<ChatListBloc, ChatListState>(
        'updates chat room when last message is from other user',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom],
        ),
        act: (bloc) async {
          // 사용자 ID 설정
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 다른 사용자가 보낸 메시지로 업데이트
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: '새 메시지',
            unreadCount: 5,
            senderId: 2, // 다른 사용자
          ));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.unreadCount,
            'unreadCount',
            5,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'uses server unreadCount when last message is from current user (server handles sender exclusion)',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom],
        ),
        act: (bloc) async {
          // 사용자 ID 설정
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 내가 보낸 메시지로 업데이트
          // 서버가 발신자를 제외하여 계산한 unreadCount를 보냄
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: '내 메시지',
            unreadCount: 0, // 서버가 발신자를 제외하여 계산한 값
            senderId: 1, // 현재 사용자
          ));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.unreadCount,
            'unreadCount',
            0, // 서버가 보낸 정확한 값
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: uses server unreadCount when NEW_MESSAGE arrives (server handles presence)',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom.copyWith(unreadCount: 0)],
        ),
        act: (bloc) async {
          // 사용자 ID 설정
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 방을 열어둔 상태로 설정
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));
          // 서버가 presence를 고려하여 계산한 unreadCount 사용
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: '상대방 새 메시지',
            unreadCount: 0, // 서버가 presence를 고려하여 0으로 계산
            senderId: 2, // 상대방
          ));
        },
        expect: () => [
          // ChatRoomEntered로 인한 낙관 업데이트 (이미 0이므로 변화 없음)
          // ChatRoomUpdated에서 열려있는 방이므로 0 유지
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount',
            0, // 서버가 presence를 고려하여 계산한 값
          ),
        ],
      );
    });

    group('ChatListSubscriptionStarted', () {
      blocTest<ChatListBloc, ChatListState>(
        'connects WebSocket if not connected',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(false);
          when(() => mockWebSocketService.connect()).thenAnswer((_) async => {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        wait: const Duration(milliseconds: 600), // 연결 후 구독까지 기다림
        verify: (_) {
          verify(() => mockWebSocketService.connect()).called(1);
          verify(() => mockWebSocketService.subscribeToUserChannel(1)).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'subscribes to user channel when WebSocket is connected',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(true);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        verify: (_) {
          verifyNever(() => mockWebSocketService.connect());
          verify(() => mockWebSocketService.subscribeToUserChannel(1)).called(1);
        },
      );
    });

    group('ChatRoomEntered', () {
      blocTest<ChatListBloc, ChatListState>(
        'does not change unreadCount when room is entered (server value is trusted)',
        build: () => createBloc(),
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 3),
            FakeEntities.groupChatRoom.copyWith(unreadCount: 7),
          ],
        ),
        act: (bloc) => bloc.add(const ChatRoomEntered(1)),
        expect: () => [
          // 서버 값만 신뢰하므로 상태 변경 없음 (서버의 READ 이벤트가 도착하면 업데이트됨)
          // 상태가 변경되지 않으므로 expect는 비어있음
        ],
      );
    });

    group('READ event handling', () {
      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: updates unreadCount to 0 when READ event is received after markAsRead',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 5),
          ],
        ),
        act: (bloc) {
          // READ 이벤트 수신 (서버가 markAsRead 후 보내준 정확한 unreadCount)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'READ',
            unreadCount: 0, // 서버가 계산한 정확한 값
            lastMessage: '마지막 메시지',
            senderId: 2,
          ));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount',
            0, // 서버가 보낸 정확한 값 사용
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: READ event updates unreadCount from server value',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 3),
          ],
        ),
        act: (bloc) {
          // 서버의 READ 이벤트 도착 (정확한 값)
          // ChatRoomEntered는 상태를 변경하지 않으므로 별도로 테스트하지 않음
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'READ',
            unreadCount: 0, // 서버가 계산한 정확한 값
            lastMessage: '마지막 메시지',
            senderId: 2,
          ));
        },
        expect: () => [
          // READ 이벤트로 인한 업데이트 (서버 값 사용)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after READ',
            0, // 서버가 보낸 정확한 값
          ),
        ],
      );
    });
  });
}
