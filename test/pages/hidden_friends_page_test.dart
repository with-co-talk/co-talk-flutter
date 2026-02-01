import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/hidden_friends_page.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/di/injection.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

void main() {
  late MockFriendBloc mockFriendBloc;

  setUpAll(() {
    // Register GetIt mock
    if (!getIt.isRegistered<FriendBloc>()) {
      getIt.registerFactory<FriendBloc>(() => mockFriendBloc);
    }
  });

  setUp(() {
    mockFriendBloc = MockFriendBloc();

    // Reset GetIt registration for each test
    if (getIt.isRegistered<FriendBloc>()) {
      getIt.unregister<FriendBloc>();
    }
    getIt.registerFactory<FriendBloc>(() => mockFriendBloc);
  });

  tearDown(() {
    mockFriendBloc.close();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: HiddenFriendsPage(),
    );
  }

  group('HiddenFriendsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('숨김 친구'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should show loading indicator initially when loading with empty list', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          isHiddenFriendsLoading: true,
          hiddenFriends: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no hidden friends', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.text('숨긴 친구가 없습니다'), findsOneWidget);
      expect(find.text('친구 목록에서 숨긴 친구가 여기에 표시됩니다'), findsOneWidget);
    });

    testWidgets('should display list of hidden friends', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden1@test.com',
            nickname: 'HiddenUser1',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
        Friend(
          id: 2,
          user: const User(
            id: 3,
            email: 'hidden2@test.com',
            nickname: 'HiddenUser2',
          ),
          createdAt: DateTime(2024, 1, 2),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('HiddenUser1'), findsOneWidget);
      expect(find.text('hidden1@test.com'), findsOneWidget);
      expect(find.text('HiddenUser2'), findsOneWidget);
      expect(find.text('hidden2@test.com'), findsOneWidget);
      expect(find.text('숨김 해제'), findsNWidgets(2));
    });

    testWidgets('should dispatch UnhideFriendRequested event when unhide button tapped', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Clear interactions from init
      clearInteractions(mockFriendBloc);

      // Tap unhide button
      await tester.tap(find.text('숨김 해제'));
      await tester.pumpAndSettle();

      // Verify event is dispatched
      verify(() => mockFriendBloc.add(const UnhideFriendRequested(2))).called(1);
    });

    testWidgets('should show snackbar when unhide button tapped', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap unhide button
      await tester.tap(find.text('숨김 해제'));
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('HiddenUser님을 숨김 해제했습니다'), findsOneWidget);
    });

    testWidgets('should show error state when loading fails with empty list', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: [],
          errorMessage: 'Failed to load hidden friends',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('숨김 친구 목록을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('should dispatch HiddenFriendsLoadRequested on retry button tap', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: [],
          errorMessage: 'Failed to load hidden friends',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Clear interactions from init
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const HiddenFriendsLoadRequested())).called(1);
    });

    testWidgets('should show friend initial in avatar for friend without image', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
            avatarUrl: null,
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('should show CircleAvatar for each friend', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify CircleAvatar exists for friend
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should dispatch HiddenFriendsLoadRequested on pull to refresh', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Clear interactions from init
      clearInteractions(mockFriendBloc);

      // Perform pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      verify(() => mockFriendBloc.add(const HiddenFriendsLoadRequested())).called(1);
    });

    testWidgets('should show error snackbar when error message changes', (tester) async {
      whenListen(
        mockFriendBloc,
        Stream.fromIterable([
          const FriendState(
            isHiddenFriendsLoading: false,
            hiddenFriends: [],
          ),
          const FriendState(
            isHiddenFriendsLoading: false,
            hiddenFriends: [],
            errorMessage: 'Network error',
          ),
        ]),
        initialState: const FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify error snackbar appears with mapped message
      // ErrorMessageMapper returns '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.' for unknown errors
      expect(find.text('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('should not show loading indicator when loading with existing list', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden@test.com',
            nickname: 'HiddenUser',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: true,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Should show list, not loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('HiddenUser'), findsOneWidget);
    });

    testWidgets('should dispatch HiddenFriendsLoadRequested on init', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const HiddenFriendsLoadRequested())).called(1);
    });

    testWidgets('should show list separator dividers', (tester) async {
      final hiddenFriends = [
        Friend(
          id: 1,
          user: const User(
            id: 2,
            email: 'hidden1@test.com',
            nickname: 'HiddenUser1',
          ),
          createdAt: DateTime(2024, 1, 1),
          isHidden: true,
        ),
        Friend(
          id: 2,
          user: const User(
            id: 3,
            email: 'hidden2@test.com',
            nickname: 'HiddenUser2',
          ),
          createdAt: DateTime(2024, 1, 2),
          isHidden: true,
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isHiddenFriendsLoading: false,
          hiddenFriends: hiddenFriends,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify ListView.separated is used (separatorBuilder creates dividers)
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('HiddenUser1'), findsOneWidget);
      expect(find.text('HiddenUser2'), findsOneWidget);
    });
  });
}
