import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/pages/settings/settings_page.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

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
        child: const SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('shows all settings sections', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림'), findsOneWidget);
      expect(find.text('일반'), findsOneWidget);
      expect(find.text('계정'), findsOneWidget);
      expect(find.text('정보'), findsOneWidget);
    });

    testWidgets('shows notification settings', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 설정'), findsOneWidget);
    });

    testWidgets('shows general settings', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('언어'), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('다크 모드'), findsOneWidget);
    });

    testWidgets('shows account settings', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('비밀번호 변경'), findsOneWidget);
      expect(find.text('차단 관리'), findsOneWidget);
    });

    testWidgets('shows info section', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('앱 버전'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('이용약관'), findsOneWidget);
      expect(find.text('개인정보 처리방침'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Scroll down to find logout button
      await tester.scrollUntilVisible(
        find.text('로그아웃'),
        100,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('로그아웃'), findsOneWidget);
    });

    testWidgets('shows dark mode switch', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog when logout button is pressed', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      // Use a larger screen size to fit all content
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the logout button (OutlinedButton)
      final logoutButton = find.widgetWithText(OutlinedButton, '로그아웃');
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
