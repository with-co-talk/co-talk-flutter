import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/friends/friend_settings_page.dart';
import 'package:co_talk_flutter/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  setUp(() {
    // Mock router with all required routes
    router = GoRouter(
      initialLocation: AppRoutes.friendSettings,
      routes: [
        GoRoute(
          path: AppRoutes.friends,
          builder: (context, state) => const Scaffold(body: Text('Friends')),
        ),
        GoRoute(
          path: AppRoutes.friendSettings,
          builder: (context, state) => const FriendSettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.receivedRequests,
          builder: (context, state) => const Scaffold(body: Text('Received Requests')),
        ),
        GoRoute(
          path: AppRoutes.sentRequests,
          builder: (context, state) => const Scaffold(body: Text('Sent Requests')),
        ),
        GoRoute(
          path: AppRoutes.hiddenFriends,
          builder: (context, state) => const Scaffold(body: Text('Hidden Friends')),
        ),
        GoRoute(
          path: AppRoutes.blockedUsers,
          builder: (context, state) => const Scaffold(body: Text('Blocked Users')),
        ),
      ],
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('FriendSettingsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // "친구 관리" appears twice: once in AppBar and once as section title
      expect(find.text('친구 관리'), findsNWidgets(2));
    });

    testWidgets('renders all section titles', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('친구 요청'), findsOneWidget);
      // "친구 관리" appears twice: AppBar title + section title
      expect(find.text('친구 관리'), findsNWidgets(2));
    });

    testWidgets('renders all menu items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('친구 추가'), findsOneWidget);
      expect(find.text('받은 친구 요청'), findsOneWidget);
      expect(find.text('보낸 친구 요청'), findsOneWidget);
      expect(find.text('숨김 친구 관리'), findsOneWidget);
      expect(find.text('차단 사용자 관리'), findsOneWidget);
    });

    testWidgets('renders subtitles for menu items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('닉네임으로 친구를 검색하세요'), findsOneWidget);
      expect(find.text('수락 대기 중인 요청을 확인하세요'), findsOneWidget);
      expect(find.text('보낸 요청을 확인하세요'), findsOneWidget);
      expect(find.text('숨긴 친구를 확인하세요'), findsOneWidget);
      expect(find.text('차단한 사용자를 관리하세요'), findsOneWidget);
    });

    testWidgets('renders all icons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('navigates to friends page when 친구 추가 is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('친구 추가'));
      await tester.pumpAndSettle();

      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('navigates to received requests page when 받은 친구 요청 is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('받은 친구 요청'));
      await tester.pumpAndSettle();

      expect(find.text('Received Requests'), findsOneWidget);
    });

    testWidgets('navigates to sent requests page when 보낸 친구 요청 is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('보낸 친구 요청'));
      await tester.pumpAndSettle();

      expect(find.text('Sent Requests'), findsOneWidget);
    });

    testWidgets('navigates to hidden friends page when 숨김 친구 관리 is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('숨김 친구 관리'));
      await tester.pumpAndSettle();

      expect(find.text('Hidden Friends'), findsOneWidget);
    });

    testWidgets('navigates to blocked users page when 차단 사용자 관리 is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('차단 사용자 관리'));
      await tester.pumpAndSettle();

      expect(find.text('Blocked Users'), findsOneWidget);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify back button exists in AppBar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders ListTile widgets for each menu item', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 5 menu items should have ListTile
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('renders chevron icons for all menu items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // All 5 menu items should have chevron_right icon
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
    });
  });
}
