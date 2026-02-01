import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/blocked_users_page.dart';
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

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: BlockedUsersPage(),
    );
  }

  final blockedUser1 = const User(
    id: 1,
    email: 'blocked1@example.com',
    nickname: 'BlockedUser1',
    status: UserStatus.active,
    role: UserRole.user,
  );

  final blockedUser2 = const User(
    id: 2,
    email: 'blocked2@example.com',
    nickname: 'BlockedUser2',
    status: UserStatus.active,
    role: UserRole.user,
  );

  group('BlockedUsersPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('차단 사용자'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading indicator initially when loading and list is empty', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(isBlockedUsersLoading: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading indicator when loading but list is not empty', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          isBlockedUsersLoading: true,
          blockedUsers: [blockedUser1],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows empty state when no blocked users', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          isBlockedUsersLoading: false,
          blockedUsers: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
      expect(find.text('차단한 사용자가 없습니다'), findsOneWidget);
      expect(find.text('차단한 사용자가 여기에 표시됩니다'), findsOneWidget);
    });

    testWidgets('shows error state when error occurs with empty list', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          errorMessage: 'Network error',
          blockedUsers: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('차단 목록을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches BlockedUsersLoadRequested on retry button tap', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(errorMessage: 'Error'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Clear initial load event
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const BlockedUsersLoadRequested())).called(1);
    });

    testWidgets('displays list of blocked users', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          blockedUsers: [blockedUser1, blockedUser2],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('BlockedUser1'), findsOneWidget);
      expect(find.text('blocked1@example.com'), findsOneWidget);
      expect(find.text('BlockedUser2'), findsOneWidget);
      expect(find.text('blocked2@example.com'), findsOneWidget);
    });

    testWidgets('shows user avatar with initial when no avatarUrl', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          blockedUsers: [blockedUser1],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('B'), findsOneWidget); // First letter of BlockedUser1
    });

    testWidgets('shows user initial when no avatar', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          blockedUsers: [blockedUser2],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isNull);
    });

    testWidgets('shows unblock button for each blocked user', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          blockedUsers: [blockedUser1],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('차단 해제'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });






  });
}
