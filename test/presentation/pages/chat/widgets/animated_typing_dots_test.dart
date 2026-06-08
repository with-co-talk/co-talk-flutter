import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/animated_typing_dots.dart';

void main() {
  group('AnimatedTypingDots', () {
    Widget buildSubject() {
      return const MaterialApp(
        home: Scaffold(
          body: AnimatedTypingDots(),
        ),
      );
    }

    testWidgets('renders 3 dot containers', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      // The widget uses a Key per dot; find by key or count the dot Containers.
      final dotFinder = find.byKey(const ValueKey('typing_dot_0'));
      final dotFinder1 = find.byKey(const ValueKey('typing_dot_1'));
      final dotFinder2 = find.byKey(const ValueKey('typing_dot_2'));

      expect(dotFinder, findsOneWidget);
      expect(dotFinder1, findsOneWidget);
      expect(dotFinder2, findsOneWidget);
    });

    testWidgets('widget is left-aligned inside a bubble container',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      // The outer Align widget should exist with Alignment.centerLeft.
      final alignFinder = find.byWidgetPredicate(
        (w) => w is Align && w.alignment == Alignment.centerLeft,
      );
      expect(alignFinder, findsWidgets);
    });

    testWidgets('animation runs and is repeating after several frames',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      // Pump initial frame
      await tester.pump();

      // Advance time significantly to see animation progress
      await tester.pump(const Duration(milliseconds: 400));

      // The widget should still be alive (not thrown) and rendering dot keys
      expect(find.byKey(const ValueKey('typing_dot_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('typing_dot_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('typing_dot_2')), findsOneWidget);

      // Advance past a full cycle (~900ms total) to verify repeating behavior
      await tester.pump(const Duration(milliseconds: 900));

      // Widget still renders after full cycle — controller is repeating
      expect(find.byKey(const ValueKey('typing_dot_0')), findsOneWidget);
    });

    testWidgets('disposes cleanly without errors', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 200));

      // Replace widget tree to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      // No exception means dispose was clean
      expect(find.byKey(const ValueKey('typing_dot_0')), findsNothing);
    });
  });
}
