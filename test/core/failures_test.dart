import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/errors/failures.dart';

void main() {
  group('Failures', () {
    group('ServerFailure', () {
      test('creates instance with message and statusCode', () {
        const failure = ServerFailure(
          message: '서버 에러',
          statusCode: 500,
        );

        expect(failure.message, '서버 에러');
        expect(failure.statusCode, 500);
      });

      test('creates instance without statusCode', () {
        const failure = ServerFailure(message: '서버 에러');

        expect(failure.message, '서버 에러');
        expect(failure.statusCode, isNull);
      });

      test('props includes message and statusCode', () {
        const failure = ServerFailure(
          message: '서버 에러',
          statusCode: 500,
        );

        expect(failure.props, ['서버 에러', 500]);
      });

      test('two instances with same values are equal', () {
        const failure1 = ServerFailure(message: '에러', statusCode: 400);
        const failure2 = ServerFailure(message: '에러', statusCode: 400);

        expect(failure1, equals(failure2));
      });

      test('two instances with different values are not equal', () {
        const failure1 = ServerFailure(message: '에러1', statusCode: 400);
        const failure2 = ServerFailure(message: '에러2', statusCode: 400);

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('CacheFailure', () {
      test('creates instance with message', () {
        const failure = CacheFailure(message: '캐시 에러');

        expect(failure.message, '캐시 에러');
      });

      test('props includes message', () {
        const failure = CacheFailure(message: '캐시 에러');

        expect(failure.props, ['캐시 에러']);
      });
    });

    group('NetworkFailure', () {
      test('creates instance with message', () {
        const failure = NetworkFailure(message: '네트워크 에러');

        expect(failure.message, '네트워크 에러');
      });

      test('props includes message', () {
        const failure = NetworkFailure(message: '네트워크 에러');

        expect(failure.props, ['네트워크 에러']);
      });
    });

    group('AuthFailure', () {
      test('creates instance with message', () {
        const failure = AuthFailure(message: '인증 에러');

        expect(failure.message, '인증 에러');
      });

      test('props includes message', () {
        const failure = AuthFailure(message: '인증 에러');

        expect(failure.props, ['인증 에러']);
      });
    });

    group('ValidationFailure', () {
      test('creates instance with message and fieldErrors', () {
        const failure = ValidationFailure(
          message: '유효성 에러',
          fieldErrors: {'email': '이메일 형식이 아닙니다'},
        );

        expect(failure.message, '유효성 에러');
        expect(failure.fieldErrors, {'email': '이메일 형식이 아닙니다'});
      });

      test('creates instance without fieldErrors', () {
        const failure = ValidationFailure(message: '유효성 에러');

        expect(failure.message, '유효성 에러');
        expect(failure.fieldErrors, isNull);
      });

      test('props includes message and fieldErrors', () {
        const failure = ValidationFailure(
          message: '유효성 에러',
          fieldErrors: {'email': '오류'},
        );

        expect(failure.props, ['유효성 에러', {'email': '오류'}]);
      });

      test('two instances with same values are equal', () {
        const failure1 = ValidationFailure(
          message: '에러',
          fieldErrors: {'field': 'error'},
        );
        const failure2 = ValidationFailure(
          message: '에러',
          fieldErrors: {'field': 'error'},
        );

        expect(failure1, equals(failure2));
      });
    });
  });
}
