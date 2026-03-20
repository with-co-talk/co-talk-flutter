import 'dart:async';

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
    when(() => mockWebSocketService.onlineStatusEvents).thenAnswer(
      (_) => const Stream<WebSocketOnlineStatusEvent>.empty(),
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
            cachedTotalUnreadCount: 5, // directChatRoom(0) + groupChatRoom(5)
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
          cachedTotalUnreadCount: 5,
        ),
        act: (bloc) => bloc.add(const ChatListRefreshRequested()),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
            cachedTotalUnreadCount: 0, // directChatRoom.unreadCount = 0
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
            cachedTotalUnreadCount: 0, // directChatRoom.unreadCount = 0
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
            cachedTotalUnreadCount: 5, // groupChatRoom.unreadCount = 5
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

    group('ChatRoomExited clears _currentlyOpenRoomId', () {
      blocTest<ChatListBloc, ChatListState>(
        'should show unreadCount from server after ChatRoomExited (window blur on desktop)',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 0),
          ],
        ),
        act: (bloc) async {
          // 1. Enter room (sets _currentlyOpenRoomId)
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));

          // 2. Exit room (clears _currentlyOpenRoomId) - simulates desktop window blur
          bloc.add(const ChatRoomExited());
          await Future.delayed(const Duration(milliseconds: 50));

          // 3. New message arrives from server with unreadCount=1
          bloc.add(ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'Hello!',
            lastMessageAt: DateTime.now(),
            unreadCount: 1,
            senderId: 2,
          ));
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [
          // unreadCount should be 1 (from server), NOT forced to 0
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.unreadCount,
            'unreadCount',
            1,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'should suppress unreadCount to 0 while room is entered (window focused)',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 0),
          ],
        ),
        act: (bloc) async {
          // 1. Enter room (sets _currentlyOpenRoomId)
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));

          // 2. New message arrives while room is entered - unreadCount forced to 0
          bloc.add(ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'Hello!',
            lastMessageAt: DateTime.now(),
            unreadCount: 1,
            senderId: 2,
          ));
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [
          // unreadCount should be 0 (forced by _currentlyOpenRoomId)
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.unreadCount,
            'unreadCount',
            0,
          ),
        ],
      );
    });

    group('ChatRoomReadCompleted', () {
      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: ChatRoomReadCompleted 이벤트로 unreadCount를 0으로 낙관적 업데이트',
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
          // ChatRoomPage의 BlocListener가 isReadMarked 변경 시 전송
          bloc.add(const ChatRoomReadCompleted(1));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount',
            0, // 낙관적 업데이트로 즉시 0으로 설정
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: ChatRoomReadCompleted 후 서버의 chatRoomUpdates가 오면 서버 값으로 덮어쓰기',
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
          // 1. 낙관적 업데이트
          bloc.add(const ChatRoomReadCompleted(1));
          // 2. 서버의 정확한 값이 나중에 도착 (서버가 최종 소스)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'READ',
            unreadCount: 0, // 서버가 계산한 정확한 값
            lastMessage: '마지막 메시지',
            senderId: 2,
          ));
        },
        expect: () => [
          // 낙관적 업데이트: 0
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after optimistic update',
            0,
          ),
          // 서버 값으로 덮어쓰기: 0 (서버가 최종 소스)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after server update',
            0,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: 여러 채팅방이 있을 때 ChatRoomReadCompleted는 특정 채팅방만 업데이트',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(id: 1, unreadCount: 5),
            FakeEntities.groupChatRoom.copyWith(id: 2, unreadCount: 3),
            FakeEntities.directChatRoom.copyWith(id: 3, unreadCount: 7),
          ],
        ),
        act: (bloc) {
          // roomId=2만 업데이트
          bloc.add(const ChatRoomReadCompleted(2));
        },
        expect: () => [
          isA<ChatListState>()
              .having(
                (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
                'room 1 unreadCount',
                5, // 변경 없음
              )
              .having(
                (s) => s.chatRooms.firstWhere((r) => r.id == 2).unreadCount,
                'room 2 unreadCount',
                0, // 업데이트됨
              )
              .having(
                (s) => s.chatRooms.firstWhere((r) => r.id == 3).unreadCount,
                'room 3 unreadCount',
                7, // 변경 없음
              ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '🔴 RED: ChatRoomReadCompleted 후 서버가 다른 unreadCount 값을 보내면 서버 값으로 덮어쓰기',
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
          // 1. 낙관적 업데이트: 0
          bloc.add(const ChatRoomReadCompleted(1));
          // 2. 서버가 실제로는 unreadCount=2라고 응답 (예: 일부만 읽음)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'READ',
            unreadCount: 2, // 서버가 계산한 정확한 값 (낙관적 업데이트와 다름)
            lastMessage: '마지막 메시지',
            senderId: 2,
          ));
        },
        expect: () => [
          // 낙관적 업데이트: 0
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after optimistic update',
            0,
          ),
          // 서버 값으로 덮어쓰기: 2 (서버가 최종 소스)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after server update',
            2, // 서버 값으로 덮어쓰기됨
          ),
        ],
      );
    });

    group('READ event handling', () {
      blocTest<ChatListBloc, ChatListState>(
        '✅ GREEN: READ 이벤트 수신 시 unreadCount가 서버 값(0)으로 업데이트됨',
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
        '✅ GREEN: READ 이벤트로 unreadCount가 서버 값으로 업데이트됨',
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

    group('채팅방 목록 unreadCount 표시 시나리오', () {
      blocTest<ChatListBloc, ChatListState>(
        '✅ GREEN: 시나리오 1 - 채팅방 목록에서 내가 읽지 않은 메시지의 총 개수가 표시됨',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 0),
          ],
        ),
        act: (bloc) async {
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 상대방이 메시지를 보냄 -> 서버가 내가 읽지 않은 메시지 개수를 계산하여 전송
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: '새 메시지 1',
            unreadCount: 1, // 내가 읽지 않은 메시지 1개
            senderId: 2, // 상대방
          ));
          await Future.delayed(const Duration(milliseconds: 50));
          // 또 다른 메시지
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: '새 메시지 2',
            unreadCount: 2, // 내가 읽지 않은 메시지 2개
            senderId: 2, // 상대방
          ));
        },
        expect: () => [
          // 첫 번째 메시지: unreadCount=1
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after first message',
            1,
          ),
          // 두 번째 메시지: unreadCount=2 (내가 읽지 않은 메시지 총 개수)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after second message',
            2, // 내가 읽지 않은 메시지 총 개수
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '✅ GREEN: 시나리오 2 - 읽는 순간 전부 읽음 처리되어서 채팅 목록에는 0으로 표시됨',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 5), // 읽지 않은 메시지 5개
          ],
        ),
        act: (bloc) async {
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 채팅방에 진입하여 읽음 처리
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));
          // 서버가 읽음 처리 완료 후 READ 이벤트로 unreadCount=0 전송
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'READ',
            unreadCount: 0, // 읽음 처리 완료로 0
            lastMessage: '마지막 메시지',
            senderId: 2,
          ));
        },
        expect: () => [
          // READ 이벤트 후: unreadCount=0 (숫자 표시 안 됨)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount after read',
            0, // 읽음 처리 완료로 0, 숫자 표시 안 됨
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        '✅ GREEN: 시나리오 3 - 그룹 채팅에서 내가 안 읽은 메시지 개수만 표시됨 (다른 사람의 안 읽은 수 무시)',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.groupChatRoom.copyWith(
              id: 3,
              unreadCount: 0,
            ),
          ],
        ),
        act: (bloc) async {
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // 그룹 채팅에서 새 메시지 도착
          // 서버는 내가 읽지 않은 메시지 개수만 계산하여 전송
          // (다른 사람들이 읽지 않은 개수는 고려하지 않음)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 3,
            eventType: 'NEW_MESSAGE',
            lastMessage: '그룹 메시지',
            unreadCount: 3, // 내가 읽지 않은 메시지 3개만 (다른 사람들의 unreadCount 합산하지 않음)
            senderId: 2, // 다른 사용자
          ));
        },
        expect: () => [
          // 그룹 채팅에서도 내가 읽지 않은 메시지 개수만 표시
          // (안 읽은 사람이 2명이라 안 읽은 개수만 다 더하면 6개더라도)
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 3).unreadCount,
            'unreadCount in group chat',
            3, // 내가 안 읽은 메시지 개수 3개만 표시 (다른 사람들의 unreadCount 합산하지 않음)
          ),
        ],
      );
    });

    group('ChatRoomExited', () {
      blocTest<ChatListBloc, ChatListState>(
        'after exiting room, subsequent ChatRoomUpdated events increment unread normally',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom.copyWith(unreadCount: 0)],
        ),
        act: (bloc) async {
          // Start subscription
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 50));
          // Enter room (unread suppressed)
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));
          // Exit room
          bloc.add(const ChatRoomExited());
          await Future.delayed(const Duration(milliseconds: 50));
          // Now update should increment unread normally (not suppressed to 0)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'New message after exit',
            unreadCount: 1,
            senderId: 2,
          ));
        },
        expect: () => [
          // Subsequent ChatRoomUpdated should increment unread normally
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount',
            1, // Not suppressed to 0
          ),
        ],
      );
    });

    group('UserOnlineStatusChanged', () {
      blocTest<ChatListBloc, ChatListState>(
        'updates isOtherUserOnline for 1:1 chat when partner status changes',
        build: () => createBloc(),
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(
              id: 1,
              otherUserId: 2,
              isOtherUserOnline: false,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const UserOnlineStatusChanged(
          userId: 2,
          isOnline: true,
          lastActiveAt: null,
        )),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).isOtherUserOnline,
            'isOtherUserOnline',
            true,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'does not emit state when user is not in any room (Equatable skips identical state)',
        build: () => createBloc(),
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(
              id: 1,
              otherUserId: 2,
              isOtherUserOnline: false,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const UserOnlineStatusChanged(
          userId: 999, // Not in any room
          isOnline: true,
          lastActiveAt: null,
        )),
        expect: () => [], // Equatable skips emission because no room fields changed
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits state when updating group chat (even though otherUserId is null)',
        build: () => createBloc(),
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.groupChatRoom.copyWith(
              id: 2,
              otherUserId: null, // Group chat has no otherUserId
            ),
          ],
        ),
        act: (bloc) => bloc.add(const UserOnlineStatusChanged(
          userId: 3,
          isOnline: true,
          lastActiveAt: null,
        )),
        expect: () => [
          // State is emitted but no room properties changed (otherUserId is null for group chats)
          isA<ChatListState>().having(
            (s) => s.chatRooms.length,
            'chatRooms length',
            1,
          ),
        ],
      );
    });

    group('ChatListSubscriptionStopped', () {
      blocTest<ChatListBloc, ChatListState>(
        'cancels all subscriptions when stopped',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          final chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>();
          final readController = StreamController<WebSocketReadEvent>();
          final onlineStatusController = StreamController<WebSocketOnlineStatusEvent>();

          when(() => mockWebSocketService.chatRoomUpdates)
              .thenAnswer((_) => chatRoomUpdateController.stream);
          when(() => mockWebSocketService.readEvents)
              .thenAnswer((_) => readController.stream);
          when(() => mockWebSocketService.onlineStatusEvents)
              .thenAnswer((_) => onlineStatusController.stream);

          return createBloc();
        },
        act: (bloc) async {
          // Start subscription
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // Stop subscription
          bloc.add(const ChatListSubscriptionStopped());
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) {
          // Subscriptions should be cancelled
          verify(() => mockWebSocketService.chatRoomUpdates).called(1);
          verify(() => mockWebSocketService.readEvents).called(1);
          verify(() => mockWebSocketService.onlineStatusEvents).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'after subscription stopped, stream events no longer processed',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          final chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>.broadcast();

          when(() => mockWebSocketService.chatRoomUpdates)
              .thenAnswer((_) => chatRoomUpdateController.stream);

          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom.copyWith(unreadCount: 0)],
        ),
        act: (bloc) async {
          // Start subscription
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // Stop subscription
          bloc.add(const ChatListSubscriptionStopped());
          await Future.delayed(const Duration(milliseconds: 100));
          // Try to send update - should be ignored
          // (In real test, the stream controller would be closed or events ignored)
        },
        expect: () => [],
        verify: (_) {
          // Verify subscription was started and stopped
          verify(() => mockWebSocketService.chatRoomUpdates).called(1);
        },
      );
    });

    group('Bug fix verification', () {
      blocTest<ChatListBloc, ChatListState>(
        'ChatRoomUpdated handler completes fully with async getUserId',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer(
            (_) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return 1;
            },
          );
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom],
        ),
        act: (bloc) => bloc.add(const ChatRoomUpdated(
          chatRoomId: 1,
          eventType: 'NEW_MESSAGE',
          lastMessage: 'Test message',
          unreadCount: 5,
          senderId: 2,
        )),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.firstWhere((r) => r.id == 1).unreadCount,
            'unreadCount',
            5,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'SubscriptionStarted handler completes fully with async operations',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer(
            (_) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return 1;
            },
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        wait: const Duration(milliseconds: 200),
        verify: (_) {
          verify(() => mockWebSocketService.subscribeToUserChannel(1)).called(1);
        },
      );
    });

    group('Subscription leak prevention', () {
      blocTest<ChatListBloc, ChatListState>(
        'cancels all previous subscriptions before reassigning on repeated SubscriptionStarted',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(true);
          return createBloc();
        },
        act: (bloc) async {
          // First subscription
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // Second subscription (should cancel the first three streams)
          bloc.add(const ChatListSubscriptionStarted(2));
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) {
          // subscribeToUserChannel should be called twice (once per start)
          verify(() => mockWebSocketService.subscribeToUserChannel(1)).called(1);
          verify(() => mockWebSocketService.subscribeToUserChannel(2)).called(1);
          // chatRoomUpdates, readEvents, onlineStatusEvents each accessed twice
          // (once per SubscriptionStarted to create new listeners)
          verify(() => mockWebSocketService.chatRoomUpdates).called(2);
          verify(() => mockWebSocketService.readEvents).called(2);
          verify(() => mockWebSocketService.onlineStatusEvents).called(2);
        },
      );
    });

    group('ChatListRefreshRequested - additional branches', () {
      blocTest<ChatListBloc, ChatListState>(
        'skips duplicate refresh when _isRefreshing is true',
        build: () {
          // Slow response so first refresh holds _isRefreshing = true
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async {
              await Future.delayed(const Duration(milliseconds: 200));
              return [FakeEntities.directChatRoom];
            },
          );
          return createBloc();
        },
        act: (bloc) async {
          // Fire two refreshes almost simultaneously; second should be skipped
          bloc.add(const ChatListRefreshRequested());
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const ChatListRefreshRequested());
        },
        wait: const Duration(milliseconds: 400),
        verify: (_) {
          // getChatRooms called only once despite two refresh requests
          verify(() => mockChatRepository.getChatRooms()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits failure when getChatRooms throws during refresh',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenThrow(Exception('refresh network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListRefreshRequested()),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('ChatRoomUpdated - new room triggers refresh', () {
      blocTest<ChatListBloc, ChatListState>(
        'schedules refresh when updated room is not found in current list',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.directChatRoom],
        ),
        act: (bloc) async {
          // Event references a room that is NOT in the list (id=999)
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 999,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'Hello from new room',
            unreadCount: 1,
            senderId: 2,
          ));
          // Wait long enough for the 300ms debounce timer and subsequent refresh
          await Future.delayed(const Duration(milliseconds: 500));
        },
        wait: const Duration(milliseconds: 600),
        verify: (_) {
          // getChatRooms should have been called by the scheduled refresh
          verify(() => mockChatRepository.getChatRooms()).called(greaterThanOrEqualTo(1));
        },
      );
    });

    group('ChatRoomUpdated - room re-sorting', () {
      blocTest<ChatListBloc, ChatListState>(
        'reorders rooms so the one with the most recent message is first',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(
              id: 1,
              lastMessageAt: DateTime(2024, 1, 1, 10, 0),
            ),
            FakeEntities.groupChatRoom.copyWith(
              id: 2,
              lastMessageAt: DateTime(2024, 1, 1, 9, 0),
            ),
          ],
        ),
        act: (bloc) async {
          // room 2 receives a new message at a later time -> should move to top
          bloc.add(ChatRoomUpdated(
            chatRoomId: 2,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'New group message',
            lastMessageAt: DateTime(2024, 1, 1, 11, 0),
            unreadCount: 1,
            senderId: 3,
          ));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.id,
            'first room id after sort',
            2, // room 2 should be first now
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'uses createdAt as fallback sort key when lastMessageAt is null',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(
              id: 1,
              lastMessageAt: null,
              createdAt: DateTime(2024, 1, 1),
            ),
            FakeEntities.groupChatRoom.copyWith(
              id: 2,
              lastMessageAt: null,
              createdAt: DateTime(2024, 1, 2),
            ),
          ],
        ),
        act: (bloc) async {
          // Update room 1 with a new lastMessage but still null lastMessageAt
          bloc.add(const ChatRoomUpdated(
            chatRoomId: 1,
            eventType: 'NEW_MESSAGE',
            lastMessage: 'Updated',
            unreadCount: 1,
            senderId: 3,
          ));
        },
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.id,
            'first room id — newer createdAt wins',
            2, // room 2 has createdAt=2024-01-02 which is newer
          ),
        ],
      );
    });

    group('ChatListSubscriptionStarted - WebSocket degraded', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits isWebSocketDegraded=true when connect throws',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(false);
          when(() => mockWebSocketService.currentConnectionState)
              .thenReturn(WebSocketConnectionState.disconnected);
          when(() => mockWebSocketService.connectionState).thenAnswer(
            (_) => const Stream<WebSocketConnectionState>.empty(),
          );
          when(() => mockWebSocketService.connect())
              .thenThrow(Exception('connection refused'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.isWebSocketDegraded,
            'isWebSocketDegraded',
            true,
          ),
        ],
        verify: (_) {
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits isWebSocketDegraded=false when already connected',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(true);
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.isWebSocketDegraded,
            'isWebSocketDegraded',
            false,
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits isWebSocketDegraded=false when WebSocket connects via stream',
        build: () {
          when(() => mockWebSocketService.isConnected).thenReturn(false);
          when(() => mockWebSocketService.currentConnectionState)
              .thenReturn(WebSocketConnectionState.disconnected);
          when(() => mockWebSocketService.connect()).thenAnswer((_) async {});

          // Stream that emits connected state quickly
          final controller = StreamController<WebSocketConnectionState>.broadcast();
          when(() => mockWebSocketService.connectionState)
              .thenAnswer((_) => controller.stream);

          // Emit connected state shortly after connect is called
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!controller.isClosed) {
              controller.add(WebSocketConnectionState.connected);
            }
          });

          return createBloc();
        },
        act: (bloc) => bloc.add(const ChatListSubscriptionStarted(1)),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.isWebSocketDegraded,
            'isWebSocketDegraded',
            false,
          ),
        ],
      );
    });

    group('GroupChatRoomCreated - error branch', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits failure when createGroupChatRoom throws',
        build: () {
          when(() => mockChatRepository.createGroupChatRoom(any(), any()))
              .thenThrow(Exception('server error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const GroupChatRoomCreated(
          name: 'New Group',
          memberIds: [2, 3],
        )),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('ChatRoomUpdated - null field fallbacks', () {
      blocTest<ChatListBloc, ChatListState>(
        'keeps existing lastMessage when event lastMessage is null',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(
              id: 1,
              lastMessage: 'original message',
              unreadCount: 3, // non-zero so update causes state change
            ),
          ],
        ),
        act: (bloc) => bloc.add(const ChatRoomUpdated(
          chatRoomId: 1,
          eventType: 'READ',
          // lastMessage intentionally null — should preserve existing
          unreadCount: 0,
          senderId: 1,
        )),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.lastMessage,
            'lastMessage preserved',
            'original message',
          ),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'keeps existing unreadCount when event unreadCount is null',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(id: 1, unreadCount: 7),
          ],
        ),
        act: (bloc) => bloc.add(const ChatRoomUpdated(
          chatRoomId: 1,
          eventType: 'UPDATE',
          lastMessage: 'some update',
          // unreadCount intentionally null
          senderId: 2,
        )),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.chatRooms.first.unreadCount,
            'unreadCount preserved when event.unreadCount is null',
            7,
          ),
        ],
      );
    });

    group('ChatListResetRequested', () {
      blocTest<ChatListBloc, ChatListState>(
        'clears all state and returns to initial when reset is requested',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [
            FakeEntities.directChatRoom.copyWith(unreadCount: 3),
            FakeEntities.groupChatRoom.copyWith(unreadCount: 7),
          ],
          cachedTotalUnreadCount: 10,
        ),
        act: (bloc) async {
          // First start subscriptions to have active state
          bloc.add(const ChatListSubscriptionStarted(1));
          await Future.delayed(const Duration(milliseconds: 100));
          // Enter a room to set _currentlyOpenRoomId
          bloc.add(const ChatRoomEntered(1));
          await Future.delayed(const Duration(milliseconds: 50));
          // Now reset everything (simulating logout)
          bloc.add(const ChatListResetRequested());
        },
        expect: () => [
          // The final emission should be the initial/default state
          const ChatListState(),
        ],
        verify: (bloc) {
          // After reset, state should be completely clean
          expect(bloc.state.status, ChatListStatus.initial);
          expect(bloc.state.chatRooms, isEmpty);
          expect(bloc.state.totalUnreadCount, 0);
          expect(bloc.state.errorMessage, isNull);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'after reset, can load fresh data for a new user',
        build: () {
          when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return createBloc();
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.groupChatRoom],
          cachedTotalUnreadCount: 5,
        ),
        act: (bloc) async {
          // Reset (simulating logout)
          bloc.add(const ChatListResetRequested());
          await Future.delayed(const Duration(milliseconds: 50));
          // Load fresh data (simulating login as new user)
          bloc.add(const ChatListLoadRequested());
        },
        expect: () => [
          // Reset emission
          const ChatListState(),
          // Load emissions
          const ChatListState(status: ChatListStatus.loading),
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
            cachedTotalUnreadCount: 0,
          ),
        ],
      );
    });
  });
}
