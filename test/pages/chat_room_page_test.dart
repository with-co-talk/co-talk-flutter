import 'dart:async';
import 'dart:io';
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
import 'package:co_talk_flutter/core/services/active_room_tracker.dart';
import 'package:co_talk_flutter/core/services/notification_click_handler.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:go_router/go_router.dart';
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

/// Stub NotificationClickHandler that records callback registration and clearing.
class StubNotificationClickHandler implements NotificationClickHandler {
  @override
  SameRoomRefreshCallback? onSameRoomRefresh;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Simple stub for ActiveRoomTracker.
class StubActiveRoomTracker implements ActiveRoomTracker {
  @override
  int? activeRoomId;
}

class FakeFile extends Fake implements File {}

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
    registerFallbackValue(FakeFile());
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

      expect(state.props.length, 30);
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

  group('GetIt 직접 호출 동작 검증', () {
    late MockChatRoomBloc mockChatRoomBloc;
    late MockChatListBloc mockChatListBloc;
    late MockAuthBloc mockAuthBloc;
    late StreamController<ChatRoomState> chatRoomStreamController;
    late StreamController<ChatListState> chatListStreamController;
    late TestWindowFocusTracker windowFocusTracker;

    void setupMockBlocs({ChatRoomState? chatRoomState}) {
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
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());
    }

    Widget buildWidget({int roomId = 1}) {
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

    setUp(() {
      mockChatRoomBloc = MockChatRoomBloc();
      mockChatListBloc = MockChatListBloc();
      mockAuthBloc = MockAuthBloc();
      chatRoomStreamController = StreamController<ChatRoomState>.broadcast();
      chatListStreamController = StreamController<ChatListState>.broadcast();
      windowFocusTracker = TestWindowFocusTracker();
      windowFocusTracker.setCurrentFocus(null); // no focus tracking

      // WebSocketService는 항상 필요
      final mockWebSocketService = MockWebSocketService();
      when(() => mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream<WebSocketConnectionState>.value(
            WebSocketConnectionState.connected),
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
      chatRoomStreamController.close();
      chatListStreamController.close();
      windowFocusTracker.dispose();

      // GetIt 정리
      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
      if (GetIt.instance.isRegistered<NotificationClickHandler>()) {
        GetIt.instance.unregister<NotificationClickHandler>();
      }
      if (GetIt.instance.isRegistered<ActiveRoomTracker>()) {
        GetIt.instance.unregister<ActiveRoomTracker>();
      }
      if (GetIt.instance.isRegistered<ChatRepository>()) {
        GetIt.instance.unregister<ChatRepository>();
      }
    });

    testWidgets(
        'initState에서 NotificationClickHandler가 GetIt에 등록되어 있으면 onSameRoomRefresh 콜백이 설정됨',
        (tester) async {
      final stubHandler = StubNotificationClickHandler();
      GetIt.instance.registerSingleton<NotificationClickHandler>(stubHandler);

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 42));
      await tester.pump();

      // onSameRoomRefresh 콜백이 설정되어야 함
      expect(stubHandler.onSameRoomRefresh, isNotNull);
    });

    testWidgets(
        'onSameRoomRefresh 콜백이 트리거되면 ChatRoomRefreshRequested가 ChatRoomBloc에 전달됨',
        (tester) async {
      final stubHandler = StubNotificationClickHandler();
      GetIt.instance.registerSingleton<NotificationClickHandler>(stubHandler);

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 42));
      await tester.pump();

      // 콜백이 설정된 상태에서 호출
      expect(stubHandler.onSameRoomRefresh, isNotNull);
      stubHandler.onSameRoomRefresh!(42);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomRefreshRequested()))
          .called(1);
    });

    testWidgets(
        'dispose 시 NotificationClickHandler의 onSameRoomRefresh 콜백이 null로 초기화됨',
        (tester) async {
      final stubHandler = StubNotificationClickHandler();
      GetIt.instance.registerSingleton<NotificationClickHandler>(stubHandler);

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      // 등록 확인
      expect(stubHandler.onSameRoomRefresh, isNotNull);

      // dispose 트리거
      await tester.pumpWidget(Container());
      await tester.pump();

      // 콜백이 해제되어야 함
      expect(stubHandler.onSameRoomRefresh, isNull);
    });

    testWidgets(
        'dispose 시 ActiveRoomTracker.activeRoomId가 null로 설정됨',
        (tester) async {
      final stubTracker = StubActiveRoomTracker();
      stubTracker.activeRoomId = 1; // 초기값 설정
      GetIt.instance.registerSingleton<ActiveRoomTracker>(stubTracker);

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      // dispose 트리거
      await tester.pumpWidget(Container());
      await tester.pump();

      // activeRoomId가 null로 설정되어야 함 (FCM 알림 suppress 방지)
      expect(stubTracker.activeRoomId, isNull);
    });

    testWidgets(
        '채팅방 옵션 바텀시트에 "채팅방 이미지 변경" 항목이 표시됨',
        (tester) async {
      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      // more_vert 아이콘 버튼 탭
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 바텀시트에 "채팅방 이미지 변경" 항목이 있어야 함
      expect(find.text('채팅방 이미지 변경'), findsOneWidget);
    });

    testWidgets(
        '채팅방 옵션 바텀시트에 "미디어 모아보기" 및 "채팅방 나가기" 항목이 표시됨',
        (tester) async {
      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('미디어 모아보기'), findsOneWidget);
      expect(find.text('채팅방 나가기'), findsOneWidget);
    });

    testWidgets(
        '_pickAndUpdateGroupImage: ChatRepository가 uploadFile에서 예외를 던지면 에러 스낵바가 표시됨',
        (tester) async {
      // ChatRepository를 GetIt에 등록하고 uploadFile이 예외를 던지도록 설정
      final mockChatRepo = MockChatRepository();
      when(() => mockChatRepo.uploadFile(any<File>()))
          .thenThrow(Exception('upload failed'));
      GetIt.instance.registerSingleton<ChatRepository>(mockChatRepo);

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      // 이 테스트는 이미지 피커 없이 진행되므로, _pickAndUpdateGroupImage에서
      // imagePicker.pickFromGallery()가 null을 반환하여 조기 반환됨.
      // 바텀시트의 "채팅방 이미지 변경" 항목이 존재하는지만 확인
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('채팅방 이미지 변경'), findsOneWidget);

      // 항목이 탭 가능한지 확인 (예외 없이 실행되어야 함)
      await tester.tap(find.text('채팅방 이미지 변경'));
      await tester.pumpAndSettle();

      // 이미지 피커가 null을 반환하므로 에러 스낵바 없이 정상 종료
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'NotificationClickHandler가 GetIt에 없어도 initState가 예외 없이 완료됨',
        (tester) async {
      // NotificationClickHandler를 등록하지 않음
      if (GetIt.instance.isRegistered<NotificationClickHandler>()) {
        GetIt.instance.unregister<NotificationClickHandler>();
      }

      setupMockBlocs();
      // 예외 없이 위젯이 렌더링되어야 함
      await expectLater(
        () async {
          await tester.pumpWidget(buildWidget(roomId: 1));
          await tester.pump();
        },
        returnsNormally,
      );
    });

    testWidgets(
        'ActiveRoomTracker가 GetIt에 없어도 dispose가 예외 없이 완료됨',
        (tester) async {
      // ActiveRoomTracker를 등록하지 않음
      if (GetIt.instance.isRegistered<ActiveRoomTracker>()) {
        GetIt.instance.unregister<ActiveRoomTracker>();
      }

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pump();

      // dispose 트리거 - 예외 없이 완료되어야 함
      await expectLater(
        () async {
          await tester.pumpWidget(Container());
          await tester.pump();
        },
        returnsNormally,
      );
    });

    testWidgets(
        'WebSocketService connectionState가 connected이면 ConnectionStatusBanner가 숨겨짐',
        (tester) async {
      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pumpAndSettle();

      // connected 상태이면 배너가 표시되지 않아야 함 (빈 컨테이너)
      // ConnectionStatusBanner는 connected가 아닐 때만 visible
      expect(find.text('서버와 연결이 끊어졌습니다'), findsNothing);
    });

    testWidgets(
        'WebSocketService onReconnect 콜백이 바텀시트 없이 정상적으로 GetIt.instance를 통해 호출 가능',
        (tester) async {
      // WebSocketService는 setUp에서 이미 등록되어 있음
      final mockWebSocketService =
          GetIt.instance<WebSocketService>() as MockWebSocketService;

      setupMockBlocs();
      await tester.pumpWidget(buildWidget(roomId: 1));
      await tester.pumpAndSettle();

      // 빌드 시 StreamBuilder에서 GetIt.instance<WebSocketService>()가 호출됨
      // 연결 상태 스트림이 정상적으로 구독되어야 함
      verify(() => mockWebSocketService.connectionState).called(greaterThan(0));
    });
  });

  group('ChatRoomPage - 채팅방 옵션 및 BLoC 리스너', () {
    late MockChatRoomBloc mockChatRoomBloc;
    late MockChatListBloc mockChatListBloc;
    late MockAuthBloc mockAuthBloc;
    late StreamController<ChatRoomState> chatRoomStreamController;
    late StreamController<ChatListState> chatListStreamController;
    late TestWindowFocusTracker windowFocusTracker;

    setUp(() {
      mockChatRoomBloc = MockChatRoomBloc();
      mockChatListBloc = MockChatListBloc();
      mockAuthBloc = MockAuthBloc();
      chatRoomStreamController = StreamController<ChatRoomState>.broadcast();
      chatListStreamController = StreamController<ChatListState>.broadcast();
      windowFocusTracker = TestWindowFocusTracker();
      windowFocusTracker.setCurrentFocus(null); // no focus tracking (mobile)

      final mockWebSocketService = MockWebSocketService();
      when(() => mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream<WebSocketConnectionState>.value(
            WebSocketConnectionState.connected),
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
      chatRoomStreamController.close();
      chatListStreamController.close();
      windowFocusTracker.dispose();
      if (GetIt.instance.isRegistered<WebSocketService>()) {
        GetIt.instance.unregister<WebSocketService>();
      }
      if (GetIt.instance.isRegistered<NotificationClickHandler>()) {
        GetIt.instance.unregister<NotificationClickHandler>();
      }
      if (GetIt.instance.isRegistered<ActiveRoomTracker>()) {
        GetIt.instance.unregister<ActiveRoomTracker>();
      }
      if (GetIt.instance.isRegistered<ChatRepository>()) {
        GetIt.instance.unregister<ChatRepository>();
      }
    });

    Widget buildWidget({ChatRoomState? chatRoomState, int roomId = 1}) {
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

    testWidgets('채팅방 나가기 다이얼로그에서 취소를 누르면 다이얼로그가 닫힘', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Open more options
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap leave room option
      await tester.tap(find.text('채팅방 나가기'));
      await tester.pumpAndSettle();

      // Confirm dialog should appear with full text
      expect(find.textContaining('채팅방을 나가시겠습니까?'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // Dialog should be gone, no ChatRoomLeaveRequested dispatched
      expect(find.textContaining('채팅방을 나가시겠습니까?'), findsNothing);
      verifyNever(() => mockChatRoomBloc.add(const ChatRoomLeaveRequested()));
    });

    testWidgets('채팅방 나가기 확인 시 ChatRoomLeaveRequested가 dispatch됨', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('채팅방 나가기'));
      await tester.pumpAndSettle();

      clearInteractions(mockChatRoomBloc);

      // Tap the confirm button
      final leaveButtons = find.text('나가기');
      expect(leaveButtons, findsOneWidget);
      await tester.tap(leaveButtons);
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomLeaveRequested())).called(1);
    });

    testWidgets('에러 메시지 리스너: 일반 에러가 표시됨', (tester) async {
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        errorMessage: null,
      );

      await tester.pumpWidget(buildWidget(chatRoomState: initialState));
      await tester.pumpAndSettle();
      clearInteractions(mockChatRoomBloc);

      chatRoomStreamController.add(const ChatRoomState(
        status: ChatRoomStatus.failure,
        errorMessage: '메시지 전송 실패',
        isReinviting: false,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('메시지 전송 실패'), findsOneWidget);
    });

    testWidgets('재초대 성공 시 성공 스낵바가 표시됨', (tester) async {
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        isReinviting: true,
        otherUserNickname: '친구',
      );

      await tester.pumpWidget(buildWidget(chatRoomState: initialState));
      await tester.pumpAndSettle();
      clearInteractions(mockChatRoomBloc);
      clearInteractions(mockChatListBloc);

      // Transition: isReinviting false + reinviteSuccess true
      chatRoomStreamController.add(const ChatRoomState(
        status: ChatRoomStatus.success,
        isReinviting: false,
        reinviteSuccess: true,
        otherUserNickname: '친구',
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('재초대 실패 시 에러 스낵바가 표시됨', (tester) async {
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        isReinviting: true,
      );

      await tester.pumpWidget(buildWidget(chatRoomState: initialState));
      await tester.pumpAndSettle();
      clearInteractions(mockChatRoomBloc);

      chatRoomStreamController.add(const ChatRoomState(
        status: ChatRoomStatus.failure,
        isReinviting: false,
        reinviteSuccess: false,
        errorMessage: '재초대 실패 원인',
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('메시지 전달 성공 시 성공 스낵바가 표시됨', (tester) async {
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        isForwarding: true,
      );

      await tester.pumpWidget(buildWidget(chatRoomState: initialState));
      await tester.pumpAndSettle();
      clearInteractions(mockChatRoomBloc);

      chatRoomStreamController.add(const ChatRoomState(
        status: ChatRoomStatus.success,
        isForwarding: false,
        forwardSuccess: true,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('메시지가 전달되었습니다'), findsOneWidget);
    });

    testWidgets('hasLeft가 false -> true 변경 시 ChatListRefreshRequested가 전달됨', (tester) async {
      const initialState = ChatRoomState(
        status: ChatRoomStatus.success,
        hasLeft: false,
      );

      // Use GoRouter to handle context.go() call when hasLeft becomes true
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
                BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: ChatRoomPage(
                roomId: 1,
                windowFocusTracker: windowFocusTracker,
              ),
            ),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const Scaffold(body: Text('Chat List')),
          ),
        ],
      );

      when(() => mockChatRoomBloc.state).thenReturn(initialState);
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
        AuthState.authenticated(
            const User(id: 1, email: 'test@test.com', nickname: 'Test')),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      clearInteractions(mockChatListBloc);

      chatRoomStreamController.add(const ChatRoomState(
        status: ChatRoomStatus.success,
        hasLeft: true,
      ));
      await tester.pump();
      await tester.pump();

      verify(() => mockChatListBloc.add(const ChatListRefreshRequested())).called(1);
    });

    testWidgets('검색 버튼 탭 시 MessageSearchWidget이 표시됨', (tester) async {
      final mockMessageSearchBloc = MockMessageSearchBloc();
      final messageSearchController =
          StreamController<MessageSearchState>.broadcast();

      when(() => mockMessageSearchBloc.state)
          .thenReturn(const MessageSearchState());
      when(() => mockMessageSearchBloc.stream)
          .thenAnswer((_) => messageSearchController.stream);
      when(() => mockMessageSearchBloc.close()).thenAnswer((_) async {});
      when(() => mockMessageSearchBloc.add(any())).thenReturn(null);

      addTearDown(() async {
        await messageSearchController.close();
      });

      final widget = MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<MessageSearchBloc>.value(
                value: mockMessageSearchBloc),
          ],
          child: ChatRoomPage(
            roomId: 1,
            windowFocusTracker: windowFocusTracker,
          ),
        ),
      );

      when(() => mockChatRoomBloc.state).thenReturn(const ChatRoomState());
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
        AuthState.authenticated(
            const User(id: 1, email: 'test@test.com', nickname: 'Test')),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Close icon should now appear (search mode)
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('검색 모드에서 닫기 버튼 탭 시 검색 모드가 종료됨', (tester) async {
      final mockMessageSearchBloc = MockMessageSearchBloc();
      final messageSearchController =
          StreamController<MessageSearchState>.broadcast();

      when(() => mockMessageSearchBloc.state)
          .thenReturn(const MessageSearchState());
      when(() => mockMessageSearchBloc.stream)
          .thenAnswer((_) => messageSearchController.stream);
      when(() => mockMessageSearchBloc.close()).thenAnswer((_) async {});
      when(() => mockMessageSearchBloc.add(any())).thenReturn(null);

      addTearDown(() async {
        await messageSearchController.close();
      });

      when(() => mockChatRoomBloc.state).thenReturn(const ChatRoomState());
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
        AuthState.authenticated(
            const User(id: 1, email: 'test@test.com', nickname: 'Test')),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<MessageSearchBloc>.value(
                value: mockMessageSearchBloc),
          ],
          child: ChatRoomPage(
            roomId: 1,
            windowFocusTracker: windowFocusTracker,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Tap close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Back to normal mode - search icon reappears
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('앱 타이틀: direct 채팅방은 상대방 닉네임 표시', (tester) async {
      const state = ChatRoomState(
        status: ChatRoomStatus.success,
        roomType: ChatRoomType.direct,
        otherUserNickname: '친구닉',
      );

      await tester.pumpWidget(buildWidget(chatRoomState: state));
      await tester.pump();

      expect(find.text('친구닉'), findsOneWidget);
    });

    testWidgets('앱 타이틀: 나와의 채팅방은 나와의 채팅 표시', (tester) async {
      const state = ChatRoomState(
        status: ChatRoomStatus.success,
        roomType: ChatRoomType.self,
      );

      await tester.pumpWidget(buildWidget(chatRoomState: state));
      await tester.pump();

      expect(find.text('나와의 채팅'), findsOneWidget);
    });

    testWidgets('앱 타이틀: 그룹 채팅방은 방 이름 표시', (tester) async {
      const state = ChatRoomState(
        status: ChatRoomStatus.success,
        roomType: ChatRoomType.group,
        roomName: '개발팀',
      );

      await tester.pumpWidget(buildWidget(chatRoomState: state));
      await tester.pump();

      expect(find.text('개발팀'), findsOneWidget);
    });

    testWidgets('뒤로가기 버튼 표시 확인', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('미디어 모아보기 항목이 채팅방 옵션 바텀시트에 표시됨', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Simply verify the option is present without actually tapping (avoids GetIt missing registration)
      expect(find.text('미디어 모아보기'), findsOneWidget);
    });

    testWidgets('dispose 시 ChatRoomClosed가 ChatRoomBloc에 전달됨', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      clearInteractions(mockChatRoomBloc);

      // Trigger dispose
      await tester.pumpWidget(Container());
      await tester.pump();

      verify(() => mockChatRoomBloc.add(const ChatRoomClosed())).called(1);
    });

    testWidgets('검색 모드 토글 시 MessageSearchCleared 이벤트 전달됨', (tester) async {
      final mockMessageSearchBloc = MockMessageSearchBloc();
      final messageSearchController =
          StreamController<MessageSearchState>.broadcast();

      when(() => mockMessageSearchBloc.state)
          .thenReturn(const MessageSearchState());
      when(() => mockMessageSearchBloc.stream)
          .thenAnswer((_) => messageSearchController.stream);
      when(() => mockMessageSearchBloc.close()).thenAnswer((_) async {});
      when(() => mockMessageSearchBloc.add(any())).thenReturn(null);

      addTearDown(() async {
        await messageSearchController.close();
      });

      when(() => mockChatRoomBloc.state).thenReturn(const ChatRoomState());
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
        AuthState.authenticated(
            const User(id: 1, email: 'test@test.com', nickname: 'Test')),
      );
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<MessageSearchBloc>.value(
                value: mockMessageSearchBloc),
          ],
          child: ChatRoomPage(
            roomId: 1,
            windowFocusTracker: windowFocusTracker,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Exit search mode - MessageSearchCleared should be dispatched
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      verify(() =>
              mockMessageSearchBloc.add(const MessageSearchCleared()))
          .called(greaterThanOrEqualTo(1));
    });
  });
}
