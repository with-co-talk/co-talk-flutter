import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

void main() {
  late MockChatRoomBloc mockChatRoomBloc;

  setUpAll(() {
    registerFallbackValue(const ReinviteUserRequested(inviteeId: 0));
  });

  setUp(() {
    mockChatRoomBloc = MockChatRoomBloc();
  });

  void setupBloc({
    bool isSending = false,
    bool isUploadingFile = false,
    bool isOtherUserLeft = false,
    String? otherUserNickname,
    int? otherUserId,
    bool isReinviting = false,
  }) {
    final state = ChatRoomState(
      status: ChatRoomStatus.success,
      roomId: 1,
      currentUserId: 1,
      hasMore: false,
      isSending: isSending,
      isUploadingFile: isUploadingFile,
      isOtherUserLeft: isOtherUserLeft,
      otherUserNickname: otherUserNickname,
      otherUserId: otherUserId,
      isReinviting: isReinviting,
    );
    whenListen(
      mockChatRoomBloc,
      Stream.value(state),
      initialState: state,
    );
  }

  Widget createTestWidget({
    TextEditingController? controller,
    FocusNode? focusNode,
    VoidCallback? onSend,
    VoidCallback? onChanged,
    Message? replyToMessage,
    VoidCallback? onCancelReply,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ChatRoomBloc>.value(
          value: mockChatRoomBloc,
          child: MessageInput(
            controller: controller ?? TextEditingController(),
            focusNode: focusNode ?? FocusNode(),
            onSend: onSend ?? () {},
            onChanged: onChanged,
            replyToMessage: replyToMessage,
            onCancelReply: onCancelReply,
          ),
        ),
      ),
    );
  }

  group('MessageInput Text Field Tests', () {
    testWidgets('should render text field with hint text',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('메시지를 입력하세요'), findsOneWidget);
    });

    testWidgets('should render attachment button',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('should render send button',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should update text field when user types',
        (WidgetTester tester) async {
      setupBloc();
      final controller = TextEditingController();

      await tester.pumpWidget(createTestWidget(controller: controller));

      await tester.enterText(find.byType(TextField), 'Hello');
      expect(controller.text, 'Hello');
    });

    testWidgets('should call onChanged when text changes',
        (WidgetTester tester) async {
      setupBloc();
      bool onChangedCalled = false;

      await tester.pumpWidget(
        createTestWidget(onChanged: () => onChangedCalled = true),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      expect(onChangedCalled, isTrue);
    });
  });

  group('MessageInput Send Button State Tests', () {
    testWidgets('send button should be disabled when text field is empty',
        (WidgetTester tester) async {
      setupBloc(isSending: false);
      final controller = TextEditingController();

      await tester.pumpWidget(createTestWidget(controller: controller));

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('send button should be enabled when text is present',
        (WidgetTester tester) async {
      setupBloc(isSending: false);
      final controller = TextEditingController(text: 'Hello');

      await tester.pumpWidget(createTestWidget(controller: controller));
      await tester.pump();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('send button should be replaced with spinner when isSending is true',
        (WidgetTester tester) async {
      setupBloc(isSending: true);
      final controller = TextEditingController(text: 'Hello');

      await tester.pumpWidget(createTestWidget(controller: controller));
      await tester.pump();

      // When isSending, the send icon is replaced with a CircularProgressIndicator
      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show CircularProgressIndicator when isSending is true',
        (WidgetTester tester) async {
      setupBloc(isSending: true);
      final controller = TextEditingController(text: 'Hello');

      await tester.pumpWidget(createTestWidget(controller: controller));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('send button should be disabled when text is only whitespace',
        (WidgetTester tester) async {
      setupBloc(isSending: false);
      final controller = TextEditingController(text: '   ');

      await tester.pumpWidget(createTestWidget(controller: controller));
      await tester.pump();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('tapping send button with text should call onSend',
        (WidgetTester tester) async {
      setupBloc(isSending: false);
      bool onSendCalled = false;
      final controller = TextEditingController(text: 'Test message');

      await tester.pumpWidget(
        createTestWidget(
          controller: controller,
          onSend: () => onSendCalled = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      expect(onSendCalled, isTrue);
    });
  });

  group('MessageInput Uploading State Tests', () {
    testWidgets('should show upload indicator when isUploadingFile is true',
        (WidgetTester tester) async {
      setupBloc(isUploadingFile: true);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('파일 업로드 중...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should NOT show text field when uploading',
        (WidgetTester tester) async {
      setupBloc(isUploadingFile: true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should NOT show send button when uploading',
        (WidgetTester tester) async {
      setupBloc(isUploadingFile: true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.send), findsNothing);
    });
  });

  group('MessageInput Other User Left Tests', () {
    testWidgets('should show reinvite UI when other user left',
        (WidgetTester tester) async {
      setupBloc(
        isOtherUserLeft: true,
        otherUserNickname: 'Alice',
        otherUserId: 2,
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Alice님이 채팅방을 나갔습니다'), findsOneWidget);
      expect(find.text('다시 초대하기'), findsOneWidget);
    });

    testWidgets('should show default text when otherUserNickname is null',
        (WidgetTester tester) async {
      setupBloc(isOtherUserLeft: true, otherUserId: 2);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('상대방님이 채팅방을 나갔습니다'), findsOneWidget);
    });

    testWidgets('should NOT show text field when other user left',
        (WidgetTester tester) async {
      setupBloc(isOtherUserLeft: true, otherUserId: 2);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should show exit icon when other user left',
        (WidgetTester tester) async {
      setupBloc(isOtherUserLeft: true, otherUserId: 2);

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('should show loading indicator when reinviting',
        (WidgetTester tester) async {
      setupBloc(
        isOtherUserLeft: true,
        otherUserId: 2,
        otherUserNickname: 'Alice',
        isReinviting: true,
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('초대 중...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should dispatch ReinviteUserRequested when reinvite button tapped',
        (WidgetTester tester) async {
      setupBloc(
        isOtherUserLeft: true,
        otherUserId: 2,
        otherUserNickname: 'Alice',
        isReinviting: false,
      );

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('다시 초대하기'));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(
            const ReinviteUserRequested(inviteeId: 2),
          )).called(1);
    });
  });

  group('MessageInput Reply Mode Tests', () {
    testWidgets('should show reply preview bar when replyToMessage is set',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: 'Original message to reply to',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.byIcon(Icons.reply), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Original message to reply to'), findsOneWidget);
    });

    testWidgets('should show close button in reply preview',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Bob',
        content: 'Something',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping close in reply preview should call onCancelReply',
        (WidgetTester tester) async {
      setupBloc();
      bool cancelCalled = false;

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Carol',
        content: 'Cancel this',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          replyToMessage: replyMsg,
          onCancelReply: () => cancelCalled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(cancelCalled, isTrue);
    });

    testWidgets('should NOT show reply preview when replyToMessage is null',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.reply), findsNothing);
    });

    testWidgets('reply preview should show image icon for image reply',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Dave',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/img.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('reply preview should show file icon for file reply',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Dave',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/doc.pdf',
        fileName: 'doc.pdf',
        fileContentType: 'application/pdf',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('reply preview should show video icon for video reply',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Dave',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/clip.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('reply preview should show sender nickname 알 수 없음 when null',
        (WidgetTester tester) async {
      setupBloc();

      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        content: 'Anonymous reply',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(replyToMessage: replyMsg),
      );

      expect(find.text('알 수 없음'), findsOneWidget);
    });
  });

  group('MessageInput Attachment Options Tests', () {
    testWidgets('tapping attachment button should show bottom sheet',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('갤러리에서 선택'), findsOneWidget);
      expect(find.text('카메라'), findsOneWidget);
      expect(find.text('파일'), findsOneWidget);
    });

    testWidgets('attachment bottom sheet should show gallery icon',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('attachment bottom sheet should show camera icon',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('attachment bottom sheet should show attach_file icon',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });

  group('MessageInput Normal State Layout Tests', () {
    testWidgets('normal state should show text field and send button',
        (WidgetTester tester) async {
      setupBloc();

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should show person_add icon in reinvite button when not reinviting',
        (WidgetTester tester) async {
      setupBloc(
        isOtherUserLeft: true,
        otherUserId: 2,
        isReinviting: false,
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });
  });
}
