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

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthBloc', () {
    test('initial state is AuthState.initial', () {
      final bloc = AuthBloc(mockAuthRepository);
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
          return AuthBloc(mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when user is not logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => false);
          return AuthBloc(mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verifyNever(() => mockAuthRepository.getCurrentUser());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return AuthBloc(mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
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
          return AuthBloc(mockAuthRepository);
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
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when login fails',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Invalid credentials'));
          return AuthBloc(mockAuthRepository);
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
        'emits [loading, failure] when getCurrentUser returns null after login',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return AuthBloc(mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthState.loading(),
          const AuthState.failure('사용자 정보를 가져올 수 없습니다'),
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
          return AuthBloc(mockAuthRepository);
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
          return AuthBloc(mockAuthRepository);
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
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return AuthBloc(mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when logout fails',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenThrow(Exception('Logout failed'));
          return AuthBloc(mockAuthRepository);
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
    });
  });
}
