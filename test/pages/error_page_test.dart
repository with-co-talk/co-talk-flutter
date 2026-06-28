import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/pages/error/error_page.dart';
import 'package:co_talk_flutter/presentation/widgets/gradient_button.dart';

Widget _wrap(Widget home) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('ErrorPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage()));

      expect(find.text('오류'), findsOneWidget);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage()));

      // Warm Sand 리뉴얼: EmptyStateView 스타일의 친근한 에러 아이콘(cloud_off_rounded)
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('shows default error message when message is null', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage()));

      expect(find.text('페이지를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows custom error message when provided', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage(message: '커스텀 에러 메시지')));

      expect(find.text('커스텀 에러 메시지'), findsOneWidget);
    });

    testWidgets('shows home button', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage()));

      expect(find.text('홈으로 돌아가기'), findsOneWidget);
    });

    testWidgets('home button exists and is enabled', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorPage()));

      // Warm Sand 리뉴얼: 홈 버튼이 공용 GradientButton 으로 변경
      final button = find.widgetWithText(GradientButton, '홈으로 돌아가기');
      expect(button, findsOneWidget);

      // Verify button is enabled
      final gradientButton = tester.widget<GradientButton>(button);
      expect(gradientButton.onPressed, isNotNull);
    });
  });
}
