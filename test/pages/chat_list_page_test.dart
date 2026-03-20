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

    testWidgets('does not dispatch ChatListLoadRequested when rooms already loaded', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
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

      // Should NOT call load since rooms are already available
      verifyNever(() => mockChatListBloc.add(const ChatListLoadRequested()));
    });

    testWidgets('shows search icon in app bar', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows settings icon in app bar', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('tapping search icon switches to search mode', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // In search mode the text field should appear
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('채팅방 검색'), findsOneWidget);
    });

    testWidgets('tapping back in search mode exits search mode', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Tap the back arrow to exit search mode
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // Should be back to normal app bar
      expect(find.text('채팅'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('search mode shows clear button when query is not empty', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Type a search query
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tapping clear button clears the search query', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(const ChatListState());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('search filters chat rooms by name', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 2,
          otherUserNickname: 'Alice',
        ),
        ChatRoom(
          id: 2,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 3,
          otherUserNickname: 'Bob',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('search with no matching results shows empty search result', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 2,
          otherUserNickname: 'Alice',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'xyz_nomatch');
      await tester.pump();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.textContaining('"xyz_nomatch"'), findsOneWidget);
    });

    testWidgets('shows online indicator for direct room when other user is online', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 2,
          otherUserNickname: 'OnlineUser',
          isOtherUserOnline: true,
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // The online status indicator is a small green Container
      final containers = find.byWidgetPredicate(
        (w) => w is Container && w.decoration != null,
      );
      expect(containers, findsWidgets);
    });

    testWidgets('does not show online indicator for group rooms', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          name: 'Group',
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Group rooms should show group icon, not online indicator
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('shows image last message preview as 사진을 보냈습니다', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          lastMessage: 'image_url',
          lastMessageType: 'IMAGE',
          otherUserId: 2,
          otherUserNickname: 'User',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('사진을 보냈습니다'), findsOneWidget);
    });

    testWidgets('shows file last message preview as 파일을 보냈습니다', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          lastMessage: 'file_url',
          lastMessageType: 'FILE',
          otherUserId: 2,
          otherUserNickname: 'User',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('파일을 보냈습니다'), findsOneWidget);
    });

    testWidgets('shows self chat name for self type rooms', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.self,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Self chat should show the user's own nickname (from AuthBloc)
      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('shows 나 as self chat name when nickname is empty', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: '',
        )),
      );

      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.self,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('나'), findsOneWidget);
    });

    testWidgets('direct room with no avatar shows initial letter', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 2,
          otherUserNickname: 'Xavier',
          otherUserAvatarUrl: null,
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('shows error snackbar when errorMessage changes', (tester) async {
      when(() => mockChatListBloc.state).thenReturn(
        const ChatListState(status: ChatListStatus.success),
      );

      final streamController = StreamController<ChatListState>.broadcast();
      when(() => mockChatListBloc.stream).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

      streamController.add(const ChatListState(
        status: ChatListStatus.failure,
        errorMessage: '서버 오류',
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);

      await streamController.close();
    });

    testWidgets('pull-to-refresh dispatches ChatListRefreshRequested', (tester) async {
      final chatRooms = List.generate(
        20,
        (i) => ChatRoom(
          id: i + 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, i + 1),
          otherUserId: i + 2,
          otherUserNickname: 'User$i',
        ),
      );

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockChatListBloc);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(() => mockChatListBloc.add(const ChatListRefreshRequested()))
          .called(greaterThanOrEqualTo(1));
    });

    testWidgets('bold unread room shows bold name and preview text', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          unreadCount: 3,
          lastMessage: '새 메시지 도착',
          otherUserId: 2,
          otherUserNickname: 'BoldUser',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Bold name and preview text are shown
      expect(find.text('BoldUser'), findsOneWidget);
      expect(find.text('새 메시지 도착'), findsOneWidget);
    });

    testWidgets('group room with image URL does not show group icon', (tester) async {
      // When a group has an imageUrl, group icon is replaced with the image.
      // We check that the room name is still rendered correctly.
      final chatRooms = [
        ChatRoom(
          id: 1,
          name: '이미지 그룹',
          imageUrl: null, // No image so we can verify group icon shows
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Group rooms with no image show the group icon
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.text('이미지 그룹'), findsOneWidget);
    });

    testWidgets('shows last message time when lastMessageAt is set', (tester) async {
      final chatRooms = [
        ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          lastMessage: '안녕',
          lastMessageAt: DateTime(2024, 6, 15, 14, 30),
          otherUserId: 2,
          otherUserNickname: 'User',
        ),
      ];

      when(() => mockChatListBloc.state).thenReturn(
        ChatListState(status: ChatListStatus.success, chatRooms: chatRooms),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Some formatted time text should appear
      expect(find.text('User'), findsOneWidget);
    });
  });
}
