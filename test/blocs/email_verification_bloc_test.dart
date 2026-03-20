import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/email_verification_state.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  EmailVerificationBloc createBloc() =>
      EmailVerificationBloc(mockAuthRepository);

  group('EmailVerificationBloc', () {
    test('initial state is EmailVerificationState.waiting', () {
      final bloc = createBloc();
      expect(bloc.state, const EmailVerificationState.waiting());
    });

    group('EmailVerificationResendRequested', () {
      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'emits resending then resent when resend succeeds',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.resendVerification(email: 'user@example.com'))
              .called(1);
        },
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'emits resending then error when resend fails',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles empty email',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.resendVerification(email: '')).called(1);
        },
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles invalid email format',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('invalid-email')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles multiple resend requests in sequence',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const EmailVerificationResendRequested('user1@example.com'))
          ..add(const EmailVerificationResendRequested('user2@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles specific error messages',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenThrow(Exception('이메일을 찾을 수 없습니다'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('unknown@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles rate limit errors',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenThrow(Exception('Too many requests'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles timeout errors',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenThrow(Exception('Timeout'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('EmailVerificationReset', () {
      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'resets to waiting state from resent',
        seed: () => const EmailVerificationState.resent(),
        build: createBloc,
        act: (bloc) => bloc.add(const EmailVerificationReset()),
        expect: () => [
          const EmailVerificationState.waiting(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'resets to waiting state from error',
        seed: () => const EmailVerificationState.error('Some error'),
        build: createBloc,
        act: (bloc) => bloc.add(const EmailVerificationReset()),
        expect: () => [
          const EmailVerificationState.waiting(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'resets to waiting state from resending',
        seed: () => const EmailVerificationState.resending(),
        build: createBloc,
        act: (bloc) => bloc.add(const EmailVerificationReset()),
        expect: () => [
          const EmailVerificationState.waiting(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'clears error message',
        seed: () => const EmailVerificationState.error('Error message'),
        build: createBloc,
        act: (bloc) => bloc.add(const EmailVerificationReset()),
        verify: (bloc) {
          expect(bloc.state.status, EmailVerificationStatus.waiting);
          expect(bloc.state.errorMessage, isNull);
        },
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles multiple resets',
        seed: () => const EmailVerificationState.error('Error'),
        build: createBloc,
        act: (bloc) => bloc
          ..add(const EmailVerificationReset())
          ..add(const EmailVerificationReset()),
        // Only one state change because second reset doesn't change state
        expect: () => [
          const EmailVerificationState.waiting(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'reset from waiting state is idempotent',
        build: createBloc,
        act: (bloc) => bloc.add(const EmailVerificationReset()),
        expect: () => [
          const EmailVerificationState.waiting(),
        ],
      );
    });

    group('State transitions', () {
      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'can resend after reset',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const EmailVerificationResendRequested('user@example.com'))
          ..add(const EmailVerificationReset())
          ..add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
          const EmailVerificationState.waiting(),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'can retry after error',
        build: () {
          var callCount = 0;
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('First attempt failed');
            }
          });
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const EmailVerificationResendRequested('user@example.com'))
          ..add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'maintains consistent state through error and reset cycle',
        build: () {
          var callCount = 0;
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Error');
            }
          });
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const EmailVerificationResendRequested('user@example.com'))
          ..add(const EmailVerificationReset())
          ..add(const EmailVerificationResendRequested('user@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          isA<EmailVerificationState>()
              .having((s) => s.status, 'status', EmailVerificationStatus.error),
          const EmailVerificationState.waiting(),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles very long email addresses',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(EmailVerificationResendRequested(
          'very.long.email.address.that.might.be.used.in.testing@example.com',
        )),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles special characters in email',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested('user+test@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );

      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles whitespace in email',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const EmailVerificationResendRequested(' user@example.com ')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.resendVerification(email: ' user@example.com '))
              .called(1);
        },
      );
    });

    group('Concurrent operations', () {
      blocTest<EmailVerificationBloc, EmailVerificationState>(
        'handles rapid successive resend requests',
        build: () {
          when(() => mockAuthRepository.resendVerification(email: any(named: 'email')))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const EmailVerificationResendRequested('user1@example.com'))
          ..add(const EmailVerificationResendRequested('user2@example.com'))
          ..add(const EmailVerificationResendRequested('user3@example.com')),
        expect: () => [
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
          const EmailVerificationState.resending(),
          const EmailVerificationState.resent(),
        ],
      );
    });
  });
}
