import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

void main() {
  final testUser = User(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  group('AuthEvent', () {
    group('AuthCheckRequested', () {
      test('creates event', () {
        const event = AuthCheckRequested();
        expect(event, isA<AuthEvent>());
      });

      test('equality works', () {
        const event1 = AuthCheckRequested();
        const event2 = AuthCheckRequested();
        expect(event1, equals(event2));
      });

      test('props is empty', () {
        const event = AuthCheckRequested();
        expect(event.props, isEmpty);
      });
    });

    group('AuthLoginRequested', () {
      test('creates event with email and password', () {
        const event = AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(event.email, 'test@example.com');
        expect(event.password, 'password123');
      });

      test('equality works', () {
        const event1 = AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        );
        const event2 = AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        );
        const event3 = AuthLoginRequested(
          email: 'other@example.com',
          password: 'password123',
        );

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('props contains email and password', () {
        const event = AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(event.props, contains('test@example.com'));
        expect(event.props, contains('password123'));
      });
    });

    group('AuthSignUpRequested', () {
      test('creates event with email, password, and nickname', () {
        const event = AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        );

        expect(event.email, 'test@example.com');
        expect(event.password, 'password123');
        expect(event.nickname, 'TestUser');
      });

      test('equality works', () {
        const event1 = AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        );
        const event2 = AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        );

        expect(event1, equals(event2));
      });

      test('props contains all fields', () {
        const event = AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        );

        expect(event.props, contains('test@example.com'));
        expect(event.props, contains('password123'));
        expect(event.props, contains('TestUser'));
      });
    });

    group('AuthLogoutRequested', () {
      test('creates event', () {
        const event = AuthLogoutRequested();
        expect(event, isA<AuthEvent>());
      });

      test('equality works', () {
        const event1 = AuthLogoutRequested();
        const event2 = AuthLogoutRequested();
        expect(event1, equals(event2));
      });
    });
  });

  group('AuthState', () {
    test('initial state', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('creates state with all fields', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        errorMessage: null,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.user, testUser);
    });

    test('copyWith creates new state', () {
      const state = AuthState();

      final newState = state.copyWith(
        status: AuthStatus.loading,
      );

      expect(newState.status, AuthStatus.loading);
      expect(newState.user, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
      );

      final newState = state.copyWith(status: AuthStatus.loading);

      expect(newState.user, testUser);
    });

    test('equality works', () {
      const state1 = AuthState(status: AuthStatus.initial);
      const state2 = AuthState(status: AuthStatus.initial);
      const state3 = AuthState(status: AuthStatus.loading);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props contains all fields', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        errorMessage: 'Error',
      );

      expect(state.props.length, 3);
    });
  });

  group('AuthStatus', () {
    test('has all expected values', () {
      expect(AuthStatus.values.length, 5);
      expect(AuthStatus.values, contains(AuthStatus.initial));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.failure));
    });
  });
}
