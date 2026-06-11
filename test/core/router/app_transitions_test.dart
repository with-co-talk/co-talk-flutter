import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:co_talk_flutter/core/router/app_transitions.dart';
import 'package:co_talk_flutter/core/theme/app_motion.dart';

void main() {
  testWidgets('fade-through page renders its child', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => buildPageWithFadeThrough(
            state: state,
            child: const Text('hello'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    // 전환 위젯이 트리에 존재 (페이드)
    expect(find.byType(FadeTransition), findsWidgets);
    // 슬라이드 전환도 존재해야 함 — 제거 시 회귀를 감지
    expect(find.byType(SlideTransition), findsWidgets);
  });

  testWidgets('uses AppMotion.normal as forward transition duration',
      (tester) async {
    late CustomTransitionPage page;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            page = buildPageWithFadeThrough(
              state: state,
              child: const Text('x'),
            );
            return page;
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(page.transitionDuration, AppMotion.normal);
    expect(page.reverseTransitionDuration, AppMotion.fast);
  });
}
