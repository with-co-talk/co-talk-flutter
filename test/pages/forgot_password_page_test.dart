import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/forgot_password_bloc.dart';
import 'package:co_talk_flutter/presentation/pages/auth/forgot_password_page.dart';

class MockForgotPasswordBloc extends Mock implements ForgotPasswordBloc {}

class FakeForgotPasswordEvent extends Fake implements ForgotPasswordEvent {}

void main() {
  late MockForgotPasswordBloc mockBloc;
  late StreamController<ForgotPasswordState> stateController;

  setUpAll(() {
    registerFallbackValue(FakeForgotPasswordEvent());
  });

  setUp(() {
    mockBloc = MockForgotPasswordBloc();
    stateController = StreamController<ForgotPasswordState>.broadcast();
    when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => mockBloc.isClosed).thenReturn(false);
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    stateController.close();
  });

  Widget createWidgetUnderTest({ForgotPasswordState? initialState}) {
    final state = initialState ?? const ForgotPasswordState();
    when(() => mockBloc.state).thenReturn(state);

    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (context, routerState) =>
              BlocProvider<ForgotPasswordBloc>.value(
            value: mockBloc,
            child: const ForgotPasswordPage(),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, routerState) =>
              const Scaffold(body: Text('Login')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('ForgotPasswordPage - email step', () {
    testWidgets('앱바 타이틀 "비밀번호 찾기"를 렌더링한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('비밀번호 찾기'), findsOneWidget);
    });

    testWidgets('이메일 입력 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('이메일'), findsOneWidget);
    });

    testWidgets('"인증 코드 받기" 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('인증 코드 받기'), findsOneWidget);
    });

    testWidgets('initial 상태에서 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('loading 상태에서 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          status: ForgotPasswordStatus.loading,
        ),
      ));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading 상태에서 CircularProgressIndicator를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          status: ForgotPasswordStatus.loading,
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('이메일 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('인증 코드 받기'));
      await tester.pump();

      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    });

    testWidgets('유효한 이메일 입력 후 버튼 탭 시 ForgotPasswordCodeRequested 이벤트를 디스패치한다',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('인증 코드 받기'));
      await tester.pump();

      verify(() => mockBloc.add(
            ForgotPasswordCodeRequested(email: 'test@example.com'),
          )).called(1);
    });

    testWidgets('failure 상태에서 에러 메시지 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final failureState = const ForgotPasswordState(
        status: ForgotPasswordStatus.failure,
        errorMessage: '사용자를 찾을 수 없습니다',
      );
      when(() => mockBloc.state).thenReturn(failureState);
      stateController.add(failureState);
      // pump twice: first to process stream event, second to show SnackBar
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('사용자를 찾을 수 없습니다'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - code step', () {
    testWidgets('code 단계에서 인증 코드 입력 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      expect(find.text('인증 코드 (6자리)'), findsOneWidget);
    });

    testWidgets('code 단계에서 "인증 코드 확인" 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      expect(find.text('인증 코드 확인'), findsOneWidget);
    });

    testWidgets('code 단계에서 "인증 코드 재발송" 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      expect(find.text('인증 코드 재발송'), findsOneWidget);
    });

    testWidgets('code 단계 loading 상태에서 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          status: ForgotPasswordStatus.loading,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('인증 코드 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('인증 코드 확인'));
      await tester.pump();

      expect(find.text('인증 코드를 입력해주세요'), findsOneWidget);
    });

    testWidgets('6자리 코드 입력 후 확인 버튼 탭 시 ForgotPasswordCodeVerified 이벤트를 디스패치한다',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: 'test@example.com',
        ),
      ));
      await tester.pump();

      final codeField = find.byType(TextFormField);
      expect(codeField, findsOneWidget);
      await tester.enterText(codeField, '123456');
      await tester.pump();

      await tester.tap(find.text('인증 코드 확인'));
      await tester.pump();

      verify(() => mockBloc.add(any(
            that: isA<ForgotPasswordCodeVerified>(),
          ))).called(1);
    });
  });

  group('ForgotPasswordPage - new password step', () {
    testWidgets('newPassword 단계에서 새 비밀번호 필드들을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: 'test@example.com',
          code: '123456',
        ),
      ));
      await tester.pump();

      expect(find.text('새 비밀번호'), findsOneWidget);
      expect(find.text('새 비밀번호 확인'), findsOneWidget);
    });

    testWidgets('newPassword 단계에서 "비밀번호 변경" 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: 'test@example.com',
          code: '123456',
        ),
      ));
      await tester.pump();

      expect(find.text('비밀번호 변경'), findsOneWidget);
    });

    testWidgets('newPassword 단계 loading 상태에서 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          status: ForgotPasswordStatus.loading,
          email: 'test@example.com',
          code: '123456',
        ),
      ));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('complete 단계 전환 시 성공 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: 'test@example.com',
          code: '123456',
        ),
      ));
      await tester.pump();

      final completeState = const ForgotPasswordState(
        step: ForgotPasswordStep.complete,
      );
      when(() => mockBloc.state).thenReturn(completeState);
      stateController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('비밀번호가 성공적으로 변경되었습니다'), findsOneWidget);
    });
  });
}
