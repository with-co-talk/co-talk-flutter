import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockWebSocketService mockWebSocketService;
  late MockChatRepository mockChatRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockDesktopNotificationBridge mockDesktopNotificationBridge;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockWebSocketService = MockWebSocketService();
    mockChatRepository = MockChatRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockDesktopNotificationBridge = MockDesktopNotificationBridge();

    // WebSocketService mock 기본 설정
    when(() => mockWebSocketService.connect()).thenAnswer((_) async {});
    when(() => mockWebSocketService.disconnect()).thenReturn(null);

    // ChatRepository mock 기본 설정
    when(() => mockChatRepository.clearLocalData()).thenAnswer((_) async {});

    // NotificationRepository mock 기본 설정
    when(() => mockNotificationRepository.registerToken(userId: any(named: 'userId'), deviceType: any(named: 'deviceType')))
        .thenAnswer((_) async {});
    when(() => mockNotificationRepository.setupTokenRefreshListener(userId: any(named: 'userId'), deviceType: any(named: 'deviceType')))
        .thenReturn(null);
    when(() => mockNotificationRepository.unregisterToken()).thenAnswer((_) async {});
    when(() => mockNotificationRepository.disposeTokenRefreshListener()).thenReturn(null);

    // DesktopNotificationBridge mock 기본 설정
    when(() => mockDesktopNotificationBridge.setCurrentUserId(any())).thenReturn(null);
  });

  AuthBloc createBloc() => AuthBloc(
        mockAuthRepository,
        mockWebSocketService,
        mockChatRepository,
        mockNotificationRepository,
        mockDesktopNotificationBridge,
      );

  group('AuthBloc', () {
    test('initial state is AuthState.initial', () {
      final bloc = createBloc();
      expect(bloc.state, const AuthState.initial());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when user is logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when user is not logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => false);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verifyNever(() => mockAuthRepository.getCurrentUser());
          verifyNever(() => mockWebSocketService.connect());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when isLoggedIn throws exception',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when login succeeds',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.login(
                email: 'test@example.com',
                password: 'password123',
              )).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when login fails',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Invalid credentials'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with placeholder user when getCurrentUser returns null after login',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockAuthRepository.getCurrentUserId())
              .thenAnswer((_) async => 1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticated,
          ),
        ],
      );
    });

    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when sign up and auto-login succeed',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenAnswer((_) async => 1);
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signUp(
                email: 'test@example.com',
                password: 'password123',
                nickname: 'TestUser',
              )).called(1);
          verify(() => mockAuthRepository.login(
                email: 'test@example.com',
                password: 'password123',
              )).called(1);
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when sign up fails',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenThrow(Exception('Email already exists'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'existing@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with placeholder user when getCurrentUser returns null after signup',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenAnswer((_) async => 1);
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockAuthRepository.getCurrentUserId())
              .thenAnswer((_) async => 1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticated,
          ),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockWebSocketService.disconnect()).called(1);
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when logout fails',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenThrow(Exception('Logout failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'logout 시 로컬 채팅 데이터를 삭제함',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockChatRepository.clearLocalData()).called(1);
        },
      );
    });
  });
}
