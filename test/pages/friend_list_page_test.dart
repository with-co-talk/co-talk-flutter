import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/friend_list_page.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

void main() {
  late MockFriendBloc mockFriendBloc;

  setUp(() {
    mockFriendBloc = MockFriendBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<FriendBloc>.value(
        value: mockFriendBloc,
        child: const FriendListPage(),
      ),
    );
  }

  group('FriendListPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      // AppBar 타이틀과 첫 번째 탭에 '친구'가 있음
      expect(find.text('친구'), findsNWidgets(2));
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(status: FriendStatus.loading),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no friends', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(status: FriendStatus.success),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('친구가 없습니다\n친구를 추가해보세요'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.failure,
          errorMessage: '에러 발생',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('친구 목록을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches FriendListLoadRequested on retry button tap', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(status: FriendStatus.failure),
      );

      await tester.pumpWidget(createWidgetUnderTest());

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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('FriendUser'), findsOneWidget);
      expect(find.text('온라인'), findsOneWidget);
    });

    testWidgets('shows offline status for offline friend', (tester) async {
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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('오프라인'), findsOneWidget);
    });

    testWidgets('shows away status for away friend', (tester) async {
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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('자리 비움'), findsOneWidget);
    });

    testWidgets('dispatches FriendListLoadRequested on init', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const FriendListLoadRequested())).called(1);
    });

    testWidgets('shows add friend button in app bar', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('opens add friend dialog when add button is tapped', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('닉네임으로 검색'), findsOneWidget);
    });

    testWidgets('shows popup menu for friend options', (tester) async {
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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('대화하기'), findsOneWidget);
      expect(find.text('친구 삭제'), findsOneWidget);
    });

    testWidgets('shows remove friend dialog from popup menu', (tester) async {
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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap remove friend option
      await tester.tap(find.text('친구 삭제'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('FriendUser님을 친구에서 삭제하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('shows search results in add friend dialog', (tester) async {
      final searchResults = [
        const User(
          id: 5,
          email: 'search@test.com',
          nickname: 'SearchUser',
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          searchResults: searchResults,
          hasSearched: true,
          searchQuery: 'Search',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('SearchUser'), findsOneWidget);
      expect(find.text('search@test.com'), findsOneWidget);
    });

    testWidgets('shows no results message in add friend dialog', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.success,
          isSearching: false,
          searchResults: [],
          hasSearched: true,
          searchQuery: 'test',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

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

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify the status indicator container exists
      final statusIndicator = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration != null);

      expect(statusIndicator, findsWidgets);
    });
  });
}
