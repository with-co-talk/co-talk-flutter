import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/message_input.dart';

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}

void main() {
  late MockChatRoomBloc mockChatRoomBloc;

  setUp(() {
    mockChatRoomBloc = MockChatRoomBloc();
    whenListen(
      mockChatRoomBloc,
      const Stream<ChatRoomState>.empty(),
      initialState: const ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        currentUserId: 1,
        hasMore: false,
      ),
    );
  });

  Future<void> openAttachmentSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ChatRoomBloc>.value(
            value: mockChatRoomBloc,
            child: MessageInput(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              onSend: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
  }

  // debugDefaultTargetPlatformOverride는 테스트 본문이 끝나기 전에 반드시
  // 원복해야 한다(flutter_test 바인딩 불변식 검사). try/finally로 보장한다.
  Future<void> runOnPlatform(
    WidgetTester tester,
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await openAttachmentSheet(tester);
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('모바일(android)에서는 첨부 시트에 카메라 옵션이 보인다', (tester) async {
    await runOnPlatform(tester, TargetPlatform.android, () async {
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  testWidgets('macOS에서는 첨부 시트에 카메라 옵션이 없다 (image_picker 미지원 → 심사 2.1(a) 오류 방지)',
      (tester) async {
    // macOS의 image_picker는 ImageSource.camera를 지원하지 않아 탭 즉시
    // 에러가 노출된다(App Store 심사 반려 사유). 데스크톱에서는 숨겨야 한다.
    await runOnPlatform(tester, TargetPlatform.macOS, () async {
      expect(find.byIcon(Icons.camera_alt), findsNothing);
      // 갤러리·파일 옵션은 데스크톱에서도 유지되어야 한다.
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });

  testWidgets('windows에서도 첨부 시트에 카메라 옵션이 없다', (tester) async {
    await runOnPlatform(tester, TargetPlatform.windows, () async {
      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });
  });
}
