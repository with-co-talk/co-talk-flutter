import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_event.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_state.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
  });

  ChangePasswordBloc createBloc() => ChangePasswordBloc(mockSettingsRepository);

  group('ChangePasswordBloc', () {
    test('initial state is ChangePasswordState.initial', () {
      final bloc = createBloc();
      expect(bloc.state, const ChangePasswordState.initial());
    });

    group('ChangePasswordSubmitted', () {
      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'emits loading then success when password change succeeds',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'oldPassword123',
          newPassword: 'newPassword456',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.changePassword(
                'oldPassword123',
                'newPassword456',
              )).called(1);
        },
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'emits loading then error when password change fails',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenThrow(Exception('Invalid password'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'wrongPassword',
          newPassword: 'newPassword456',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          isA<ChangePasswordState>()
              .having((s) => s.status, 'status', ChangePasswordStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'emits specific error message for generic errors',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenThrow(Exception('알 수 없는 오류가 발생했습니다'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'oldPassword',
          newPassword: 'newPassword',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.error(
            '비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.',
          ),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'preserves specific error messages from ErrorMessageMapper',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenThrow(Exception('비밀번호가 일치하지 않습니다'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'wrongPassword',
          newPassword: 'newPassword456',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          isA<ChangePasswordState>()
              .having((s) => s.status, 'status', ChangePasswordStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'handles empty passwords',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: '',
          newPassword: '',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.changePassword('', '')).called(1);
        },
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'handles same current and new password',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'samePassword',
          newPassword: 'samePassword',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'handles multiple submit requests in sequence',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old1',
            newPassword: 'new1',
          ))
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old2',
            newPassword: 'new2',
          )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'handles network timeout errors',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenThrow(Exception('Timeout'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ChangePasswordSubmitted(
          currentPassword: 'oldPassword',
          newPassword: 'newPassword',
        )),
        expect: () => [
          const ChangePasswordState.loading(),
          isA<ChangePasswordState>()
              .having((s) => s.status, 'status', ChangePasswordStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ChangePasswordReset', () {
      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'resets to initial state from success',
        seed: () => const ChangePasswordState.success(),
        build: createBloc,
        act: (bloc) => bloc.add(const ChangePasswordReset()),
        expect: () => [
          const ChangePasswordState.initial(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'resets to initial state from error',
        seed: () => const ChangePasswordState.error('Some error'),
        build: createBloc,
        act: (bloc) => bloc.add(const ChangePasswordReset()),
        expect: () => [
          const ChangePasswordState.initial(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'resets to initial state from loading',
        seed: () => const ChangePasswordState.loading(),
        build: createBloc,
        act: (bloc) => bloc.add(const ChangePasswordReset()),
        expect: () => [
          const ChangePasswordState.initial(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'clears error message',
        seed: () => const ChangePasswordState.error('Error message'),
        build: createBloc,
        act: (bloc) => bloc.add(const ChangePasswordReset()),
        verify: (bloc) {
          expect(bloc.state.status, ChangePasswordStatus.initial);
          expect(bloc.state.errorMessage, isNull);
        },
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'handles multiple resets',
        seed: () => const ChangePasswordState.error('Error'),
        build: createBloc,
        act: (bloc) => bloc
          ..add(const ChangePasswordReset())
          ..add(const ChangePasswordReset()),
        // Only one state change because second reset doesn't change state
        expect: () => [
          const ChangePasswordState.initial(),
        ],
      );
    });

    group('State transitions', () {
      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'can submit again after success',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old1',
            newPassword: 'new1',
          ))
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old2',
            newPassword: 'new2',
          )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'can submit again after error',
        build: () {
          var callCount = 0;
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('First attempt failed');
            }
          });
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old',
            newPassword: 'new',
          ))
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old',
            newPassword: 'new',
          )),
        expect: () => [
          const ChangePasswordState.loading(),
          isA<ChangePasswordState>()
              .having((s) => s.status, 'status', ChangePasswordStatus.error),
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        'can reset and submit again',
        build: () {
          when(() => mockSettingsRepository.changePassword(any(), any()))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old1',
            newPassword: 'new1',
          ))
          ..add(const ChangePasswordReset())
          ..add(const ChangePasswordSubmitted(
            currentPassword: 'old2',
            newPassword: 'new2',
          )),
        expect: () => [
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
          const ChangePasswordState.initial(),
          const ChangePasswordState.loading(),
          const ChangePasswordState.success(),
        ],
      );
    });
  });
}
