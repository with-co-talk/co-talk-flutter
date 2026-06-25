import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
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

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

class MockChatSettingsCubit extends MockCubit<ChatSettingsState>
    implements ChatSettingsCubit {}

void main() {
  const currentUserId = 1;

  // Fixed timestamp in a past year so AppDateUtils.formatMessageTime() always
  // renders the full "yyyy년 M월 d일 a h:mm" branch, keeping the golden image
  // stable regardless of the date the test is run.
  final fixedTime = DateTime(2020, 3, 14, 9, 41);

  late MockChatRoomBloc mockChatRoomBloc;
  late MockChatListBloc mockChatListBloc;
  late MockChatSettingsCubit mockChatSettingsCubit;

  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  setUp(() {
    mockChatRoomBloc = MockChatRoomBloc();
    mockChatListBloc = MockChatListBloc();
    mockChatSettingsCubit = MockChatSettingsCubit();

    const roomState = ChatRoomState(
      status: ChatRoomStatus.success,
      roomId: 1,
      currentUserId: currentUserId,
      hasMore: false,
    );
    whenListen(mockChatRoomBloc, Stream<ChatRoomState>.empty(),
        initialState: roomState);

    const listState = ChatListState();
    whenListen(mockChatListBloc, Stream<ChatListState>.empty(),
        initialState: listState);

    const settingsState =
        ChatSettingsState.loaded(ChatSettings(autoDownloadImagesOnWifi: false));
    whenListen(mockChatSettingsCubit, Stream<ChatSettingsState>.empty(),
        initialState: settingsState);
  });

  Widget buildHarness(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ChatRoomBloc>.value(value: mockChatRoomBloc),
            BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
            BlocProvider<ChatSettingsCubit>.value(value: mockChatSettingsCubit),
          ],
          child: child,
        ),
      ),
    );
  }

  testWidgets('message bubble list golden (received + reaction, sent + read receipt)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Received message with a reaction.
    final receivedMessage = Message(
      id: 10,
      chatRoomId: 1,
      senderId: 2,
      senderNickname: '상대방',
      content: '안녕하세요! 잘 지내시죠?',
      type: MessageType.text,
      createdAt: fixedTime,
      reactions: const [
        MessageReaction(
          id: 100,
          messageId: 10,
          userId: 1,
          emoji: '👍',
        ),
      ],
      isDeleted: false,
      unreadCount: 0,
    );

    // Sent message with an unread (read-receipt) count.
    final sentMessage = Message(
      id: 11,
      chatRoomId: 1,
      senderId: currentUserId,
      content: '네, 잘 지내요. 반가워요!',
      type: MessageType.text,
      createdAt: fixedTime,
      reactions: const [],
      isDeleted: false,
      unreadCount: 1,
    );

    await tester.pumpWidget(
      buildHarness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageBubble(message: receivedMessage, isMe: false),
            MessageBubble(message: sentMessage, isMe: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/message_bubble_list.png'),
    );
  });
}
