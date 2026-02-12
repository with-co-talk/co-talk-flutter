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
}
