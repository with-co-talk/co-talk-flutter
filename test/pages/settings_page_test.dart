import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/theme/theme_cubit.dart';
import 'package:co_talk_flutter/presentation/pages/settings/settings_page.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockThemeCubit extends Mock implements ThemeCubit {
  @override
  ThemeMode get state => ThemeMode.light;

  @override
  Stream<ThemeMode> get stream => const Stream.empty();

  @override
  bool isDarkMode(BuildContext context) => false;

  @override
  Future<void> close() async {}
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();
    authStateController = StreamController<AuthState>.broadcast();
  });

  tearDown(() {
    authStateController.close();
  });

  Widget createWidgetUnderTest({AuthState? authState}) {
    final state = authState ?? AuthState.authenticated(const User(
      id: 1,
      email: 'test@test.com',
      nickname: 'TestUser',
    ));
    when(() => mockAuthBloc.state).thenReturn(state);
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.isClosed).thenReturn(false);
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        ],
        child: const SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('shows all settings sections', (tester) async {
      // Use a larger screen size to fit all sections
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('프로필'), findsOneWidget);
      expect(find.text('알림'), findsOneWidget);
      expect(find.text('채팅'), findsOneWidget);
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('일반'), findsOneWidget);
      expect(find.text('계정'), findsOneWidget);
      expect(find.text('정보'), findsOneWidget);
    });

    testWidgets('shows notification settings', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 설정'), findsOneWidget);
    });

    testWidgets('shows general settings', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('언어'), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('다크 모드'), findsOneWidget);
    });

    testWidgets('shows account settings', (tester) async {
      // Use a larger screen size to fit all sections
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('비밀번호 변경'), findsOneWidget);
      expect(find.text('회원 탈퇴'), findsOneWidget);
    });

    testWidgets('shows info section', (tester) async {
      // Use a larger screen size to fit all sections
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('앱 버전'), findsOneWidget);
      // Version is loaded asynchronously, initial value is '...'
      expect(find.text('...'), findsOneWidget);
      expect(find.text('이용약관'), findsOneWidget);
      expect(find.text('개인정보 처리방침'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
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
      // Use a larger screen size to ensure the switch is visible
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog when logout button is pressed', (tester) async {
      // Use a larger screen size to fit all content
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Scroll to find the logout button
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, '로그아웃'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Find and tap the logout button (OutlinedButton)
      final logoutButton = find.widgetWithText(OutlinedButton, '로그아웃');
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });
  });
}
