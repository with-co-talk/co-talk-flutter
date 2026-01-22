import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/pages/profile/profile_page.dart';
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
        child: const ProfilePage(),
      ),
    );
  }

  group('ProfilePage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('프로필'), findsOneWidget);
    });

    testWidgets('shows loading indicator when user is null', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows user nickname', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('shows user email', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('shows user avatar with first letter of nickname', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('shows status info', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          status: UserStatus.active,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('상태'), findsOneWidget);
      expect(find.text('활성'), findsOneWidget);
    });

    testWidgets('shows online status info', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          onlineStatus: OnlineStatus.online,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('온라인 상태'), findsOneWidget);
      expect(find.text('온라인'), findsOneWidget);
    });

    testWidgets('shows offline status', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          onlineStatus: OnlineStatus.offline,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('오프라인'), findsOneWidget);
    });

    testWidgets('shows away status', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          onlineStatus: OnlineStatus.away,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('자리 비움'), findsOneWidget);
    });

    testWidgets('shows join date', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          createdAt: DateTime(2024, 5, 15),
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('가입일'), findsOneWidget);
      expect(find.text('2024년 5월 15일'), findsOneWidget);
    });

    testWidgets('shows hyphen when join date is null', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          createdAt: null,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('shows edit button in app bar', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows camera icon on avatar', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('shows inactive status', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          status: UserStatus.inactive,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('비활성'), findsOneWidget);
    });

    testWidgets('shows suspended status', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
          status: UserStatus.suspended,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('정지됨'), findsOneWidget);
    });
  });
}
