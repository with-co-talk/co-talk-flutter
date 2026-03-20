import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/forgot_password_bloc.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  ForgotPasswordBloc createBloc() => ForgotPasswordBloc(mockAuthRepository);

  group('ForgotPasswordBloc', () {
    test('초기 상태는 email 단계이고 initial 상태', () {
      final bloc = createBloc();
      expect(bloc.state.step, ForgotPasswordStep.email);
      expect(bloc.state.status, ForgotPasswordStatus.initial);
      expect(bloc.state.email, isNull);
      expect(bloc.state.code, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    group('ForgotPasswordCodeRequested', () {
      const testEmail = 'test@example.com';

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '유효한 이메일로 인증 코드 요청 성공',
        build: () {
          when(() => mockAuthRepository.requestPasswordResetCode(
                email: testEmail,
              )).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(ForgotPasswordCodeRequested(email: testEmail)),
        expect: () => [
          const ForgotPasswordState(status: ForgotPasswordStatus.loading),
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.success,
            email: testEmail,
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.requestPasswordResetCode(
                email: testEmail,
              )).called(1);
        },
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '존재하지 않는 이메일로 요청 실패',
        build: () {
          when(() => mockAuthRepository.requestPasswordResetCode(
                email: testEmail,
              )).thenThrow(Exception('사용자를 찾을 수 없습니다.'));
          return createBloc();
        },
        act: (bloc) => bloc.add(ForgotPasswordCodeRequested(email: testEmail)),
        expect: () => [
          const ForgotPasswordState(status: ForgotPasswordStatus.loading),
          const ForgotPasswordState(
            status: ForgotPasswordStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '네트워크 에러 처리',
        build: () {
          when(() => mockAuthRepository.requestPasswordResetCode(
                email: any(named: 'email'),
              )).thenThrow(Exception('네트워크 연결 실패'));
          return createBloc();
        },
        act: (bloc) => bloc.add(ForgotPasswordCodeRequested(email: testEmail)),
        expect: () => [
          const ForgotPasswordState(status: ForgotPasswordStatus.loading),
          const ForgotPasswordState(
            status: ForgotPasswordStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '빈 이메일로 요청 시 에러 처리',
        build: () {
          when(() => mockAuthRepository.requestPasswordResetCode(
                email: '',
              )).thenThrow(Exception('잘못된 요청입니다.'));
          return createBloc();
        },
        act: (bloc) => bloc.add(ForgotPasswordCodeRequested(email: '')),
        expect: () => [
          const ForgotPasswordState(status: ForgotPasswordStatus.loading),
          const ForgotPasswordState(
            status: ForgotPasswordStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '잘못된 이메일 형식으로 요청 시 에러 처리',
        build: () {
          when(() => mockAuthRepository.requestPasswordResetCode(
                email: 'invalid-email',
              )).thenThrow(Exception('잘못된 이메일 형식입니다.'));
          return createBloc();
        },
        act: (bloc) =>
            bloc.add(ForgotPasswordCodeRequested(email: 'invalid-email')),
        expect: () => [
          const ForgotPasswordState(status: ForgotPasswordStatus.loading),
          const ForgotPasswordState(
            status: ForgotPasswordStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );
    });

    group('ForgotPasswordCodeVerified', () {
      const testEmail = 'test@example.com';
      const testCode = '123456';

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '유효한 인증 코드 검증 성공',
        build: () {
          when(() => mockAuthRepository.verifyPasswordResetCode(
                email: testEmail,
                code: testCode,
              )).thenAnswer((_) async => true);
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: testEmail,
        ),
        act: (bloc) => bloc.add(ForgotPasswordCodeVerified(
          email: testEmail,
          code: testCode,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.success,
            email: testEmail,
            code: testCode,
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.verifyPasswordResetCode(
                email: testEmail,
                code: testCode,
              )).called(1);
        },
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '잘못된 인증 코드로 검증 실패',
        build: () {
          when(() => mockAuthRepository.verifyPasswordResetCode(
                email: testEmail,
                code: testCode,
              )).thenAnswer((_) async => false);
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: testEmail,
        ),
        act: (bloc) => bloc.add(ForgotPasswordCodeVerified(
          email: testEmail,
          code: testCode,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            errorMessage: '인증 코드가 유효하지 않습니다. 다시 확인해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '만료된 인증 코드로 검증 실패',
        build: () {
          when(() => mockAuthRepository.verifyPasswordResetCode(
                email: testEmail,
                code: testCode,
              )).thenThrow(Exception('인증 코드가 만료되었습니다.'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: testEmail,
        ),
        act: (bloc) => bloc.add(ForgotPasswordCodeVerified(
          email: testEmail,
          code: testCode,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '네트워크 에러 처리',
        build: () {
          when(() => mockAuthRepository.verifyPasswordResetCode(
                email: any(named: 'email'),
                code: any(named: 'code'),
              )).thenThrow(Exception('네트워크 연결 실패'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: testEmail,
        ),
        act: (bloc) => bloc.add(ForgotPasswordCodeVerified(
          email: testEmail,
          code: testCode,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '빈 인증 코드로 검증 시도',
        build: () {
          when(() => mockAuthRepository.verifyPasswordResetCode(
                email: testEmail,
                code: '',
              )).thenAnswer((_) async => false);
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          email: testEmail,
        ),
        act: (bloc) => bloc.add(ForgotPasswordCodeVerified(
          email: testEmail,
          code: '',
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.code,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            errorMessage: '인증 코드가 유효하지 않습니다. 다시 확인해주세요.',
          ),
        ],
      );
    });

    group('ForgotPasswordResetRequested', () {
      const testEmail = 'test@example.com';
      const testCode = '123456';
      const testNewPassword = 'NewPassword123!';

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '유효한 정보로 비밀번호 재설정 성공',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: testNewPassword,
              )).thenAnswer((_) async {});
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: testNewPassword,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.complete,
            status: ForgotPasswordStatus.success,
            email: testEmail,
            code: testCode,
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: testNewPassword,
              )).called(1);
        },
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '잘못된 인증 코드로 비밀번호 재설정 실패',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: testNewPassword,
              )).thenThrow(Exception('잘못된 인증 코드입니다.'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: testNewPassword,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            code: testCode,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '약한 비밀번호로 재설정 실패',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: '123',
              )).thenThrow(Exception('비밀번호가 너무 짧습니다.'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: '123',
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            code: testCode,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '네트워크 에러 처리',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: any(named: 'email'),
                code: any(named: 'code'),
                newPassword: any(named: 'newPassword'),
              )).thenThrow(Exception('네트워크 연결 실패'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: testNewPassword,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            code: testCode,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '빈 비밀번호로 재설정 시도',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: '',
              )).thenThrow(Exception('비밀번호를 입력해주세요.'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: '',
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            code: testCode,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '만료된 코드로 비밀번호 재설정 실패',
        build: () {
          when(() => mockAuthRepository.resetPasswordWithCode(
                email: testEmail,
                code: testCode,
                newPassword: testNewPassword,
              )).thenThrow(Exception('인증 코드가 만료되었습니다.'));
          return createBloc();
        },
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          email: testEmail,
          code: testCode,
        ),
        act: (bloc) => bloc.add(ForgotPasswordResetRequested(
          email: testEmail,
          code: testCode,
          newPassword: testNewPassword,
        )),
        expect: () => [
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.loading,
            email: testEmail,
            code: testCode,
          ),
          const ForgotPasswordState(
            step: ForgotPasswordStep.newPassword,
            status: ForgotPasswordStatus.failure,
            email: testEmail,
            code: testCode,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );
    });

    group('ForgotPasswordReset', () {
      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '상태를 초기화',
        build: () => createBloc(),
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.complete,
          status: ForgotPasswordStatus.success,
          email: 'test@example.com',
          code: '123456',
        ),
        act: (bloc) => bloc.add(ForgotPasswordReset()),
        expect: () => [
          const ForgotPasswordState(),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        '에러 상태를 초기화',
        build: () => createBloc(),
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.newPassword,
          status: ForgotPasswordStatus.failure,
          email: 'test@example.com',
          code: '123456',
          errorMessage: '에러 메시지',
        ),
        act: (bloc) => bloc.add(ForgotPasswordReset()),
        expect: () => [
          const ForgotPasswordState(),
        ],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'code 단계에서 초기화',
        build: () => createBloc(),
        seed: () => const ForgotPasswordState(
          step: ForgotPasswordStep.code,
          status: ForgotPasswordStatus.success,
          email: 'test@example.com',
        ),
        act: (bloc) => bloc.add(ForgotPasswordReset()),
        expect: () => [
          const ForgotPasswordState(),
        ],
      );
    });
  });
}
