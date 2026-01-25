import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/exception_to_failure_mapper.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/core/errors/failures.dart';

void main() {
  group('ExceptionToFailureMapper', () {
    group('toFailure', () {
      test('converts ServerException to ServerFailure', () {
        final exception = const ServerException(
          message: '서버 에러',
          statusCode: 500,
        );

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<ServerFailure>());
        expect((result as ServerFailure).message, '서버 에러');
        expect(result.statusCode, 500);
      });

      test('converts NetworkException to NetworkFailure', () {
        final exception = const NetworkException(
          message: '네트워크 에러',
        );

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<NetworkFailure>());
        expect(result.message, '네트워크 에러');
      });

      test('converts CacheException to CacheFailure', () {
        final exception = const CacheException(
          message: '캐시 에러',
        );

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<CacheFailure>());
        expect(result.message, '캐시 에러');
      });

      test('converts AuthException to AuthFailure', () {
        final exception = const AuthException(
          message: '인증 에러',
          type: AuthErrorType.tokenExpired,
        );

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<AuthFailure>());
        expect(result.message, '인증 에러');
      });

      test('converts ValidationException to ValidationFailure', () {
        final exception = const ValidationException(
          message: '유효성 검사 에러',
          fieldErrors: {'email': '이메일 형식이 아닙니다'},
        );

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<ValidationFailure>());
        expect(result.message, '유효성 검사 에러');
        expect((result as ValidationFailure).fieldErrors, {'email': '이메일 형식이 아닙니다'});
      });

      test('converts unknown exception to ServerFailure with toString message', () {
        final exception = Exception('알 수 없는 에러');

        final result = ExceptionToFailureMapper.toFailure(exception);

        expect(result, isA<ServerFailure>());
        expect(result.message, contains('알 수 없는 에러'));
      });

      test('converts string to ServerFailure', () {
        final result = ExceptionToFailureMapper.toFailure('문자열 에러');

        expect(result, isA<ServerFailure>());
        expect(result.message, '문자열 에러');
      });
    });
  });
}
