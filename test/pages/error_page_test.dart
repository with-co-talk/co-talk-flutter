import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/error/error_page.dart';

void main() {
  group('ErrorPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(),
        ),
      );

      expect(find.text('오류'), findsOneWidget);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows default error message when message is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(),
        ),
      );

      expect(find.text('페이지를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows custom error message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(message: '커스텀 에러 메시지'),
        ),
      );

      expect(find.text('커스텀 에러 메시지'), findsOneWidget);
    });

    testWidgets('shows home button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(),
        ),
      );

      expect(find.text('홈으로 돌아가기'), findsOneWidget);
    });

    testWidgets('home button exists and is enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorPage(),
        ),
      );

      final button = find.widgetWithText(ElevatedButton, '홈으로 돌아가기');
      expect(button, findsOneWidget);

      // Verify button is enabled
      final elevatedButton = tester.widget<ElevatedButton>(button);
      expect(elevatedButton.onPressed, isNotNull);
    });
  });
}
