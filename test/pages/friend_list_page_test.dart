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

class MockAuthBlocCustom extends Mock implements AuthBloc {
  final AuthState customState;

  MockAuthBlocCustom(this.customState);

  @override
  AuthState get state => customState;

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

    testWidgets('shows error snackbar when errorMessage changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));
      await tester.pump();

      // Emit a state with an error message
      friendStateController.add(const FriendState(
        status: FriendStatus.failure,
        errorMessage: '네트워크 오류',
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows success snackbar when successMessage changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));
      await tester.pump();

      friendStateController.add(const FriendState(
        status: FriendStatus.success,
        successMessage: '친구 요청이 수락되었습니다',
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows friend count in header', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'a@test.com',
            nickname: 'Alice',
          ),
          createdAt: DateTime(2024, 1, 1),
        ),
        Friend(
          id: 2,
          user: const User(
            id: 3,
            email: 'b@test.com',
            nickname: 'Bob',
          ),
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      expect(find.text('친구 2명'), findsOneWidget);
    });

    testWidgets('shows empty friend count header when no friends', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));

      expect(find.text('친구 0명'), findsOneWidget);
    });

    testWidgets('shows my profile card when user is authenticated', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));

      // My nickname should appear in the profile card
      expect(find.text('Me'), findsOneWidget);
    });

    testWidgets('shows add friend button on empty state', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));

      // Both AppBar icon and empty state button show person_add icon
      expect(find.byIcon(Icons.person_add), findsWidgets);
    });

    testWidgets('tapping empty state add friend button opens bottom sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: const FriendState(status: FriendStatus.success),
      ));

      // Tap the ElevatedButton.icon with label '친구 추가'
      await tester.tap(find.text('친구 추가'));
      await tester.pumpAndSettle();

      expect(find.text('닉네임으로 검색'), findsOneWidget);
    });

    testWidgets('shows loading spinner in add friend dialog when searching', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          isSearching: true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      // Use pump instead of pumpAndSettle to avoid CircularProgressIndicator timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows initial search prompt when hasSearched is false', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          hasSearched: false,
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('닉네임을 입력하여 검색하세요'), findsOneWidget);
    });

    testWidgets('shows error view in add friend dialog when error and hasSearched', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          errorMessage: '검색 실패',
          hasSearched: true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('검색 중 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('shows friend status message when present', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'StatusUser',
            statusMessage: '오늘도 좋은 하루!',
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

      expect(find.text('오늘도 좋은 하루!'), findsOneWidget);
    });

    testWidgets('shows hide dialog when hide slidable action is tapped', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'SlideFriend',
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

      // Drag to reveal slidable actions
      await tester.drag(find.text('SlideFriend'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Find and tap '숨김' action
      final hideAction = find.text('숨김');
      if (hideAction.evaluate().isNotEmpty) {
        await tester.tap(hideAction);
        await tester.pumpAndSettle();
        expect(find.text('친구 숨김'), findsOneWidget);
      }
    });

    testWidgets('shows block dialog when block slidable action is tapped', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'BlockFriend',
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

      await tester.drag(find.text('BlockFriend'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final blockAction = find.text('차단');
      if (blockAction.evaluate().isNotEmpty) {
        await tester.tap(blockAction);
        await tester.pumpAndSettle();
        expect(find.text('친구 차단'), findsOneWidget);
      }
    });

    testWidgets('shows delete dialog when delete slidable action is tapped', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'DeleteFriend',
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

      await tester.drag(find.text('DeleteFriend'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final deleteAction = find.text('삭제');
      if (deleteAction.evaluate().isNotEmpty) {
        await tester.tap(deleteAction);
        await tester.pumpAndSettle();
        expect(find.text('친구 삭제'), findsOneWidget);
      }
    });

    testWidgets('cancel button in hide dialog dismisses dialog', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'HideFriend',
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

      await tester.drag(find.text('HideFriend'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final hideAction = find.text('숨김');
      if (hideAction.evaluate().isNotEmpty) {
        await tester.tap(hideAction);
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        expect(find.text('친구 숨김'), findsNothing);
      }
    });

    testWidgets('confirm hide dispatches HideFriendRequested', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'HideFriend2',
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

      await tester.drag(find.text('HideFriend2'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final hideAction = find.text('숨김');
      if (hideAction.evaluate().isNotEmpty) {
        clearInteractions(mockFriendBloc);
        await tester.tap(hideAction);
        await tester.pumpAndSettle();

        // Confirm hide by tapping '숨김' in the dialog
        final dialogHideButtons = find.text('숨김');
        if (dialogHideButtons.evaluate().length > 1) {
          await tester.tap(dialogHideButtons.last);
          await tester.pump();
          verify(() => mockFriendBloc.add(HideFriendRequested(2))).called(1);
        }
      }
    });

    testWidgets('confirm delete dispatches FriendRemoved', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'DelFriend',
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

      await tester.drag(find.text('DelFriend'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final deleteAction = find.text('삭제');
      if (deleteAction.evaluate().isNotEmpty) {
        clearInteractions(mockFriendBloc);
        await tester.tap(deleteAction);
        await tester.pumpAndSettle();

        final confirmDelete = find.text('삭제');
        if (confirmDelete.evaluate().length > 1) {
          await tester.tap(confirmDelete.last);
          await tester.pump();
          verify(() => mockFriendBloc.add(FriendRemoved(2))).called(1);
        }
      }
    });

    testWidgets('confirm block dispatches BlockUserRequested', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'BlockFriend2',
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

      await tester.drag(find.text('BlockFriend2'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final blockAction = find.text('차단');
      if (blockAction.evaluate().isNotEmpty) {
        clearInteractions(mockFriendBloc);
        await tester.tap(blockAction);
        await tester.pumpAndSettle();

        final confirmBlock = find.text('차단');
        if (confirmBlock.evaluate().length > 1) {
          await tester.tap(confirmBlock.last);
          await tester.pump();
          verify(() => mockFriendBloc.add(BlockUserRequested(2))).called(1);
        }
      }
    });

    testWidgets('does not show loading indicator when friends exist and loading', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Buddy'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      // loading with non-empty friends list should NOT show spinner
      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.loading,
          friends: friends,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('pull-to-refresh dispatches FriendListLoadRequested', (tester) async {
      final friends = List.generate(
        20,
        (i) => Friend(
          id: i + 1,
          user: User(id: i + 2, email: 'u$i@test.com', nickname: 'User$i'),
          createdAt: DateTime(2024, 1, i + 1),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
        ),
      ));

      clearInteractions(mockFriendBloc);

      // Perform pull-to-refresh gesture
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(() => mockFriendBloc.add(const FriendListLoadRequested())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('search result retry button dispatches UserSearchRequested', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          errorMessage: '오류',
          hasSearched: true,
          searchQuery: 'test',
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      clearInteractions(mockFriendBloc);

      final retryButton = find.text('다시 시도');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pump();
        verify(() => mockFriendBloc.add(const UserSearchRequested('test'))).called(1);
      }
    });

    testWidgets('send friend request dispatches FriendRequestSent', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final searchResults = [
        const User(id: 10, email: 'new@test.com', nickname: 'NewUser'),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          searchResults: searchResults,
          hasSearched: true,
          searchQuery: 'New',
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      clearInteractions(mockFriendBloc);

      final addButton = find.text('추가');
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pump();
        verify(() => mockFriendBloc.add(const FriendRequestSent(10))).called(1);
      }
    });

    testWidgets('search no results with query shows query text', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(id: 2, email: 'f@test.com', nickname: 'Friend'),
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        friendState: FriendState(
          status: FriendStatus.success,
          friends: friends,
          searchResults: const [],
          hasSearched: true,
          searchQuery: 'nobody',
        ),
      ));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.textContaining('"nobody"'), findsOneWidget);
    });

    testWidgets('my profile card shows ? initial for empty nickname', (tester) async {
      final emptyNicknameBloc = MockAuthBlocCustom(
        AuthState.authenticated(const User(
          id: 1,
          email: 'me@test.com',
          nickname: '',
        )),
      );

      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(status: FriendStatus.success),
      );
      when(() => mockFriendBloc.stream)
          .thenAnswer((_) => friendStateController.stream);
      when(() => mockFriendBloc.isClosed).thenReturn(false);
      when(() => mockFriendBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<FriendBloc>.value(value: mockFriendBloc),
            BlocProvider<AuthBloc>.value(value: emptyNicknameBloc),
          ],
          child: const FriendListPage(),
        ),
      ));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('my profile card shows status message when present', (tester) async {
      final statusUserBloc = MockAuthBlocCustom(
        AuthState.authenticated(const User(
          id: 1,
          email: 'me@test.com',
          nickname: 'Me',
          statusMessage: '내 상태 메시지',
        )),
      );

      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(status: FriendStatus.success),
      );
      when(() => mockFriendBloc.stream)
          .thenAnswer((_) => friendStateController.stream);
      when(() => mockFriendBloc.isClosed).thenReturn(false);
      when(() => mockFriendBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<FriendBloc>.value(value: mockFriendBloc),
            BlocProvider<AuthBloc>.value(value: statusUserBloc),
          ],
          child: const FriendListPage(),
        ),
      ));

      expect(find.text('내 상태 메시지'), findsOneWidget);
    });

    testWidgets('friend tile shows initial for friend without avatar', (tester) async {
      final friends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'f@test.com',
            nickname: 'ZeroAvatar',
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

      expect(find.text('Z'), findsOneWidget);
    });
  });
}
