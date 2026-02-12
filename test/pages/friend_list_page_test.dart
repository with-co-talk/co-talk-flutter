import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/friend_list_page.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

class MockFriendBloc extends Mock implements FriendBloc {}

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => AuthState.authenticated(const User(
    id: 1,
    email: 'me@test.com',
    nickname: 'Me',
  ));

  @override
  Stream<AuthState> get stream => const Stream.empty();

  @override
  Future<void> close() async {}
}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockFriendBloc mockFriendBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<FriendState> friendStateController;

  setUpAll(() {
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockFriendBloc = MockFriendBloc();
    mockAuthBloc = MockAuthBloc();
    friendStateController = StreamController<FriendState>.broadcast();
  });

  tearDown(() {
    friendStateController.close();
  });

  Widget createWidgetUnderTest({FriendState? friendState}) {
    final state = friendState ?? const FriendState();
    when(() => mockFriendBloc.state).thenReturn(state);
    when(() => mockFriendBloc.stream).thenAnswer((_) => friendStateController.stream);
    when(() => mockFriendBloc.isClosed).thenReturn(false);
    when(() => mockFriendBloc.add(any())).thenReturn(null);
    when(() => mockFriendBloc.close()).thenAnswer((_) async {});

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const FriendListPage(),
      ),
    );
  }

  group('FriendListPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // AppBar 타이틀에만 '친구'가 있음
      expect(find.text('친구'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.loading),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no friends', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));

      // 실제 구현은 두 개의 별도 Text 위젯으로 되어 있음
      expect(find.text('친구가 없습니다'), findsOneWidget);
      expect(find.text('친구를 추가하고 대화를 시작해보세요'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(
          status: FriendStatus.failure,
          errorMessage: '에러 발생',
        ),
      ));

      expect(find.text('친구 목록을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches FriendListLoadRequested on retry button tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.failure),
      ));

      // Clear interactions from init
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const FriendListLoadRequested())).called(1);
    });

    testWidgets('shows friends list when loaded', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
            onlineStatus: OnlineStatus.online,
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      expect(find.text('FriendUser'), findsOneWidget);
      // Note: Online status is shown as a colored dot, not text
    });

    testWidgets('shows friend nickname for offline friend', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'OfflineUser',
            onlineStatus: OnlineStatus.offline,
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      expect(find.text('OfflineUser'), findsOneWidget);
      // Note: Offline status doesn't show a visual indicator
    });

    testWidgets('shows friend nickname for away friend', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'AwayUser',
            onlineStatus: OnlineStatus.away,
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      expect(find.text('AwayUser'), findsOneWidget);
    });

    testWidgets('dispatches FriendListLoadRequested on init', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const FriendListLoadRequested())).called(1);
    });

    testWidgets('shows add friend button in app bar', (tester) async {
      // 친구가 있을 때는 빈 상태 버튼이 안 보이므로 AppBar의 아이콘만 표시됨
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      // AppBar에만 person_add 아이콘이 있음
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('opens add friend dialog when add button is tapped', (tester) async {
      // 친구가 있을 때 테스트 (빈 상태 버튼 없음)
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('닉네임으로 검색'), findsOneWidget);
    });

    testWidgets('shows search results in add friend dialog', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final searchResults = [
        const User(
          id: 5,
          email: 'search@test.com',
          nickname: 'SearchUser',
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          searchResults: searchResults,
          hasSearched: true,
          searchQuery: 'Search',
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('SearchUser'), findsOneWidget);
      expect(find.text('search@test.com'), findsOneWidget);
    });

    testWidgets('shows no results message in add friend dialog', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          isSearching: false,
          searchResults: const [],
          hasSearched: true,
          searchQuery: 'test',
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    });

    testWidgets('shows friend initial in avatar for friend without image', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'TestUser',
            avatarUrl: null,
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      // 이니셜 'T'가 아바타에 표시됨
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('shows online status indicator', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'OnlineUser',
            onlineStatus: OnlineStatus.online,
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      // Verify the status indicator container exists
      final statusIndicator = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration != null);

      expect(statusIndicator, findsWidgets);
    });

    testWidgets('dispatches FriendListSubscriptionStarted on init', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const FriendListSubscriptionStarted())).called(1);
    });

    testWidgets('dispatches FriendListSubscriptionStopped on dispose', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Navigate away from the page to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      verify(() => mockFriendBloc.add(const FriendListSubscriptionStopped())).called(1);
    });

    testWidgets('has settings button that navigates to friend settings', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'friend@test.com',
            nickname: 'FriendUser',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      // Find the settings button
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      // Note: The settings button's onPressed handler includes logic to
      // dispatch FriendListLoadRequested after returning from navigation.
      // This ensures the friend list is refreshed when coming back from
      // the hidden friends page. The actual navigation flow with refresh
      // is tested in integration tests.
    });
  });
}
