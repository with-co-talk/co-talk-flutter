import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/pages/main/main_page.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import '../mocks/fake_entities.dart';

class MockChatListBloc extends Mock implements ChatListBloc {
  @override
  ChatListState get state => const ChatListState();

  @override
  Stream<ChatListState> get stream => const Stream.empty();

  @override
  Future<void> close() async {}
}

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => AuthState.authenticated(FakeEntities.user);

  @override
  Stream<AuthState> get stream => const Stream.empty();

  @override
  Future<void> close() async {}
}

class StreamableMockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

class StreamableMockChatListBloc extends Mock implements ChatListBloc {
  @override
  Future<void> close() async {}
}

void main() {
  late MockChatListBloc mockChatListBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockChatListBloc = MockChatListBloc();
    mockAuthBloc = MockAuthBloc();
  });

  Widget createTestWidget({required Widget child, Size size = const Size(400, 800)}) {
    final router = GoRouter(
      initialLocation: '/friends',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainPage(child: child),
          routes: [
            GoRoute(
              path: '/friends',
              builder: (context, state) => child,
            ),
            GoRoute(
              path: '/chat',
              builder: (context, state) => const Text('Chat'),
            ),
          ],
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatListBloc>.value(value: mockChatListBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('MainPage', () {
    testWidgets('renders mobile layout with bottom navigation bar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders desktop layout with navigation rail', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows all navigation destinations in mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      // MainPage has 2 tabs: 친구 (friends) and 채팅 (chat)
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('채팅'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows all navigation destinations in desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      // MainPage has 2 tabs: 친구 (friends) and 채팅 (chat)
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('채팅'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('shows navigation icons in mobile navigation', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Test')));
      await tester.pumpAndSettle();

      // When on /friends route:
      // - Friends tab is selected -> shows Icons.people (filled)
      // - Chat tab is not selected -> shows Icons.chat_outlined (outlined)
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders child widget', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(child: const Text('Child Content')));
      await tester.pumpAndSettle();

      expect(find.text('Child Content'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    group('account switch resubscription', () {
      late StreamableMockAuthBloc streamableAuthBloc;
      late StreamableMockChatListBloc streamableChatListBloc;

      setUp(() {
        streamableAuthBloc = StreamableMockAuthBloc();
        streamableChatListBloc = StreamableMockChatListBloc();
      });

      testWidgets('re-subscribes with new userId on account switch', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final authController = StreamController<AuthState>.broadcast();

        // Initial state: user 1
        final initialAuthState = AuthState.authenticated(const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'User1',
        ));

        when(() => streamableAuthBloc.state).thenReturn(initialAuthState);
        whenListen(streamableAuthBloc, authController.stream, initialState: initialAuthState);
        when(() => streamableChatListBloc.state).thenReturn(const ChatListState());
        whenListen(streamableChatListBloc, const Stream<ChatListState>.empty(), initialState: const ChatListState());

        final router = GoRouter(
          initialLocation: '/friends',
          routes: [
            ShellRoute(
              builder: (context, state, child) => MainPage(child: child),
              routes: [
                GoRoute(
                  path: '/friends',
                  builder: (context, state) => const Text('Friends'),
                ),
                GoRoute(
                  path: '/chat',
                  builder: (context, state) => const Text('Chat'),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ChatListBloc>.value(value: streamableChatListBloc),
              BlocProvider<AuthBloc>.value(value: streamableAuthBloc),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Clear initial interactions from didChangeDependencies
        clearInteractions(streamableChatListBloc);

        // Account switch: change to user 2
        final newAuthState = AuthState.authenticated(const User(
          id: 2,
          email: 'test2@test.com',
          nickname: 'User2',
        ));
        when(() => streamableAuthBloc.state).thenReturn(newAuthState);
        authController.add(newAuthState);
        await tester.pump();
        await tester.pump();

        verify(() => streamableChatListBloc.add(const ChatListSubscriptionStopped())).called(1);
        verify(() => streamableChatListBloc.add(const ChatListSubscriptionStarted(2))).called(1);

        await authController.close();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });
  });
}
