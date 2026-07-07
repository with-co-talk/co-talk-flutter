import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
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
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('메시지 본문이 테마 폰트(Pretendard)를 상속한다', (tester) async {
    // RichText를 직접 쓰면 DefaultTextStyle(테마 fontFamily)을 상속하지 않아
    // 메시지 본문만 시스템 폰트로 렌더링된다. Text.rich 기반이어야 한다.
    final mockRoomBloc = MockChatRoomBloc();
    whenListen(
      mockRoomBloc,
      const Stream<ChatRoomState>.empty(),
      initialState: const ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        hasMore: false,
      ),
    );
    final mockSettings = MockChatSettingsCubit();
    whenListen(
      mockSettings,
      const Stream<ChatSettingsState>.empty(),
      initialState: const ChatSettingsState.loaded(
          ChatSettings(autoDownloadImagesOnWifi: false)),
    );

    const content = '폰트 상속 확인용 메시지';
    final message = Message(
      id: 1,
      chatRoomId: 1,
      senderId: 2,
      content: content,
      createdAt: DateTime(2020, 3, 14, 9, 41),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ChatRoomBloc>.value(value: mockRoomBloc),
              BlocProvider<ChatSettingsCubit>.value(value: mockSettings),
            ],
            child: MessageBubble(message: message, isMe: false),
          ),
        ),
      ),
    );
    await tester.pump();

    final bodyRichTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .where((rt) => rt.text.toPlainText().contains(content))
        .toList();

    expect(bodyRichTexts, isNotEmpty, reason: '메시지 본문 RichText를 찾지 못함');
    for (final rt in bodyRichTexts) {
      expect(
        rt.text.style?.fontFamily,
        'Pretendard',
        reason: '메시지 본문이 테마 폰트를 상속해야 한다',
      );
    }
  });
}
