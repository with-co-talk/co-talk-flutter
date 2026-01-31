import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/chat_list_page.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late MockChatListBloc mockChatListBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  setUp(() {
    mockChatListBloc = MockChatListBloc();
    mockAuthBloc = MockAuthBloc();

    // AuthBloc 기본 상태 설정
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(const User(
        id: 1,
        email: 'test@test.com',
        nickname: 'TestUser',
      )),
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const ChatListPage(),
      ),
    );
  }

  group('ChatListPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('채팅'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(
        const ChatListState(status: ChatListStatus.loading),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no chat rooms', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(
        const ChatListState(status: ChatListStatus.success),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('채팅방이 없습니다\n친구를 추가하고 대화를 시작해보세요'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(
        const ChatListState(
          status: ChatListStatus.failure,
          errorMessage: '에러 발생',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('채팅방을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches ChatListLoadRequested on retry button tap', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(
        const ChatListState(status: ChatListStatus.failure),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // clear 호출 기록 초기화 (initState에서 이미 호출됨)
      clearInteractions(mockChatListBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockChatListBloc.add(const ChatListLoadRequested())).called(1);
    });

    testWidgets('shows chat rooms list when loaded', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          name: null,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          unreadCount: 5,
          lastMessage: '안녕하세요',
          lastMessageAt: DateTime.now(),
          otherUserId: 2,
          otherUserNickname: 'OtherUser',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(
          status: ChatListStatus.success,
          chatRooms: chatRooms,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('OtherUser'), findsOneWidget);
      expect(find.text('안녕하세요'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ for high unread count', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          name: null,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          unreadCount: 150,
          otherUserId: 2,
          otherUserNickname: 'User',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(
          status: ChatListStatus.success,
          chatRooms: chatRooms,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows group icon for group chat rooms', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          name: '그룹 채팅',
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
          unreadCount: 0,
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(
          status: ChatListStatus.success,
          chatRooms: chatRooms,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('dispatches ChatListLoadRequested on init', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockChatListBloc.add(const ChatListLoadRequested())).called(1);
    });

    testWidgets('🔴 RED: re-subscribes with new userId on account switch', skip: true, (tester) async {
      // 최초는 userId=1로 authenticated
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'User1',
        )),
      );

      // 계정 전환 이벤트는 "나중에" 흘려서, clearInteractions 이후 호출을 검증한다.
      final controller = StreamController<AuthState>();
      whenListen(
        mockAuthBloc,
        controller.stream,
        initialState: mockAuthBloc.state,
      );
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());
      // initState 처리
      await tester.pump();
      clearInteractions(mockChatListBloc);

      // auth stream 반영 (계정 전환)
      controller.add(AuthState.authenticated(const User(
        id: 2,
        email: 'test2@test.com',
        nickname: 'User2',
      )));
      await tester.pump();

      verify(() => mockChatListBloc.add(const ChatListSubscriptionStopped())).called(1);
      verify(() => mockChatListBloc.add(const ChatListSubscriptionStarted(2))).called(1);

      await controller.close();
    });
  });
}
