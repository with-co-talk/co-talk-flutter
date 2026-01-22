import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:co_talk_flutter/presentation/pages/main/main_page.dart';

void main() {
  Widget createTestWidget({required Widget child, Size size = const Size(400, 800)}) {
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainPage(child: child),
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => child,
            ),
            GoRoute(
              path: '/friends',
              builder: (context, state) => const Text('Friends'),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const Text('Profile'),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Text('Settings'),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('MainPage', () {
    testWidgets('renders mobile layout with bottom navigation bar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders desktop layout with navigation rail', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows all navigation destinations in mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.text('채팅'), findsOneWidget);
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('프로필'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows all navigation destinations in desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.text('채팅'), findsOneWidget);
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('프로필'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows chat icon in mobile navigation', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.byIcon(Icons.people_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders child widget', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Child Content')));
      await tester.pumpAndSettle();

      expect(find.text('Child Content'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
