import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/auth/find_email_result_page.dart';

void main() {
  Widget createWidgetUnderTest({String maskedEmail = 'te**@example.com'}) {
    return MaterialApp(
      home: FindEmailResultPage(maskedEmail: maskedEmail),
    );
  }

  group('FindEmailResultPage', () {
    testWidgets('아이디 찾기 결과 타이틀을 렌더링한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('아이디 찾기 결과'), findsOneWidget);
    });

    testWidgets('마스킹된 이메일을 표시한다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(maskedEmail: 'te**@example.com'),
      );

      expect(find.text('te**@example.com'), findsOneWidget);
    });

    testWidgets('가입된 이메일을 찾았습니다 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('가입된 이메일을 찾았습니다'), findsOneWidget);
    });

    testWidgets('로그인하기 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('로그인하기'), findsOneWidget);
    });

    testWidgets('비밀번호 찾기 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('비밀번호 찾기'), findsOneWidget);
    });
  });
}
