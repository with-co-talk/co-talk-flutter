import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/find_email_bloc.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  FindEmailBloc createBloc() => FindEmailBloc(mockAuthRepository);

  group('FindEmailBloc', () {
    test('초기 상태는 FindEmailStatus.initial', () {
      final bloc = createBloc();
      expect(bloc.state.status, FindEmailStatus.initial);
      expect(bloc.state.maskedEmail, isNull);
      expect(bloc.state.message, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    group('FindEmailRequested', () {
      const testNickname = '테스트유저';
      const testPhoneNumber = '010-1234-5678';
      const testMaskedEmail = 'te***@example.com';
      const testMessage = '등록된 이메일을 찾았습니다.';

      blocTest<FindEmailBloc, FindEmailState>(
        '유효한 입력으로 이메일 찾기 성공',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: testPhoneNumber,
              )).thenAnswer((_) async => {
                'found': true,
                'maskedEmail': testMaskedEmail,
                'message': testMessage,
              });
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.success,
            maskedEmail: testMaskedEmail,
            message: testMessage,
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: testPhoneNumber,
              )).called(1);
        },
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '존재하지 않는 사용자로 실패',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: testPhoneNumber,
              )).thenAnswer((_) async => {
                'found': false,
                'message': '일치하는 사용자를 찾을 수 없습니다.',
              });
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.notFound,
            message: '일치하는 사용자를 찾을 수 없습니다.',
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: testPhoneNumber,
              )).called(1);
        },
      );

      blocTest<FindEmailBloc, FindEmailState>(
        'found가 false이고 message가 없을 때 기본 메시지 사용',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: testPhoneNumber,
              )).thenAnswer((_) async => {
                'found': false,
              });
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.notFound,
            message: '일치하는 계정을 찾을 수 없습니다.',
          ),
        ],
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '네트워크 에러 처리',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: any(named: 'nickname'),
                phoneNumber: any(named: 'phoneNumber'),
              )).thenThrow(Exception('네트워크 연결 실패'));
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '서버 에러 처리',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: any(named: 'nickname'),
                phoneNumber: any(named: 'phoneNumber'),
              )).thenThrow(Exception('서버 오류'));
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '빈 닉네임으로 요청 시 에러 처리',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: '',
                phoneNumber: testPhoneNumber,
              )).thenThrow(Exception('잘못된 요청입니다.'));
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: '',
          phoneNumber: testPhoneNumber,
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '빈 전화번호로 요청 시 에러 처리',
        build: () {
          when(() => mockAuthRepository.findEmail(
                nickname: testNickname,
                phoneNumber: '',
              )).thenThrow(Exception('잘못된 요청입니다.'));
          return createBloc();
        },
        act: (bloc) => bloc.add(FindEmailRequested(
          nickname: testNickname,
          phoneNumber: '',
        )),
        expect: () => [
          const FindEmailState(status: FindEmailStatus.loading),
          const FindEmailState(
            status: FindEmailStatus.failure,
            errorMessage: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ],
      );
    });

    group('FindEmailReset', () {
      blocTest<FindEmailBloc, FindEmailState>(
        '상태를 초기화',
        build: () => createBloc(),
        seed: () => const FindEmailState(
          status: FindEmailStatus.success,
          maskedEmail: 'te***@example.com',
          message: '이메일을 찾았습니다.',
        ),
        act: (bloc) => bloc.add(FindEmailReset()),
        expect: () => [
          const FindEmailState(),
        ],
      );

      blocTest<FindEmailBloc, FindEmailState>(
        '에러 상태를 초기화',
        build: () => createBloc(),
        seed: () => const FindEmailState(
          status: FindEmailStatus.failure,
          errorMessage: '에러 메시지',
        ),
        act: (bloc) => bloc.add(FindEmailReset()),
        expect: () => [
          const FindEmailState(),
        ],
      );
    });
  });
}
