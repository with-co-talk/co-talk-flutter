import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/friend_list_page.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockFriendBloc mockFriendBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockFriendBloc = MockFriendBloc();
    mockAuthBloc = MockAuthBloc();
  });

  Friend buildFriend({required OnlineStatus onlineStatus}) {
    return Friend(
      id: 1,
      user: User(
        id: 2,
        email: 'friend@test.com',
        nickname: '친구',
        onlineStatus: onlineStatus,
      ),
      createdAt: DateTime(2024, 1, 1),
    );
  }

  Widget createWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const FriendListPage(),
      ),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Finder onlineDotFinder() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == AppColors.online &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    );
  }

  Future<void> pumpWithFriend(
    WidgetTester tester,
    OnlineStatus onlineStatus,
  ) async {
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: FriendState(
        status: FriendStatus.success,
        friends: [buildFriend(onlineStatus: onlineStatus)],
      ),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();
  }

  testWidgets('온라인 친구에게는 온라인 표시 점이 보인다', (tester) async {
    await pumpWithFriend(tester, OnlineStatus.online);
    expect(onlineDotFinder(), findsOneWidget);
  });

  testWidgets('오프라인 친구에게는 온라인 표시 점이 보이지 않는다', (tester) async {
    await pumpWithFriend(tester, OnlineStatus.offline);
    expect(onlineDotFinder(), findsNothing);
  });
}
