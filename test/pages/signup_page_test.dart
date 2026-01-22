import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/pages/auth/signup_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SignUpPage(),
      ),
    );
  }

  group('SignUpPage', () {
    testWidgets('renders signup form', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('회원가입'), findsWidgets);
      expect(find.text('이메일'), findsOneWidget);
      expect(find.text('닉네임'), findsOneWidget);
      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('비밀번호 확인'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    });

    testWidgets('shows validation error for empty nickname', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('닉네임을 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'TestUser');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'TestUser');
      await tester.enterText(fields.at(2), '1234567');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('비밀번호는 8자 이상이어야 합니다'), findsOneWidget);
    });

    testWidgets('shows validation error for password mismatch', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'TestUser');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password456');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    });

    testWidgets('dispatches AuthSignUpRequested on valid form submission', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'TestUser');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      verify(() => mockAuthBloc.add(const AuthSignUpRequested(
            email: 'test@example.com',
            password: 'password123',
            nickname: 'TestUser',
          ))).called(1);
    });

    testWidgets('shows loading indicator when state is loading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar on failure state', (tester) async {
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          const AuthState.initial(),
          const AuthState.failure('회원가입에 실패했습니다'),
        ]),
        initialState: const AuthState.initial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('회원가입에 실패했습니다'), findsOneWidget);
    });

    testWidgets('shows korean input warning for password', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), '한글비밀번호');
      await tester.pump();

      expect(find.text('한글이 입력되어 있습니다. 영문 키보드를 확인하세요.'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Initially visibility_off icons are shown
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tap first visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      // Now one visibility icon is shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
