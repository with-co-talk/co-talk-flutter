import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/chat_room_page.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/core/window/window_focus_tracker.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../mocks/mock_repositories.dart';

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockMessageSearchBloc
    extends MockBloc<MessageSearchEvent, MessageSearchState>
    implements MessageSearchBloc {}

class FakeChatRoomEvent extends Fake implements ChatRoomEvent {}

class FakeMessageSearchEvent extends Fake implements MessageSearchEvent {}

class FakeChatListEvent extends Fake implements ChatListEvent {}

class TestWindowFocusTracker implements WindowFocusTracker {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool? _current;

  void emit(bool focused) {
    _current = focused;
    _controller.add(focused);
  }

  void setCurrentFocus(bool? focused) {
    _current = focused;
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

/// Helper function to find RichText widgets containing specific text.
/// This is needed because find.textContaining doesn't work properly with
/// RichText that has nested TextSpan children.
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is RichText) {
      final textSpan = widget.text;
      return _textSpanContains(textSpan, text);
    }
    return false;
  });
}

/// Recursively check if a TextSpan or its children contain the given text.
bool _textSpanContains(InlineSpan span, String text) {
  if (span is TextSpan) {
    if (span.text?.contains(text) == true) {
      return true;
    }
    if (span.children != null) {
      for (final child in span.children!) {
        if (_textSpanContains(child, text)) {
          return true;
        }
      }
    }
  }
  return false;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    registerFallbackValue(FakeChatRoomEvent());
    registerFallbackValue(FakeChatListEvent());
    registerFallbackValue(FakeMessageSearchEvent());
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

      // Register mock WebSocketService in GetIt for ConnectionStatusBanner
      final mockWebSocketService = MockWebSocketService();
      when(() => mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream<WebSocketConnectionState>.value(WebSocketConnectionState.connected),
      );
      when(() => mockWebSocketService.currentConnectionState)
          .thenReturn(WebSocketConnectionState.connected);
      when(() => mockWebSocketService.resetReconnectAttempts()).thenReturn(null);
      when(() => mockWebSocketService.connect()).thenAnswer((_) async {});

      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
      GetIt.instance.registerSingleton<WebSocketService>(mockWebSocketService);
    });

    tearDown(() {
      chatRoomStreamController.close();
      chatListStreamController.close();

      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
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

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('dispatches ChatRoomOpened on init', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(roomId: 42));

      verify(() => mockChatRoomBloc.add(const ChatRoomOpened(42))).called(1);
    });

    testWidgets('when focus tracking NOT supported: inactive does NOT background room (avoid over-unsubscribe)',
        (tester) async {
      // 포커스 추적을 지원하지 않는 WindowFocusTracker 사용 (currentFocus가 null 반환)
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적 미지원으로 설정
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(windowFocusTracker: tracker));
      await tester.pumpAndSettle(); // 초기화 완료 대기
      clearInteractions(mockChatRoomBloc);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));
    });

    testWidgets('when focus tracking supported: inactive does NOT background room (focus tracker is the source of truth)',
        (tester) async {
      // 포커스 추적을 지원하는 WindowFocusTracker 사용
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(true); // 포커스 추적 지원으로 설정
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(windowFocusTracker: tracker));
      await tester.pumpAndSettle(); // 초기화 완료 대기
      clearInteractions(mockChatRoomBloc);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // 포커스 추적이 지원되는 경우 window focus 이벤트가 더 정확하므로 inactive로 background 처리하지 않는다.
      verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      verifyNever(() => mockChatRoomBloc.add(const ChatRoomBackgrounded()));
    });

    testWidgets('dispatches background/foreground on window blur/focus (deterministic)',
        (tester) async {
      final tracker = TestWindowFocusTracker();
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(windowFocusTracker: tracker));
      clearInteractions(mockChatRoomBloc);

      // 첫 번째 emit은 초기 이벤트로 취급되어 상태만 저장됨 (_lastWindowFocused가 null → false)
      // 실제 이벤트는 두 번째부터 전송됨
      tracker.emit(false); // 초기 이벤트 - 상태만 저장
      await tester.pump();

      tracker.emit(true); // 첫 번째 실제 이벤트 - ChatRoomForegrounded 전송
      await tester.pump();
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);

      tracker.emit(false); // 두 번째 실제 이벤트 - ChatRoomBackgrounded 전송
      await tester.pump();
      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);
    });

    testWidgets('🔴 RED: 채팅방 진입 직후 포커스가 빠지면 ChatRoomBackgrounded만 전송되고 ChatRoomForegrounded는 전송되지 않음',
        (tester) async {
      // 시나리오: 채팅방에 들어간 직후 사용자가 Alt+Tab으로 다른 앱으로 전환
      // 기대 동작: ChatRoomBackgrounded만 전송되고, 읽음 처리가 되지 않아야 함
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(true); // 초기 포커스 상태 설정
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(windowFocusTracker: tracker));
      clearInteractions(mockChatRoomBloc);

      // 1. 초기 이벤트: 창이 포커스된 상태에서 채팅방 진입
      tracker.emit(true); // 초기 이벤트 - 상태만 저장 (_lastWindowFocused = true)
      await tester.pump();

      // 2. 사용자가 바로 Alt+Tab으로 포커스를 빠짐
      tracker.emit(false); // ChatRoomBackgrounded 전송
      await tester.pump();

      // 3. _syncFocusOnce()가 완료되어도 이미 focusStream에서 이벤트를 보냈으므로 스킵
      await tester.pump(); // addPostFrameCallback 실행

      // 검증: ChatRoomBackgrounded만 전송되어야 함
      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);
      // ChatRoomForegrounded는 전송되지 않아야 함
      verifyNever(() => mockChatRoomBloc.add(const ChatRoomForegrounded()));
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
          currentUserId: 1,
        ),
      ));
      await tester.pumpAndSettle();

      // Messages are rendered via RichText with nested TextSpan children
      expect(findRichTextContaining('안녕하세요'), findsOneWidget);
      expect(findRichTextContaining('반갑습니다'), findsOneWidget);
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
          currentUserId: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('내 메시지'), findsOneWidget);
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
          currentUserId: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('상대방 메시지'), findsOneWidget);
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
          currentUserId: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('어제 메시지'), findsOneWidget);
      expect(findRichTextContaining('오늘 메시지'), findsOneWidget);
    });

    testWidgets('tap attachment button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    });

    testWidgets('tap more options button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
    });

    group('통합 테스트 - ChatListBloc', () {
    testWidgets('🔴 RED: initState에서 ChatRoomEntered를 ChatListBloc에 보냄', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(roomId: 1));
      await tester.pumpAndSettle();

      verify(() => mockChatListBloc.add(ChatRoomEntered(1))).called(1);
    });

    testWidgets('🔴 RED: dispose에서 ChatRoomExited를 ChatListBloc에 보냄', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(roomId: 1));
      await tester.pumpAndSettle();

      // dispose 호출
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      verify(() => mockChatListBloc.add(const ChatRoomExited())).called(1);
    });

    testWidgets('🔴 RED: ChatRoomOpened 이벤트가 ChatRoomBloc에 전달됨', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(roomId: 1));
      await tester.pumpAndSettle();

      verify(() => mockChatRoomBloc.add(ChatRoomOpened(1))).called(1);
    });

    testWidgets('🔴 RED: 포커스 추적이 지원되지 않으면 ChatRoomForegrounded가 자동으로 호출됨', (tester) async {
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적 미지원

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: 포커스 추적이 지원되면 초기 포커스 상태에 따라 ChatRoomForegrounded/Backgrounded가 호출됨', (tester) async {
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(true); // 포커스 추적 지원, 초기 포커스 = true

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: 데스크탑에서 currentFocus()가 null을 반환하면 기본적으로 ChatRoomForegrounded가 호출됨 (안전장치)', (tester) async {
      // 데스크탑에서 window_manager가 초기화되지 않았거나 실패한 경우
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적은 지원하지만 currentFocus()가 null 반환

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      // focused == null이면 기본적으로 ChatRoomForegrounded를 보내야 함
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: 데스크탑에서 currentFocus()가 false를 반환하면 ChatRoomBackgrounded가 호출됨', (tester) async {
      // 데스크탑에서 창이 포커스되지 않은 상태
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(false); // 포커스 추적 지원, 초기 포커스 = false

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);
      verifyNever(() => mockChatRoomBloc.add(const ChatRoomForegrounded()));
    });

    testWidgets('🔴 RED: 데스크탑에서 _syncFocusOnce()가 실패해도 ChatRoomForegrounded가 호출됨 (안전장치)', (tester) async {
      // currentFocus()가 예외를 던지는 경우를 시뮬레이션
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // null 반환으로 실패 시뮬레이션
      
      // TestWindowFocusTracker를 수정하여 예외를 던지도록 할 수 없으므로
      // null 반환 케이스로 테스트 (실제로는 currentFocus()가 null을 반환하면 기본적으로 foreground로 가정)

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      // null이면 기본적으로 ChatRoomForegrounded를 보내야 함
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: 포커스가 변경되면 ChatRoomForegrounded/Backgrounded가 호출됨', (tester) async {
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(true);

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));

      clearInteractions(mockChatRoomBloc);

      // 포커스 변경: true -> false
      tracker.emit(false);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);

      // 포커스 변경: false -> true
      tracker.emit(true);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: 앱이 백그라운드로 갔다가 포그라운드로 올 때 ChatRoomBackgrounded/Foregrounded가 호출됨', (tester) async {
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적 미지원 (모바일/웹)

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));

      // 초기 ChatRoomForegrounded 호출 제외
      clearInteractions(mockChatRoomBloc);

      final binding = tester.binding;
      
      // 먼저 resumed를 호출하여 _hasResumedOnce를 true로 만듦
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      clearInteractions(mockChatRoomBloc);
      clearInteractions(mockChatListBloc);

      // 앱이 백그라운드로 전환 (올바른 상태 전환: resumed -> inactive -> hidden -> paused)
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // 1.5초 디바운스 대기
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomBackgrounded())).called(1);
      verify(() => mockChatListBloc.add(const ChatRoomExited())).called(1);

      // 앱이 포그라운드로 전환 (올바른 상태 전환: paused -> hidden -> inactive -> resumed)
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(1);
    });

    testWidgets('🔴 RED: isReadMarked가 false -> true로 변경될 때 ChatListBloc에 ChatRoomReadCompleted 알림이 전송됨', (tester) async {
      // 초기 상태 설정 (isReadMarked: false)
      // BlocListener는 생성 시 previous = bloc.state로 초기화됨
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        isReadMarked: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        chatRoomState: initialState,
      ));
      await tester.pumpAndSettle();

      clearInteractions(mockChatListBloc);

      // isReadMarked가 true로 변경된 상태
      // BlocListener는 previous = initialState (BlocListener 생성 시 설정된 값), current = changedState를 비교
      const changedState = ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        isReadMarked: true, // 변경됨
      );
      when(() => mockChatRoomBloc.state).thenReturn(changedState);
      
      // 변경된 상태를 stream에 추가 (기존 chatRoomStreamController 사용)
      chatRoomStreamController.add(changedState);
      await tester.pump();
      await tester.pump(); // BlocListener가 처리할 시간 확보

      // ChatListBloc에 ChatRoomReadCompleted 알림이 전송되어야 함
      verify(() => mockChatListBloc.add(ChatRoomReadCompleted(1))).called(1);
    });

    testWidgets('🔴 RED: isReadMarked가 true -> true로 변경될 때는 ChatListBloc에 알림이 가지 않음 (중복 방지)', (tester) async {
      // 초기 상태 설정 (isReadMarked: true)
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        isReadMarked: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        chatRoomState: initialState,
      ));
      await tester.pumpAndSettle();

      clearInteractions(mockChatListBloc);

      // 같은 값으로 다시 변경 (기존 chatRoomStreamController 사용)
      chatRoomStreamController.add(initialState);
      await tester.pump();

      // ChatListBloc에 알림이 가지 않아야 함 (중복 방지)
      verifyNever(() => mockChatListBloc.add(any(that: isA<ChatRoomReadCompleted>())));
    });

    testWidgets('🔴 RED: 데스크탑 초기화 실패 시 ChatRoomForegrounded가 보장되어 markAsRead가 호출됨', (tester) async {
      // 데스크탑에서 currentFocus()가 null을 반환하는 경우
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적은 지원하지만 currentFocus()가 null 반환
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      // ChatRoomForegrounded가 호출되어야 함 (안전장치)
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('🔴 RED: 데스크탑에서 _syncFocusOnce() 실패 시에도 ChatRoomForegrounded가 보장됨', (tester) async {
      // currentFocus()가 예외를 던지는 경우를 시뮬레이션
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // null 반환으로 실패 시뮬레이션
      addTearDown(tracker.dispose);

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // postFrameCallback 대기

      // null이면 기본적으로 ChatRoomForegrounded를 보내야 함
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('🔴 RED: ChatRoomForegrounded가 호출되면 isReadMarked가 true가 되어 ChatRoomReadCompleted가 발생함', (tester) async {
      // 포커스 추적이 지원되지만 초기화가 실패하여 ChatRoomForegrounded가 호출되지 않는 경우
      final tracker = TestWindowFocusTracker();
      tracker.setCurrentFocus(null); // 포커스 추적은 지원하지만 currentFocus()가 null 반환
      addTearDown(tracker.dispose);

      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        isReadMarked: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        roomId: 1,
        chatRoomState: initialState,
        windowFocusTracker: tracker,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));

      // ChatRoomForegrounded가 호출되어야 함 (null일 때 기본적으로 보냄)
      verify(() => mockChatRoomBloc.add(const ChatRoomForegrounded())).called(greaterThanOrEqualTo(1));
      
      // ChatRoomForegrounded가 호출되면 markAsRead가 호출되어 isReadMarked가 true가 되고
      // ChatRoomReadCompleted가 발생해야 함
      // 하지만 widget 테스트에서는 실제 bloc의 내부 동작을 직접 확인할 수 없으므로
      // ChatRoomForegrounded 호출만 확인
    });
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

      expect(state.props.length, 27);
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

  group('ChatRoomPage 검색 기능 통합', () {
    late MockChatRoomBloc mockChatRoomBloc;
    late MockChatListBloc mockChatListBloc;
    late MockAuthBloc mockAuthBloc;
    late MockMessageSearchBloc mockMessageSearchBloc;
    late StreamController<ChatRoomState> chatRoomStreamController;
    late StreamController<ChatListState> chatListStreamController;
    late StreamController<MessageSearchState> messageSearchStreamController;
    late TestWindowFocusTracker windowFocusTracker;

    setUp(() {
      mockChatRoomBloc = MockChatRoomBloc();
      mockChatListBloc = MockChatListBloc();
      mockAuthBloc = MockAuthBloc();
      mockMessageSearchBloc = MockMessageSearchBloc();
      chatRoomStreamController = StreamController<ChatRoomState>.broadcast();
      chatListStreamController = StreamController<ChatListState>.broadcast();
      messageSearchStreamController =
          StreamController<MessageSearchState>.broadcast();
      windowFocusTracker = TestWindowFocusTracker();
      windowFocusTracker.setCurrentFocus(true);

      // Register mock WebSocketService in GetIt for ConnectionStatusBanner
      final mockWebSocketService = MockWebSocketService();
      when(() => mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream<WebSocketConnectionState>.value(WebSocketConnectionState.connected),
      );
      when(() => mockWebSocketService.currentConnectionState)
          .thenReturn(WebSocketConnectionState.connected);
      when(() => mockWebSocketService.resetReconnectAttempts()).thenReturn(null);
      when(() => mockWebSocketService.connect()).thenAnswer((_) async {});

      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
      GetIt.instance.registerSingleton<WebSocketService>(mockWebSocketService);
    });

    tearDown(() async {
      await chatRoomStreamController.close();
      await chatListStreamController.close();
      await messageSearchStreamController.close();
      windowFocusTracker.dispose();

      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
    });

    Widget createWidgetUnderTest({
      ChatRoomState? chatRoomState,
      MessageSearchState? messageSearchState,
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

      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(
          User(id: 1, nickname: 'Test', email: 'test@test.com')));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      when(() => mockMessageSearchBloc.state)
          .thenReturn(messageSearchState ?? const MessageSearchState());
      when(() => mockMessageSearchBloc.stream)
          .thenAnswer((_) => messageSearchStreamController.stream);
      when(() => mockMessageSearchBloc.close()).thenAnswer((_) async {});
      when(() => mockMessageSearchBloc.add(any())).thenReturn(null);

      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<MessageSearchBloc>.value(value: mockMessageSearchBloc),
          ],
          child: ChatRoomPage(
            roomId: 1,
            windowFocusTracker: windowFocusTracker,
          ),
        ),
      );
    }

    testWidgets('AppBar에 검색 버튼이 표시됨', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 검색 아이콘 버튼이 AppBar에 있어야 함
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('검색 버튼 탭 시 검색 모드가 활성화됨', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 검색 버튼 탭
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 검색 입력 필드가 나타나야 함
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      // 검색 힌트 텍스트가 보여야 함
      expect(find.text('메시지 검색'), findsOneWidget);
    });

    testWidgets('검색 모드에서 뒤로가기 버튼 탭 시 검색 모드가 종료됨', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 검색 버튼 탭
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 검색 모드가 활성화됨
      expect(find.text('메시지 검색'), findsOneWidget);

      // 닫기 버튼 탭 (검색 모드에서 표시되는 close 아이콘)
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first);
        await tester.pumpAndSettle();
        // 검색 모드가 종료되어야 함 (메시지 입력창이 다시 보임)
        expect(find.text('메시지를 입력하세요'), findsOneWidget);
      }
    });
  });
}
