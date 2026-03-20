import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_state.dart';
import 'package:co_talk_flutter/presentation/pages/auth/email_verification_page.dart';

class MockEmailVerificationBloc
    extends MockBloc<EmailVerificationEvent, EmailVerificationState>
    implements EmailVerificationBloc {}

class FakeEmailVerificationEvent extends Fake
    implements EmailVerificationEvent {}

void main() {
  late MockEmailVerificationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeEmailVerificationEvent());
  });

  setUp(() {
    mockBloc = MockEmailVerificationBloc();
  });

  Widget createWidgetUnderTest({String email = 'test@example.com'}) {
    return MaterialApp(
      home: BlocProvider<EmailVerificationBloc>.value(
        value: mockBloc,
        child: EmailVerificationPage(email: email),
      ),
    );
  }

  group('EmailVerificationPage', () {
    testWidgets('이메일 인증 타이틀을 렌더링한다', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.waiting());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('이메일 인증'), findsOneWidget);
    });

    testWidgets('제공된 이메일 주소를 포함하는 텍스트를 표시한다', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.waiting());

      await tester.pumpWidget(
        createWidgetUnderTest(email: 'user@example.com'),
      );

      expect(find.textContaining('user@example.com'), findsOneWidget);
    });

    testWidgets('인증 이메일 재발송 버튼을 표시한다', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.waiting());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('인증 이메일 재발송'), findsOneWidget);
    });

    testWidgets('로그인으로 돌아가기 버튼을 표시한다', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.waiting());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('로그인으로 돌아가기'), findsOneWidget);
    });

    testWidgets('resending 상태일 때 재발송 버튼이 비활성화된다', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.resending());

      await tester.pumpWidget(createWidgetUnderTest());

      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('resending 상태일 때 CircularProgressIndicator를 표시한다',
        (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.resending());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('재발송 버튼 탭 시 EmailVerificationResendRequested 이벤트를 디스패치한다',
        (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const EmailVerificationState.waiting());

      await tester.pumpWidget(
        createWidgetUnderTest(email: 'test@example.com'),
      );

      await tester.tap(find.text('인증 이메일 재발송'));
      await tester.pump();

      verify(() => mockBloc.add(
            const EmailVerificationResendRequested('test@example.com'),
          )).called(1);
    });
  });
}
