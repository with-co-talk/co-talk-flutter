import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/error_message_mapper.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';

void main() {
  group('ErrorMessageMapper', () {
    group('toUserFriendlyMessage', () {
      group('AuthException', () {
        test('returns correct message for invalidCredentials', () {
          final exception = const AuthException(
            message: '',
            type: AuthErrorType.invalidCredentials,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '이메일 또는 비밀번호가 올바르지 않습니다');
        });

        test('returns correct message for tokenExpired', () {
          final exception = const AuthException(
            message: '',
            type: AuthErrorType.tokenExpired,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '세션이 만료되었습니다. 다시 로그인해주세요');
        });

        test('returns correct message for tokenInvalid', () {
          final exception = const AuthException(
            message: '',
            type: AuthErrorType.tokenInvalid,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '인증 정보가 유효하지 않습니다. 다시 로그인해주세요');
        });

        test('returns correct message for unauthorized', () {
          final exception = const AuthException(
            message: '',
            type: AuthErrorType.unauthorized,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '인증이 필요합니다. 다시 로그인해주세요');
        });

        test('returns custom message for unknown with message', () {
          final exception = const AuthException(
            message: '커스텀 에러 메시지',
            type: AuthErrorType.unknown,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '커스텀 에러 메시지');
        });

        test('returns default message for unknown without message', () {
          final exception = const AuthException(
            message: '',
            type: AuthErrorType.unknown,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '인증 중 오류가 발생했습니다');
        });
      });

      group('ServerException', () {
        test('returns server message if provided', () {
          final exception = const ServerException(
            message: '서버에서 보낸 에러',
            statusCode: 400,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버에서 보낸 에러');
        });

        test('returns correct message for 400', () {
          final exception = const ServerException(
            message: '',
            statusCode: 400,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '잘못된 요청입니다');
        });

        test('returns correct message for 401', () {
          final exception = const ServerException(
            message: '',
            statusCode: 401,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '인증이 필요합니다');
        });

        test('returns correct message for 403', () {
          final exception = const ServerException(
            message: '',
            statusCode: 403,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '권한이 없습니다');
        });

        test('returns correct message for 404', () {
          final exception = const ServerException(
            message: '',
            statusCode: 404,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '요청한 리소스를 찾을 수 없습니다');
        });

        test('returns correct message for 500', () {
          final exception = const ServerException(
            message: '',
            statusCode: 500,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요');
        });

        test('returns correct message for 502', () {
          final exception = const ServerException(
            message: '',
            statusCode: 502,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요');
        });

        test('returns correct message for 503', () {
          final exception = const ServerException(
            message: '',
            statusCode: 503,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요');
        });

        test('returns default message for other status codes', () {
          final exception = const ServerException(
            message: '',
            statusCode: 418,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버 오류가 발생했습니다');
        });

        test('returns default message when statusCode is null', () {
          final exception = const ServerException(message: '');

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '서버 오류가 발생했습니다');
        });

        test('ignores "Unknown error" message', () {
          final exception = const ServerException(
            message: 'Unknown error',
            statusCode: 404,
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '요청한 리소스를 찾을 수 없습니다');
        });
      });

      group('NetworkException', () {
        test('returns exception message', () {
          final exception = const NetworkException(
            message: '네트워크 연결이 불안정합니다',
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '네트워크 연결이 불안정합니다');
        });
      });

      group('CacheException', () {
        test('returns cache error message', () {
          final exception = const CacheException(
            message: '캐시 에러',
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '데이터를 불러오는 중 오류가 발생했습니다');
        });
      });

      group('ValidationException', () {
        test('returns exception message', () {
          final exception = const ValidationException(
            message: '입력값이 올바르지 않습니다',
          );

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '입력값이 올바르지 않습니다');
        });
      });

      group('Unknown exception', () {
        test('returns default message for unknown exception type', () {
          final exception = Exception('Unknown');

          final result = ErrorMessageMapper.toUserFriendlyMessage(exception);

          expect(result, '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        });

        test('returns default message for string error', () {
          final result = ErrorMessageMapper.toUserFriendlyMessage('string error');

          expect(result, '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        });
      });
    });
  });
}
