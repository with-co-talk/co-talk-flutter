import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/chat_room_page.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/core/window/window_focus_tracker.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeChatRoomEvent extends Fake implements ChatRoomEvent {}

class FakeChatListEvent extends Fake implements ChatListEvent {}

class TestWindowFocusTracker implements WindowFocusTracker {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool? _current;

  void emit(bool focused) {
    _current = focused;
    _controller.add(focused);
  }

  @override
  Stream<bool> get focusStream => _controller.stream;

  @override
  Future<bool?> currentFocus() async => _current;

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    registerFallbackValue(FakeChatRoomEvent());
    registerFallbackValue(FakeChatListEvent());
  });

  group('ChatRoomPage Widget Tests', () {
    late MockChatRoomBloc mockChatRoomBloc;
    late MockChatListBloc mockChatListBloc;
    late MockAuthBloc mockAuthBloc;
    late StreamController<ChatRoomState> chatRoomStreamController;
    late StreamController<ChatListState> chatListStreamController;

    setUp(() {
      mockChatRoomBloc = MockChatRoomBloc();
      mockChatListBloc = MockChatListBloc();
      mockAuthBloc = MockAuthBloc();
      chatRoomStreamController = StreamController<ChatRoomState>.broadcast();
      chatListStreamController = StreamController<ChatListState>.broadcast();
    });

    tearDown(() {
      chatRoomStreamController.close();
      chatListStreamController.close();
    });

    Widget createWidgetUnderTest({
      ChatRoomState? chatRoomState,
      AuthState? authState,
      int roomId = 1,
      WindowFocusTracker? windowFocusTracker,
    }) {
      final state = chatRoomState ?? const ChatRoomState();
      when(() => mockChatRoomBloc.state).thenReturn(state);
      when(() => mockChatRoomBloc.stream)
          .thenAnswer((_) => chatRoomStreamController.stream);
      when(() => mockChatRoomBloc.isClosed).thenReturn(false);
      when(() => mockChatRoomBloc.add(any())).thenReturn(null);

      when(() => mockChatListBloc.state).thenReturn(const ChatListState());
      when(() => mockChatListBloc.stream)
          .thenAnswer((_) => chatListStreamController.stream);
      when(() => mockChatListBloc.isClosed).thenReturn(false);
      when(() => mockChatListBloc.add(any())).thenReturn(null);

      when(() => mockAuthBloc.state).thenReturn(
        authState ??
            AuthState.authenticated(const User(
              id: 1,
              email: 'test@test.com',
              nickname: 'TestUser',
            )),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: ChatRoomPage(
            roomId: roomId,
            windowFocusTracker: windowFocusTracker,
          ),
        ),
      );
    }

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('채팅'), findsOneWidget);
    });

    testWidgets('shows more options button in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: const ChatRoomState(status: ChatRoomStatus.loading),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no messages', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: const ChatRoomState(status: ChatRoomStatus.success),
      ));
      await tester.pumpAndSettle();

      expect(find.text('메시지가 없습니다'), findsOneWidget);
      expect(find.text('대화를 시작해보세요'), findsOneWidget);
    });

    testWidgets('shows message input field', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('메시지를 입력하세요'), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows attachment button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('dispatches ChatRoomOpened on init', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(roomId: 42));

      verify(() => mockChatRoomBloc.add(const ChatRoomOpened(42))).called(1);
    });

    testWidgets('on mobile: inactive does NOT background room (avoid over-unsubscribe)',
        (tester) async {
      final prev = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(createWidgetUnderTest());
        clearInteractions(mockChatRoomBloc);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();

        verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));
      } finally {
        debugDefaultTargetPlatformOverride = prev;
      }
    });

    testWidgets('on desktop: inactive does NOT background room (focus tracker is the source of truth)',
        (tester) async {
      final prev = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await tester.pumpWidget(createWidgetUnderTest());
        clearInteractions(mockChatRoomBloc);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();

        // 데스크탑은 window focus 이벤트가 더 정확하므로 inactive로 background 처리하지 않는다.
        verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();

        verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));
      } finally {
        debugDefaultTargetPlatformOverride = prev;
      }
    });

    testWidgets('dispatches background/foreground on window blur/focus (deterministic)',
        (tester) async {
      final tracker = TestWindowFocusTracker();
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(windowFocusTracker: tracker));
      clearInteractions(mockChatRoomBloc);

      tracker.emit(false);
      await tester.pump();
      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);

      tracker.emit(true);
      await tester.pump();
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('shows messages when loaded', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: 'OtherUser',
          content: '안녕하세요',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
        Message(
          id: 2,
          chatRoomId: 1,
          senderId: 1,
          senderNickname: 'TestUser',
          content: '반갑습니다',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 5),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('안녕하세요'), findsOneWidget);
      expect(find.text('반갑습니다'), findsOneWidget);
    });

    testWidgets('shows loading indicator on send button when sending',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: const ChatRoomState(isSending: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows my message bubble', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          senderNickname: 'TestUser',
          content: '내 메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('내 메시지'), findsOneWidget);
    });

    testWidgets('shows other user message bubble with avatar', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: 'OtherUser',
          content: '상대방 메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('상대방 메시지'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows first letter of nickname in avatar', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: 'Alice',
          content: '메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows ? for empty sender nickname', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: '',
          content: '메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows ? for null sender nickname', (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: null,
          content: '메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('can type message in text field', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), '테스트 메시지');
      await tester.pump();

      expect(find.text('테스트 메시지'), findsOneWidget);
    });

    testWidgets('dispatches MessageSent when send button is tapped',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), '테스트 메시지');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const MessageSent('테스트 메시지'))).called(1);
    });

    testWidgets('does not send empty message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      verifyNever(() => mockChatRoomBloc.add(any(that: isA<MessageSent>())));
    });

    testWidgets('clears text field after sending message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), '테스트 메시지');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('sends message on keyboard submit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), '키보드 전송');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const MessageSent('키보드 전송'))).called(1);
    });

    testWidgets('shows date separator for messages on different days',
        (tester) async {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: 'OtherUser',
          content: '어제 메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 14, 10, 0),
        ),
        Message(
          id: 2,
          chatRoomId: 1,
          senderId: 2,
          senderNickname: 'OtherUser',
          content: '오늘 메시지',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        chatRoomState: ChatRoomState(
          status: ChatRoomStatus.success,
          messages: messages,
        ),
      ));

      expect(find.text('어제 메시지'), findsOneWidget);
      expect(find.text('오늘 메시지'), findsOneWidget);
    });

    testWidgets('tap attachment button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    });

    testWidgets('tap more options button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
    });
  });

  group('ChatRoomState', () {
    test('has correct initial values', () {
      const state = ChatRoomState();

      expect(state.status, ChatRoomStatus.initial);
      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
      expect(state.hasMore, isFalse);
    });

    test('copyWith works correctly', () {
      const state = ChatRoomState();
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Test',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final newState = state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        isSending: true,
      );

      expect(newState.status, ChatRoomStatus.success);
      expect(newState.messages, messages);
      expect(newState.isSending, isTrue);
    });

    test('loading state', () {
      const state = ChatRoomState(status: ChatRoomStatus.loading);

      expect(state.status, ChatRoomStatus.loading);
    });

    test('failure state with error message', () {
      const state = ChatRoomState(
        status: ChatRoomStatus.failure,
        errorMessage: 'Error',
      );

      expect(state.status, ChatRoomStatus.failure);
      expect(state.errorMessage, 'Error');
    });

    test('copyWith preserves values when not specified', () {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Test',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final state = ChatRoomState(
        status: ChatRoomStatus.success,
        messages: messages,
        isSending: true,
        hasMore: true,
        errorMessage: 'Error',
      );

      final newState = state.copyWith();

      expect(newState.status, ChatRoomStatus.success);
      expect(newState.messages, messages);
      expect(newState.isSending, isTrue);
      expect(newState.hasMore, isTrue);
      expect(newState.errorMessage, 'Error');
    });

    test('copyWith can update hasMore', () {
      const state = ChatRoomState();
      final newState = state.copyWith(hasMore: true);
      expect(newState.hasMore, isTrue);
    });

    test('copyWith can update errorMessage', () {
      const state = ChatRoomState();
      final newState = state.copyWith(errorMessage: 'New error');
      expect(newState.errorMessage, 'New error');
    });

    test('props contains all fields', () {
      final messages = [
        Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Test',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final state = ChatRoomState(
        status: ChatRoomStatus.success,
        messages: messages,
        isSending: true,
        hasMore: true,
        errorMessage: 'Error',
      );

      // props: status, roomId, currentUserId, messages, nextCursor, hasMore, isSending, errorMessage, typingUsers, isReadMarked
      expect(state.props.length, 10);
    });

    test('equality works', () {
      const state1 = ChatRoomState();
      const state2 = ChatRoomState();
      const state3 = ChatRoomState(status: ChatRoomStatus.loading);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('ChatRoomEvent', () {
    test('ChatRoomOpened has correct roomId', () {
      const event = ChatRoomOpened(1);
      expect(event.roomId, 1);
    });

    test('MessageSent has correct content', () {
      const event = MessageSent('Hello');
      expect(event.content, 'Hello');
    });

    test('ChatRoomClosed is const', () {
      const event = ChatRoomClosed();
      expect(event, isA<ChatRoomClosed>());
    });

    test('MessagesLoadMoreRequested is const', () {
      const event = MessagesLoadMoreRequested();
      expect(event, isA<MessagesLoadMoreRequested>());
    });

    test('ChatRoomOpened equality', () {
      const event1 = ChatRoomOpened(1);
      const event2 = ChatRoomOpened(1);
      const event3 = ChatRoomOpened(2);
      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('MessageSent equality', () {
      const event1 = MessageSent('Hello');
      const event2 = MessageSent('Hello');
      const event3 = MessageSent('World');
      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('ChatRoomOpened props contains roomId', () {
      const event = ChatRoomOpened(42);
      expect(event.props, contains(42));
    });

    test('MessageSent props contains content', () {
      const event = MessageSent('Test content');
      expect(event.props, contains('Test content'));
    });

    test('ChatRoomClosed props is empty', () {
      const event = ChatRoomClosed();
      expect(event.props, isEmpty);
    });

    test('MessagesLoadMoreRequested props is empty', () {
      const event = MessagesLoadMoreRequested();
      expect(event.props, isEmpty);
    });
  });

  group('ChatRoomStatus', () {
    test('has all expected values', () {
      expect(ChatRoomStatus.values.length, 4);
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.initial));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.loading));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.success));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.failure));
    });

    test('initial is first value', () {
      expect(ChatRoomStatus.values.first, ChatRoomStatus.initial);
    });
  });
}
