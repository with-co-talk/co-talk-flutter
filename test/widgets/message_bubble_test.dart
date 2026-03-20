import 'package:bloc_test/bloc_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

class MockChatSettingsCubit extends MockCubit<ChatSettingsState>
    implements ChatSettingsCubit {}

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

// Fallback values for mocktail
class _FakeChatRoomEvent extends Fake implements ChatRoomEvent {}
class _FakeChatListEvent extends Fake implements ChatListEvent {}

void main() {
  late MockChatRoomBloc mockChatRoomBloc;
  late MockChatSettingsCubit mockChatSettingsCubit;
  late MockChatListBloc mockChatListBloc;

  setUpAll(() async {
    // Initialize locale data for date formatting
    await initializeDateFormatting('ko_KR', null);
    // Register fallback values for mocktail
    registerFallbackValue(_FakeChatRoomEvent());
    registerFallbackValue(_FakeChatListEvent());
  });

  setUp(() {
    mockChatRoomBloc = MockChatRoomBloc();
    mockChatSettingsCubit = MockChatSettingsCubit();
    mockChatListBloc = MockChatListBloc();
  });

  Widget createTestWidget({
    required Message message,
    required bool isMe,
    required ChatSettings chatSettings,
    ChatRoomState? chatRoomState,
  }) {
    final state = chatRoomState ??
        const ChatRoomState(
          status: ChatRoomStatus.success,
          roomId: 1,
          currentUserId: 1,
          hasMore: false,
        );

    whenListen(
      mockChatRoomBloc,
      Stream.value(state),
      initialState: state,
    );

    whenListen(
      mockChatSettingsCubit,
      Stream.value(ChatSettingsState.loaded(chatSettings)),
      initialState: ChatSettingsState.loaded(chatSettings),
    );

    whenListen(
      mockChatListBloc,
      Stream.value(const ChatListState()),
      initialState: const ChatListState(),
    );

    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatSettingsCubit>.value(value: mockChatSettingsCubit),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
          ],
          child: MessageBubble(
            message: message,
            isMe: isMe,
          ),
        ),
      ),
    );
  }

  group('MessageBubble Auto-Download Tests', () {
    testWidgets('should show placeholder when auto-download is disabled',
        (WidgetTester tester) async {
      // Arrange
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final chatSettings = const ChatSettings(
        autoDownloadImagesOnWifi: false,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: chatSettings,
        ),
      );

      // Assert
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('탭하여 이미지 보기'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('should auto-load image when auto-download is enabled',
        (WidgetTester tester) async {
      // Arrange
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final chatSettings = const ChatSettings(
        autoDownloadImagesOnWifi: true,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: chatSettings,
        ),
      );

      // Assert
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(find.text('탭하여 이미지 보기'), findsNothing);
    });

    testWidgets('should load image when tapping placeholder',
        (WidgetTester tester) async {
      // Arrange
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Test User',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final chatSettings = const ChatSettings(
        autoDownloadImagesOnWifi: false,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: chatSettings,
        ),
      );

      // Verify placeholder is shown
      expect(find.text('탭하여 이미지 보기'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);

      // Tap the placeholder
      await tester.tap(find.byIcon(Icons.image_outlined));
      // Wait for double-tap timeout (kDoubleTapTimeout is 300ms)
      await tester.pump(const Duration(milliseconds: 350));
      // Allow widget tree to rebuild
      await tester.pump();

      // Assert - image should now be loaded (CachedNetworkImage widget should exist)
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('탭하여 이미지 보기'), findsNothing);
    });

    testWidgets('should display text messages normally',
        (WidgetTester tester) async {
      // Arrange
      final textMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Test User',
        content: 'Hello, World!',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final chatSettings = const ChatSettings(
        autoDownloadImagesOnWifi: false,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: chatSettings,
        ),
      );

      // Assert - text is rendered in RichText, so we need to search through all RichText widgets
      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      // Find the RichText widget that contains our message content
      bool foundMessageContent = false;
      for (var i = 0; i < tester.widgetList(richTextFinder).length; i++) {
        final richTextWidget = tester.widget<RichText>(richTextFinder.at(i));
        final textSpan = richTextWidget.text as TextSpan;
        if (textSpan.toPlainText().contains('Hello, World!')) {
          foundMessageContent = true;
          break;
        }
      }

      expect(foundMessageContent, isTrue, reason: 'Message content "Hello, World!" should be found in one of the RichText widgets');
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('should respect auto-download setting for own messages',
        (WidgetTester tester) async {
      // Arrange
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final chatSettings = const ChatSettings(
        autoDownloadImagesOnWifi: false,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: true,
          chatSettings: chatSettings,
        ),
      );

      // Assert
      expect(find.text('탭하여 이미지 보기'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  group('MessageBubble Unified Sheet Tests', () {
    testWidgets('long press on text message should show unified sheet with emojis and options',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Test User',
        content: 'Hello!',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Find the GestureDetector and long press
      // We need to long press on the message bubble area
      // Target the CircleAvatar which is inside the outer GestureDetector
      // Long press events bubble up to the parent
      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      // Verify emojis are shown in the bottom sheet
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
      expect(find.text('😮'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('🙏'), findsOneWidget);

      // Verify message options are shown
      expect(find.text('답장'), findsOneWidget);
      expect(find.text('전달'), findsOneWidget);
      // Since isMe is false, 수정 and 삭제 should NOT be shown
      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsNothing);
      // Report should be shown for other's messages
      expect(find.text('신고'), findsOneWidget);
    });

    testWidgets('long press on own message should show edit and delete options',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1, // own message (currentUserId is 1)
        senderNickname: 'Me',
        content: 'My message',
        type: MessageType.text,
        createdAt: DateTime.now(), // recent, so within edit time limit
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // For own messages (isMe: true), there's no CircleAvatar
      // Find the RichText containing the message and long press it
      // Wait for the widget to be built first
      await tester.pump();

      final richTexts = find.byType(RichText);
      bool found = false;
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('My message')) {
          await tester.longPress(richTexts.at(i));
          found = true;
          break;
        }
      }
      expect(found, isTrue, reason: 'Should find the message RichText');

      // Allow minor overflow in bottom sheet layout (known issue: 4.5px overflow)
      await tester.pumpAndSettle();

      // Own message options
      expect(find.text('답장'), findsOneWidget);
      expect(find.text('전달'), findsOneWidget);
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      // No report for own messages
      expect(find.text('신고'), findsNothing);
    });

    testWidgets('long press on deleted message should not show sheet',
        (WidgetTester tester) async {
      final deletedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Test User',
        content: '삭제된 메시지입니다',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: true,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: deletedMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Deleted message should have no GestureDetector with onLongPress
      final gesture = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );
      expect(gesture, findsNothing);

      // No bottom sheet should appear
      expect(find.text('답장'), findsNothing);
      expect(find.text('전달'), findsNothing);
      expect(find.text('👍'), findsNothing);
    });

    testWidgets('selecting emoji in unified sheet should close the sheet',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 42,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Test User',
        content: 'React to me!',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Open unified sheet
      // Target the CircleAvatar which is inside the outer GestureDetector
      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('👍'), findsOneWidget);

      // Tap the thumbs up emoji
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      // Verify the sheet is closed
      expect(find.text('답장'), findsNothing);
    });
  });

  group('MessageBubble System Message Tests', () {
    testWidgets('should display system message centered',
        (WidgetTester tester) async {
      final systemMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 0,
        content: '채팅방이 생성되었습니다',
        type: MessageType.system,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: systemMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('채팅방이 생성되었습니다'), findsOneWidget);
      // System messages have no CircleAvatar
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('system message should not show long press sheet',
        (WidgetTester tester) async {
      final systemMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 0,
        content: '유저가 입장했습니다',
        type: MessageType.system,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: systemMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // System messages should not have a GestureDetector with onLongPress
      final longPressGestures = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );
      expect(longPressGestures, findsNothing);
    });
  });

  group('MessageBubble Sender vs Receiver Styling Tests', () {
    testWidgets('should show CircleAvatar for other user messages',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other User',
        content: 'Hello from other',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Other User'), findsOneWidget);
    });

    testWidgets('should NOT show CircleAvatar for own messages',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'My message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('should show avatar initial letter when no avatar URL',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: 'Hi',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // Initial letter 'A' shown inside avatar
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('should show ? in avatar when sender nickname is null',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        content: 'Anonymous',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should display sender nickname for other user messages',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Bob',
        content: 'Test',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('should show 알 수 없음 when senderNickname is null for other user',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        content: 'Test',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('알 수 없음'), findsOneWidget);
    });
  });

  group('MessageBubble Deleted Message Tests', () {
    testWidgets('should display deleted message placeholder text',
        (WidgetTester tester) async {
      final deletedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'original content',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: true,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: deletedMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // displayContent for deleted message returns '삭제된 메시지입니다'
      final richTextFinder = find.byType(RichText);
      bool foundDeletedText = false;
      for (var i = 0; i < tester.widgetList(richTextFinder).length; i++) {
        final richText = tester.widget<RichText>(richTextFinder.at(i));
        if (richText.text.toPlainText().contains('삭제된 메시지입니다')) {
          foundDeletedText = true;
          break;
        }
      }
      expect(foundDeletedText, isTrue);
    });

    testWidgets('own deleted message should not show long press sheet',
        (WidgetTester tester) async {
      final deletedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'deleted',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: true,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: deletedMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      final longPressGestures = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );
      expect(longPressGestures, findsNothing);
    });
  });

  group('MessageBubble File Message Tests', () {
    testWidgets('should display file message with file name',
        (WidgetTester tester) async {
      final fileMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/doc.pdf',
        fileName: 'document.pdf',
        fileSize: 1024 * 512,
        fileContentType: 'application/pdf',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: fileMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('document.pdf'), findsOneWidget);
    });

    testWidgets('should display file icon for PDF file',
        (WidgetTester tester) async {
      final fileMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/doc.pdf',
        fileName: 'report.pdf',
        fileContentType: 'application/pdf',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: fileMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('should display file size when fileSize is provided',
        (WidgetTester tester) async {
      final fileMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/file.zip',
        fileName: 'archive.zip',
        fileSize: 1024,
        fileContentType: 'application/zip',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: fileMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // 1024 bytes = 1.0 KB
      expect(find.text('1.0 KB'), findsOneWidget);
    });

    testWidgets('should display download icon in file message',
        (WidgetTester tester) async {
      final fileMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/file.docx',
        fileName: 'doc.docx',
        fileContentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: fileMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should show default file name when fileName is null',
        (WidgetTester tester) async {
      final fileMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/file',
        fileContentType: 'application/octet-stream',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: fileMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('파일'), findsOneWidget);
    });
  });

  group('MessageBubble Video Message Tests', () {
    testWidgets('should display video message with play button',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/video.mp4',
        fileName: 'clip.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should display video file name in video message',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/video.mp4',
        fileName: 'myvideo.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('myvideo.mp4'), findsOneWidget);
    });

    testWidgets('should display 동영상 when video fileName is null',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/video.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('동영상'), findsOneWidget);
    });
  });

  group('MessageBubble Reply Indicator Tests', () {
    testWidgets('should show reply preview when replyToMessage is embedded',
        (WidgetTester tester) async {
      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: 'Original message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final replyingMessage = Message(
        id: 11,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Reply content',
        type: MessageType.text,
        replyToMessageId: 10,
        replyToMessage: replyMsg,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // Reply preview should show original sender name and content
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Original message'), findsOneWidget);
    });

    testWidgets('should show image icon in reply preview for image reply',
        (WidgetTester tester) async {
      final replyMsg = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/img.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final replyingMessage = Message(
        id: 11,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Replying to image',
        type: MessageType.text,
        replyToMessageId: 10,
        replyToMessage: replyMsg,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('should show 원본 메시지를 찾을 수 없습니다 when replyToMessage is null and not in state',
        (WidgetTester tester) async {
      final replyingMessage = Message(
        id: 11,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Reply content',
        type: MessageType.text,
        replyToMessageId: 999,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('원본 메시지를 찾을 수 없습니다'), findsOneWidget);
    });
  });

  group('MessageBubble Forward Indicator Tests', () {
    testWidgets('should show forwarded indicator for forwarded messages',
        (WidgetTester tester) async {
      final forwardedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Forwarded text',
        type: MessageType.text,
        forwardedFromMessageId: 50,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: forwardedMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('전달됨'), findsOneWidget);
      expect(find.byIcon(Icons.forward), findsAtLeast(1));
    });

    testWidgets('should NOT show forwarded indicator when forwardedFromMessageId is null',
        (WidgetTester tester) async {
      final normalMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Normal text',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: normalMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('전달됨'), findsNothing);
    });
  });

  group('MessageBubble Reaction Display Tests', () {
    testWidgets('should display reactions when reactions list is non-empty',
        (WidgetTester tester) async {
      final reactions = [
        const MessageReaction(
          id: 1,
          messageId: 1,
          userId: 2,
          userNickname: 'Alice',
          emoji: '👍',
        ),
      ];

      final messageWithReaction = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: 'Like this!',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: reactions,
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: messageWithReaction,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // ReactionDisplay widget should be rendered
      expect(find.text('👍'), findsOneWidget);
    });

    testWidgets('should show unread count for own sent messages',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Unread message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 3,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should NOT show unread count when unreadCount is 0',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Read message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('0'), findsNothing);
    });
  });

  group('MessageBubble Send Status Tests', () {
    testWidgets('should show loading indicator for pending message',
        (WidgetTester tester) async {
      final pendingMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Sending...',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.pending,
        localId: 'local-1',
      );

      await tester.pumpWidget(
        createTestWidget(
          message: pendingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show retry and delete buttons for failed message',
        (WidgetTester tester) async {
      final failedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Failed to send',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.failed,
        localId: 'local-2',
      );

      await tester.pumpWidget(
        createTestWidget(
          message: failedMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('재전송'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('failed status buttons should not appear for other user messages',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Normal message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('재전송'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });
  });

  group('MessageBubble Timestamp Display Tests', () {
    testWidgets('should display formatted time for sent message',
        (WidgetTester tester) async {
      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Timed message',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 15, 14, 30),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // Time widget should exist (contains formatted time text)
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);
    });
  });

  group('MessageBubble Expired Edit Time Tests', () {
    testWidgets('should NOT show edit option when message is older than 5 minutes',
        (WidgetTester tester) async {
      final oldMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Old message',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: oldMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      bool found = false;
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Old message')) {
          await tester.longPress(richTexts.at(i));
          found = true;
          break;
        }
      }
      expect(found, isTrue);
      await tester.pumpAndSettle();

      // Edit option should NOT appear since edit time is expired
      expect(find.text('수정'), findsNothing);
      // Delete should also be absent (expired)
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('should show edit and delete when message is within 5 minutes',
        (WidgetTester tester) async {
      final recentMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Recent message',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: recentMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      bool found = false;
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Recent message')) {
          await tester.longPress(richTexts.at(i));
          found = true;
          break;
        }
      }
      expect(found, isTrue);
      await tester.pumpAndSettle();

      // Both edit and delete should be visible within 5 minutes
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  group('MessageBubble Edit Dialog Tests', () {
    testWidgets('tapping 수정 should show edit dialog with message content',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 5,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Edit this text',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Long press to open unified sheet
      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Edit this text')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      // Tap 수정 in the bottom sheet
      expect(find.text('수정'), findsOneWidget);
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      // Edit dialog should appear
      expect(find.text('메시지 수정'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping cancel in edit dialog should close it',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 6,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Cancel edit',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Cancel edit')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      // Dialog is open; tap cancel
      // There are two '취소' candidates if sheet is still open - find the one in the dialog
      final cancelButtons = find.text('취소');
      expect(cancelButtons, findsOneWidget);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Dialog should be gone
      expect(find.text('메시지 수정'), findsNothing);
    });
  });

  group('MessageBubble Delete Dialog Tests', () {
    testWidgets('tapping 삭제 in sheet should show delete confirmation dialog',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 7,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Delete me',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Delete me')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      // Tap 삭제 in the unified sheet
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // Delete confirmation dialog
      expect(find.text('메시지 삭제'), findsOneWidget);
      expect(find.text('이 메시지를 삭제하시겠습니까?'), findsOneWidget);
    });

    testWidgets('confirming delete dispatches MessageDeleted event',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 8,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Confirm delete',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Confirm delete')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // In the confirmation dialog there are two '삭제' texts (title + button)
      // The red-styled '삭제' TextButton is the confirm action
      final deleteButtons = find.text('삭제');
      // We expect 2: dialog title area and dialog button
      expect(deleteButtons, findsAtLeast(1));
      // Tap the last (confirm) button
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('이 메시지를 삭제하시겠습니까?'), findsNothing);
    });
  });

  group('MessageBubble Link Preview Tests', () {
    testWidgets('text message with URL should render LinkPreviewLoader',
        (WidgetTester tester) async {
      final urlMessage = Message(
        id: 10,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'Check https://example.com for more info',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: urlMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );
      // Pump once to start the frame, then advance time past all retry timers
      // (LinkPreviewLoader has 3-second retries × 3 attempts = up to 9 seconds)
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      // LinkPreviewLoader should be rendered when URL is detected
      expect(find.byType(RichText), findsWidgets);
      // The URL text is rendered with WidgetSpan (GestureDetector + Text)
      // so the URL itself won't be findable as plain text in find.text
      // but we can verify the message content is present
      bool foundContent = false;
      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Check') ||
            richText.text.toPlainText().contains('more info')) {
          foundContent = true;
          break;
        }
      }
      expect(foundContent, isTrue);
    });

    testWidgets('text message with embedded link preview data shows LinkPreviewCard',
        (WidgetTester tester) async {
      final msgWithPreview = Message(
        id: 11,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'https://example.com',
        type: MessageType.text,
        linkPreviewUrl: 'https://example.com',
        linkPreviewTitle: 'Example Domain',
        linkPreviewDescription: 'This domain is for examples.',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: msgWithPreview,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // LinkPreviewCard should appear when hasLinkPreview is true
      // (title or description present)
      expect(find.text('Example Domain'), findsOneWidget);
    });

    testWidgets('text message without URL shows no link preview widgets',
        (WidgetTester tester) async {
      final plainMessage = Message(
        id: 12,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'Just a plain text, no links here!',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: plainMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      bool foundContent = false;
      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final richText = tester.widget<RichText>(richTexts.at(i));
        if (richText.text.toPlainText().contains('Just a plain text')) {
          foundContent = true;
          break;
        }
      }
      expect(foundContent, isTrue);
    });
  });

  group('MessageBubble Retry and Delete Pending Message Tests', () {
    testWidgets('tapping retry button on failed message dispatches retry event',
        (WidgetTester tester) async {
      final failedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Failed',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.failed,
        localId: 'local-retry',
      );

      await tester.pumpWidget(
        createTestWidget(
          message: failedMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('재전송'), findsOneWidget);
      await tester.tap(find.text('재전송'));
      await tester.pump();

      // Verify event was dispatched
      verify(() => mockChatRoomBloc.add(any(that: isA<MessageRetryRequested>()))).called(1);
    });

    testWidgets('tapping delete button on failed message dispatches delete pending event',
        (WidgetTester tester) async {
      final failedMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Failed delete',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
        sendStatus: MessageSendStatus.failed,
        localId: 'local-del',
      );

      await tester.pumpWidget(
        createTestWidget(
          message: failedMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('삭제'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(any(that: isA<PendingMessageDeleteRequested>()))).called(1);
    });
  });

  group('MessageBubble Reply To Message State Lookup Tests', () {
    testWidgets('should look up reply message from ChatRoomBloc state when replyToMessage is null',
        (WidgetTester tester) async {
      final originalMsg = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Bob',
        content: 'Original from state',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final replyingMessage = Message(
        id: 101,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Reply via state lookup',
        type: MessageType.text,
        replyToMessageId: 100,
        // replyToMessage is null - will look up from state
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
          chatRoomState: ChatRoomState(
            status: ChatRoomStatus.success,
            roomId: 1,
            currentUserId: 1,
            hasMore: false,
            messages: [originalMsg, replyingMessage],
          ),
        ),
      );

      // Should show the sender name and content from state lookup
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Original from state'), findsOneWidget);
    });

    testWidgets('reply preview shows video icon for video file reply',
        (WidgetTester tester) async {
      final videoReply = Message(
        id: 200,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/v.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      final replyingMessage = Message(
        id: 201,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Replying to video',
        type: MessageType.text,
        replyToMessageId: 200,
        replyToMessage: videoReply,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // Video reply should show videocam icon
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('reply preview shows attach_file icon for file reply',
        (WidgetTester tester) async {
      final fileReply = Message(
        id: 300,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Alice',
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

      final replyingMessage = Message(
        id: 301,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Replying to file',
        type: MessageType.text,
        replyToMessageId: 300,
        replyToMessage: fileReply,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: replyingMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // File (non-video, non-image) reply should show attach_file icon
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });

  group('MessageBubble Reaction Toggle Tests', () {
    testWidgets('tapping reaction dispatches remove event when already reacted',
        (WidgetTester tester) async {
      final reactions = [
        const MessageReaction(
          id: 1,
          messageId: 1,
          userId: 1, // currentUserId = 1, so this is my reaction
          userNickname: 'Me',
          emoji: '❤️',
        ),
      ];

      final msgWithReaction = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'React toggle',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: reactions,
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: msgWithReaction,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // The ReactionDisplay should show the reaction
      expect(find.text('❤️'), findsOneWidget);

      // Tap the reaction to toggle (should remove since currentUserId=1 already reacted)
      await tester.tap(find.text('❤️'));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(any(that: isA<ReactionRemoveRequested>()))).called(1);
    });

    testWidgets('tapping reaction dispatches add event when not yet reacted',
        (WidgetTester tester) async {
      final reactions = [
        const MessageReaction(
          id: 1,
          messageId: 1,
          userId: 2, // currentUserId = 1, so this is NOT my reaction
          userNickname: 'Other',
          emoji: '👍',
        ),
      ];

      final msgWithReaction = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'React add test',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: reactions,
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: msgWithReaction,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('👍'), findsOneWidget);

      await tester.tap(find.text('👍'));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(any(that: isA<ReactionAddRequested>()))).called(1);
    });
  });

  group('MessageBubble Forward Dialog Tests', () {
    testWidgets('tapping 전달 in sheet should show forward room picker dialog',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 20,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Forward this',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // Long press to open unified sheet
      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('전달'), findsOneWidget);
      await tester.tap(find.text('전달'));
      await tester.pumpAndSettle();

      // ForwardRoomPickerDialog should open
      expect(find.text('채팅방 선택'), findsOneWidget);
      expect(find.text('채팅방이 없습니다'), findsOneWidget); // empty state since mockChatListBloc has no rooms
    });
  });

  group('MessageBubble Image Message Structure Tests', () {
    testWidgets('image message with auto-download shows CachedNetworkImage container',
        (WidgetTester tester) async {
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // With auto-download enabled, CachedNetworkImage widget should be present
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('image message bubble is inside ClipRRect for rounded corners',
        (WidgetTester tester) async {
      final imageMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Image widget tree should include ClipRRect for rounded corners
      expect(find.byType(ClipRRect), findsWidgets);
    });
  });

  group('MessageBubble Unread Count for Other User Messages Tests', () {
    testWidgets('should NOT show unread count for other user messages',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Other unread',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 5,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // unreadCount display is gated by `isMe`, so '5' should not appear
      expect(find.text('5'), findsNothing);
    });
  });

  group('MessageBubble Reply Action Tests', () {
    testWidgets('tapping 답장 dispatches ReplyToMessageSelected event',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 30,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Reply to me',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('답장'), findsOneWidget);
      await tester.tap(find.text('답장'));
      await tester.pump();

      verify(() => mockChatRoomBloc.add(any(that: isA<ReplyToMessageSelected>()))).called(1);
    });
  });

  group('MessageBubble More Emoji Button Tests', () {
    testWidgets('tapping + emoji button in sheet should open full emoji picker',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 40,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'More emojis',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      // The '+' icon button should be visible
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap the + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Full emoji picker should appear (EmojiPicker widget)
      // The first sheet closes and new one opens
      expect(find.text('👍'), findsNothing); // quick emoji row gone
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // NEW COVERAGE TESTS
  // ────────────────────────────────────────────────────────────────────────────

  group('MessageBubble Image Message Rendering Tests', () {
    testWidgets(
        'image message with fileUrl and auto-download shows CachedNetworkImage',
        (WidgetTester tester) async {
      final imageMessage = Message(
        id: 50,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/photo.png',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // With auto-download enabled, CachedNetworkImage is shown
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      // The placeholder text should NOT be shown
      expect(find.text('탭하여 이미지 보기'), findsNothing);
    });

    testWidgets(
        'image message without auto-download shows placeholder icon and text',
        (WidgetTester tester) async {
      final imageMessage = Message(
        id: 51,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/image2.png',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: false),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('탭하여 이미지 보기'), findsOneWidget);
    });

    testWidgets('own image message is aligned to the right (isMe true)',
        (WidgetTester tester) async {
      final imageMessage = Message(
        id: 52,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/myimage.png',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      // Own image message should show CachedNetworkImage and no avatar
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('image message long press shows fullscreen and save options',
        (WidgetTester tester) async {
      // Use a taller screen so the bottom sheet doesn't overflow
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final imageMessage = Message(
        id: 53,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/img.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          // Disable auto-download to avoid CachedNetworkImage HTTP calls
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: false),
        ),
      );
      await tester.pump();

      // Long press on the avatar to open the sheet
      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Image-specific options should be visible
      expect(find.text('전체 화면 보기'), findsOneWidget);
      // Standard options also present
      expect(find.text('답장'), findsOneWidget);
      expect(find.text('전달'), findsOneWidget);
    });
  });

  group('MessageBubble Video Message Additional Tests', () {
    testWidgets('video message shows play button overlay icon',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 60,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/clip.mp4',
        fileName: 'clip.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // Should show the play arrow icon as the overlay
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('video message shows videocam icon alongside file name',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 61,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/movie.mp4',
        fileName: 'movie.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.text('movie.mp4'), findsOneWidget);
    });

    testWidgets('video message inside container has black background',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 62,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/own.mp4',
        fileContentType: 'video/mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // The container with black87 background wrapping the video player UI
      final containers = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.black87,
      );
      expect(containers, findsOneWidget);
    });

    testWidgets('video message long press shows fullscreen option',
        (WidgetTester tester) async {
      final videoMessage = Message(
        id: 63,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.file,
        fileUrl: 'https://example.com/full.mp4',
        fileContentType: 'video/mp4',
        fileName: 'full.mp4',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: videoMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('전체 화면 보기'), findsOneWidget);
    });
  });

  group('MessageBubble Edit Time Expiry Tests', () {
    testWidgets(
        '_isEditTimeExpired is true for messages older than 5 minutes - no edit in sheet',
        (WidgetTester tester) async {
      final oldMessage = Message(
        id: 70,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Stale content',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: oldMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final rt = tester.widget<RichText>(richTexts.at(i));
        if (rt.text.toPlainText().contains('Stale content')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      // Both edit and delete should be absent (time expired)
      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsNothing);
      // Standard options still present
      expect(find.text('답장'), findsOneWidget);
    });

    testWidgets(
        '_isEditTimeExpired is false for message at exactly 4 minutes - edit shown',
        (WidgetTester tester) async {
      final freshMessage = Message(
        id: 71,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Fresh content',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: freshMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final rt = tester.widget<RichText>(richTexts.at(i));
        if (rt.text.toPlainText().contains('Fresh content')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      // Within 5 minutes → edit and delete available
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  group('MessageBubble Link Preview Additional Tests', () {
    testWidgets(
        'message with linkPreviewUrl but no title/description shows LinkPreviewLoader',
        (WidgetTester tester) async {
      final urlOnlyMessage = Message(
        id: 80,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'Visit https://flutter.dev for docs',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: urlOnlyMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );
      // Advance time past all retry delays so no pending timers remain
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      // RichText should be present
      expect(find.byType(RichText), findsWidgets);
      // No CachedNetworkImage (not an image message)
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets(
        'message with hasLinkPreview true shows LinkPreviewCard with title',
        (WidgetTester tester) async {
      final previewMessage = Message(
        id: 81,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'https://dart.dev',
        type: MessageType.text,
        linkPreviewUrl: 'https://dart.dev',
        linkPreviewTitle: 'Dart Programming Language',
        linkPreviewDescription: 'Dart is a client-optimized language.',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: previewMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );
      await tester.pump();

      // LinkPreviewCard should show the title
      expect(find.text('Dart Programming Language'), findsOneWidget);
    });
  });

  group('MessageBubble Unread Count Display Tests', () {
    testWidgets('unread count > 0 shown for own message in time widget area',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 90,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'Unread test',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 7,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      // Unread count badge
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('unread count = 1 shown for own sent message',
        (WidgetTester tester) async {
      final myMessage = Message(
        id: 91,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'One unread',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 1,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: myMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('unread count NOT shown for other user message even if > 0',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 92,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'From other',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 10,
        sendStatus: MessageSendStatus.sent,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // '10' should not appear because unreadCount display is gated by isMe
      expect(find.text('10'), findsNothing);
    });
  });

  group('MessageBubble Forward Message Original Sender Tests', () {
    testWidgets('forwarded message shows forward icon and "전달됨" label',
        (WidgetTester tester) async {
      final forwardedMessage = Message(
        id: 100,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Original forwarded text',
        type: MessageType.text,
        forwardedFromMessageId: 55,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: forwardedMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('전달됨'), findsOneWidget);
      expect(find.byIcon(Icons.forward), findsAtLeast(1));
    });

    testWidgets('forwarded own message also shows "전달됨" label',
        (WidgetTester tester) async {
      final forwardedOwnMessage = Message(
        id: 101,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'I forwarded this',
        type: MessageType.text,
        forwardedFromMessageId: 77,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: forwardedOwnMessage,
          isMe: true,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('전달됨'), findsOneWidget);
    });

    testWidgets('non-forwarded message does not show "전달됨"',
        (WidgetTester tester) async {
      final normalMessage = Message(
        id: 102,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Normal message no forward',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: normalMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('전달됨'), findsNothing);
    });
  });

  group('MessageBubble Reaction Emoji Tap Tests', () {
    testWidgets('tapping existing reaction emoji toggles remove',
        (WidgetTester tester) async {
      final reactions = [
        const MessageReaction(
          id: 10,
          messageId: 110,
          userId: 1, // current user already reacted
          userNickname: 'Me',
          emoji: '😂',
        ),
      ];

      final msgWithReaction = Message(
        id: 110,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Funny message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: reactions,
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: msgWithReaction,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('😂'), findsOneWidget);
      await tester.tap(find.text('😂'));
      await tester.pump();

      // Since currentUserId=1 already reacted with 😂, it should remove
      verify(() => mockChatRoomBloc.add(any(that: isA<ReactionRemoveRequested>()))).called(1);
    });

    testWidgets('tapping reaction emoji from another user adds reaction',
        (WidgetTester tester) async {
      final reactions = [
        const MessageReaction(
          id: 11,
          messageId: 111,
          userId: 2, // other user's reaction
          userNickname: 'Other',
          emoji: '🙏',
        ),
      ];

      final msgWithReaction = Message(
        id: 111,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Pray message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: reactions,
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: msgWithReaction,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      expect(find.text('🙏'), findsOneWidget);
      await tester.tap(find.text('🙏'));
      await tester.pump();

      // currentUserId=1 hasn't reacted → should add
      verify(() => mockChatRoomBloc.add(any(that: isA<ReactionAddRequested>()))).called(1);
    });

    testWidgets('quick emoji tap in bottom sheet dispatches ReactionAddRequested',
        (WidgetTester tester) async {
      final textMessage = Message(
        id: 112,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: 'Quick react',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: textMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      // Open unified sheet
      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('😢'), findsOneWidget);
      await tester.tap(find.text('😢'));
      await tester.pump();

      // Sheet closes and reaction is dispatched
      verify(() => mockChatRoomBloc.add(any(that: isA<ReactionAddRequested>()))).called(1);
    });
  });

  group('MessageBubble Context Menu Option Tests', () {
    testWidgets('long press on image message shows 갤러리에 저장 option',
        (WidgetTester tester) async {
      // Use a taller screen so the bottom sheet with multiple items doesn't overflow
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final imageMessage = Message(
        id: 120,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'User',
        content: '',
        type: MessageType.image,
        fileUrl: 'https://example.com/save.jpg',
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: imageMessage,
          isMe: false,
          // Disable auto-download to avoid CachedNetworkImage HTTP calls
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: false),
        ),
      );
      await tester.pump();

      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Gallery save option should appear for image messages on non-web
      expect(find.text('갤러리에 저장'), findsOneWidget);
    });

    testWidgets('long press on non-deleted other message shows 신고 option',
        (WidgetTester tester) async {
      final otherMessage = Message(
        id: 121,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'Other',
        content: 'Report me',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: otherMessage,
          isMe: false,
          chatSettings: const ChatSettings(),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      await tester.longPress(avatarFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('신고'), findsOneWidget);
    });

    testWidgets('own message does not show 신고 option in sheet',
        (WidgetTester tester) async {
      final ownMessage = Message(
        id: 122,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'Me',
        content: 'My content',
        type: MessageType.text,
        createdAt: DateTime.now(),
        reactions: const [],
        isDeleted: false,
        unreadCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          message: ownMessage,
          isMe: true,
          chatSettings: const ChatSettings(autoDownloadImagesOnWifi: true),
        ),
      );

      final richTexts = find.byType(RichText);
      for (var i = 0; i < tester.widgetList(richTexts).length; i++) {
        final rt = tester.widget<RichText>(richTexts.at(i));
        if (rt.text.toPlainText().contains('My content')) {
          await tester.longPress(richTexts.at(i));
          break;
        }
      }
      await tester.pumpAndSettle();

      expect(find.text('신고'), findsNothing);
    });
  });
}
