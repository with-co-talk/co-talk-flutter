import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';

void main() {
  group('ServerException', () {
    test('creates exception with message and status code', () {
      const exception = ServerException(
        message: 'Server error',
        statusCode: 500,
      );

      expect(exception.message, 'Server error');
      expect(exception.statusCode, 500);
    });

    test('creates exception without status code', () {
      const exception = ServerException(message: 'Server error');

      expect(exception.message, 'Server error');
      expect(exception.statusCode, isNull);
    });

    test('toString returns formatted message', () {
      const exception = ServerException(
        message: 'Server error',
        statusCode: 500,
      );

      expect(exception.toString(), 'ServerException: Server error (status: 500)');
    });
  });

  group('CacheException', () {
    test('creates exception with message', () {
      const exception = CacheException(message: 'Cache error');

      expect(exception.message, 'Cache error');
    });

    test('toString returns formatted message', () {
      const exception = CacheException(message: 'Cache error');

      expect(exception.toString(), 'CacheException: Cache error');
    });
  });

  group('NetworkException', () {
    test('creates exception with message', () {
      const exception = NetworkException(message: 'No internet');

      expect(exception.message, 'No internet');
    });

    test('toString returns formatted message', () {
      const exception = NetworkException(message: 'No internet');

      expect(exception.toString(), 'NetworkException: No internet');
    });
  });

  group('AuthException', () {
    test('creates exception with message and type', () {
      const exception = AuthException(
        message: 'Invalid credentials',
        type: AuthErrorType.invalidCredentials,
      );

      expect(exception.message, 'Invalid credentials');
      expect(exception.type, AuthErrorType.invalidCredentials);
    });

    test('toString returns formatted message', () {
      const exception = AuthException(
        message: 'Token expired',
        type: AuthErrorType.tokenExpired,
      );

      expect(
        exception.toString(),
        'AuthException: Token expired (type: AuthErrorType.tokenExpired)',
      );
    });
  });

  group('AuthErrorType', () {
    test('has all expected values', () {
      expect(AuthErrorType.values.length, 6);
      expect(AuthErrorType.values, contains(AuthErrorType.invalidCredentials));
      expect(AuthErrorType.values, contains(AuthErrorType.tokenExpired));
      expect(AuthErrorType.values, contains(AuthErrorType.tokenInvalid));
      expect(AuthErrorType.values, contains(AuthErrorType.unauthorized));
      expect(AuthErrorType.values, contains(AuthErrorType.unknown));
      expect(AuthErrorType.values, contains(AuthErrorType.emailNotVerified));
    });
  });

  group('ValidationException', () {
    test('creates exception with message', () {
      const exception = ValidationException(message: 'Validation failed');

      expect(exception.message, 'Validation failed');
      expect(exception.fieldErrors, isNull);
    });

    test('creates exception with field errors', () {
      const exception = ValidationException(
        message: 'Validation failed',
        fieldErrors: {
          'email': 'Invalid email',
          'password': 'Too short',
        },
      );

      expect(exception.message, 'Validation failed');
      expect(exception.fieldErrors!['email'], 'Invalid email');
      expect(exception.fieldErrors!['password'], 'Too short');
    });

    test('toString returns formatted message', () {
      const exception = ValidationException(message: 'Validation failed');

      expect(exception.toString(), 'ValidationException: Validation failed');
    });
  });
}
