import 'package:bloc_test/bloc_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
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

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

class MockChatSettingsCubit extends MockCubit<ChatSettingsState>
    implements ChatSettingsCubit {}

void main() {
  late MockChatRoomBloc mockChatRoomBloc;
  late MockChatSettingsCubit mockChatSettingsCubit;

  setUpAll(() async {
    // Initialize locale data for date formatting
    await initializeDateFormatting('ko_KR', null);
  });

  setUp(() {
    mockChatRoomBloc = MockChatRoomBloc();
    mockChatSettingsCubit = MockChatSettingsCubit();
  });

  Widget createTestWidget({
    required Message message,
    required bool isMe,
    required ChatSettings chatSettings,
  }) {
    whenListen(
      mockChatRoomBloc,
      Stream.value(const ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        hasMore: false,
      )),
      initialState: const ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        hasMore: false,
      ),
    );

    whenListen(
      mockChatSettingsCubit,
      Stream.value(ChatSettingsState.loaded(chatSettings)),
      initialState: ChatSettingsState.loaded(chatSettings),
    );

    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatSettingsCubit>.value(value: mockChatSettingsCubit),
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
}
