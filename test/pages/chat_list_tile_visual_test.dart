import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/pages/chat/chat_list_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

void main() {
  const me = User(
    id: 1,
    email: 'me@cotalk.app',
    nickname: '이승구',
    avatarUrl: 'https://example.com/me.jpg',
  );

  ChatRoom room({
    required ChatRoomType type,
    bool online = false,
  }) {
    return ChatRoom(
      id: 1,
      name: type == ChatRoomType.self ? '나와의 채팅' : null,
      type: type,
      createdAt: DateTime(2024, 1, 1),
      lastMessage: '메모',
      lastMessageAt: DateTime(2024, 6, 1),
      unreadCount: 0,
      otherUserId: type == ChatRoomType.direct ? 2 : null,
      otherUserNickname: type == ChatRoomType.direct ? '김민지' : null,
      isOtherUserOnline: online,
    );
  }

  Future<void> pumpList(
    WidgetTester tester,
    ChatRoom chatRoom, {
    User user = me,
    bool dark = false,
  }) async {
    final auth = MockAuthBloc();
    whenListen(auth, const Stream<AuthState>.empty(),
        initialState: AuthState.authenticated(user));
    final list = MockChatListBloc();
    whenListen(list, const Stream<ChatListState>.empty(),
        initialState: ChatListState(
            status: ChatListStatus.success, chatRooms: [chatRoom]));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ChatListBloc>.value(value: list),
          ],
          child: const ChatListPage(),
        ),
      ),
    );
    await tester.pump();
  }

  group('나와의 채팅 아바타', () {
    testWidgets('내 아바타가 있으면 이미지를 보여준다', (tester) async {
      await pumpList(tester, room(type: ChatRoomType.self));

      final avatar = tester.widget<CircleAvatar>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(CircleAvatar),
        ),
      );
      expect(avatar.backgroundImage, isNotNull,
          reason: '나와의 채팅은 내 아바타 이미지를 보여야 한다');
    });

    testWidgets('내 아바타가 없으면 이니셜을 보여준다 (빈 원 금지)', (tester) async {
      const userNoAvatar = User(
        id: 1,
        email: 'me@cotalk.app',
        nickname: '이승구',
      );
      await pumpList(tester, room(type: ChatRoomType.self),
          user: userNoAvatar);

      final avatarFinder = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(CircleAvatar),
      );
      expect(
        find.descendant(of: avatarFinder, matching: find.text('이')),
        findsOneWidget,
        reason: '나와의 채팅 아바타가 빈 원으로 남으면 안 된다',
      );
    });
  });

  group('온라인 표시 점', () {
    // Colors.green(ColorSwatch)과 일반 Color의 ==는 false이므로 ARGB로 비교.
    Finder dotFinder() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration as BoxDecoration).color?.toARGB32() ==
                  AppColors.online.toARGB32(),
        );

    testWidgets('토큰 색상(AppColors.online)을 쓴다', (tester) async {
      await pumpList(tester, room(type: ChatRoomType.direct, online: true));
      expect(dotFinder(), findsOneWidget);
    });

    testWidgets('다크 모드에서 테두리가 흰색이 아니라 surface 색이다', (tester) async {
      await pumpList(tester, room(type: ChatRoomType.direct, online: true),
          dark: true);

      final dot = tester.widget<Container>(dotFinder());
      final border = (dot.decoration as BoxDecoration).border as Border;
      expect(border.top.color, isNot(Colors.white),
          reason: '다크 모드에서 흰 테두리 링은 아바타 위에서 도드라진다');
      expect(border.top.color, AppColors.surfaceDark);
    });
  });
}
