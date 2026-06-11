import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/widgets/entry_animation.dart';

void main() {
  group('EntryAnimation', () {
    testWidgets('animate:true — 시작 시 opacity < 1, settle 후 opacity == 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntryAnimation(
              child: Text('x'),
            ),
          ),
        ),
      );

      // 첫 pump 이후 애니메이션 중간 지점(duration 절반)으로 이동
      // Duration.zero 는 vsync 가 즉시 완료 처리하므로 절반 duration 을 사용
      await tester.pump(const Duration(milliseconds: 125)); // half of normal(250ms)

      // EntryAnimation 위젯 내부의 FadeTransition 을 직접 찾는다
      // (MaterialApp 라우트 전환이 삽입하는 FadeTransition 과 구분하기 위해
      //  EntryAnimation 의 descendant 로 범위를 좁힌다)
      final entryFinder = find.byType(EntryAnimation);
      final fadeTransition = tester.widget<FadeTransition>(
        find.descendant(of: entryFinder, matching: find.byType(FadeTransition)).first,
      );
      expect(fadeTransition.opacity.value, lessThan(1.0));

      // SlideTransition 도 EntryAnimation 내부에 있어야 한다
      expect(
        find.descendant(of: entryFinder, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );

      // 애니메이션 완료
      await tester.pumpAndSettle();

      final fadeTransitionAfter = tester.widget<FadeTransition>(
        find.descendant(of: entryFinder, matching: find.byType(FadeTransition)).first,
      );
      expect(fadeTransitionAfter.opacity.value, equals(1.0));

      // offset 이 Offset.zero 로 settle
      final slideTransition = tester.widget<SlideTransition>(
        find.descendant(of: entryFinder, matching: find.byType(SlideTransition)).first,
      );
      expect(slideTransition.position.value, equals(Offset.zero));
    });

    testWidgets('animate:false — FadeTransition/SlideTransition 없이 child 를 직접 렌더링',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntryAnimation(
              animate: false,
              child: Text('x'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final entryFinder = find.byType(EntryAnimation);

      // animate:false 이면 EntryAnimation 내부에 FadeTransition/SlideTransition 이 없어야 한다
      expect(
        find.descendant(of: entryFinder, matching: find.byType(FadeTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: entryFinder, matching: find.byType(SlideTransition)),
        findsNothing,
      );

      // child 는 그대로 렌더링
      expect(find.text('x'), findsOneWidget);
    });
  });
}
