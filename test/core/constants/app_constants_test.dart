import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    // Note: AppConstants._() is a private constructor intentionally preventing
    // instantiation. It cannot be called from test code (different library).
    // This single line remains uncovered by lcov by design - the class is a
    // pure static constants holder and is never meant to be instantiated.
    test('class is accessible via static members', () {
      // Verify the class can be used via its static interface
      expect(AppConstants.appName, isNotEmpty);
      expect(AppConstants.appVersion, isNotEmpty);
    });


    group('App Info', () {
      test('appName is Co-Talk', () {
        expect(AppConstants.appName, 'Co-Talk');
      });

      test('appVersion is 1.0.0', () {
        expect(AppConstants.appVersion, '1.0.0');
      });
    });

    group('Storage Keys', () {
      test('accessTokenKey is correct', () {
        expect(AppConstants.accessTokenKey, 'access_token');
      });

      test('refreshTokenKey is correct', () {
        expect(AppConstants.refreshTokenKey, 'refresh_token');
      });

      test('userIdKey is correct', () {
        expect(AppConstants.userIdKey, 'user_id');
      });

      test('userEmailKey is correct', () {
        expect(AppConstants.userEmailKey, 'user_email');
      });

      test('all storage keys are distinct', () {
        final keys = [
          AppConstants.accessTokenKey,
          AppConstants.refreshTokenKey,
          AppConstants.userIdKey,
          AppConstants.userEmailKey,
        ];
        expect(keys.toSet().length, keys.length);
      });
    });

    group('Pagination', () {
      test('defaultPageSize is 20', () {
        expect(AppConstants.defaultPageSize, 20);
      });

      test('messagePageSize is 50', () {
        expect(AppConstants.messagePageSize, 50);
      });

      test('messagePageSize is greater than defaultPageSize', () {
        expect(AppConstants.messagePageSize, greaterThan(AppConstants.defaultPageSize));
      });

      test('page sizes are positive', () {
        expect(AppConstants.defaultPageSize, greaterThan(0));
        expect(AppConstants.messagePageSize, greaterThan(0));
      });
    });

    group('Validation', () {
      test('minPasswordLength is 8', () {
        expect(AppConstants.minPasswordLength, 8);
      });

      test('maxPasswordLength is 100', () {
        expect(AppConstants.maxPasswordLength, 100);
      });

      test('maxPasswordLength is greater than minPasswordLength', () {
        expect(AppConstants.maxPasswordLength, greaterThan(AppConstants.minPasswordLength));
      });

      test('minNicknameLength is 2', () {
        expect(AppConstants.minNicknameLength, 2);
      });

      test('maxNicknameLength is 20', () {
        expect(AppConstants.maxNicknameLength, 20);
      });

      test('maxNicknameLength is greater than minNicknameLength', () {
        expect(AppConstants.maxNicknameLength, greaterThan(AppConstants.minNicknameLength));
      });

      test('password length bounds are positive', () {
        expect(AppConstants.minPasswordLength, greaterThan(0));
        expect(AppConstants.maxPasswordLength, greaterThan(0));
      });

      test('nickname length bounds are positive', () {
        expect(AppConstants.minNicknameLength, greaterThan(0));
        expect(AppConstants.maxNicknameLength, greaterThan(0));
      });
    });

    group('Chat', () {
      test('maxMessageLength is 2000', () {
        expect(AppConstants.maxMessageLength, 2000);
      });

      test('maxFileSize is 10MB (10 * 1024 * 1024 bytes)', () {
        expect(AppConstants.maxFileSize, 10 * 1024 * 1024);
      });

      test('maxFileSize is positive', () {
        expect(AppConstants.maxFileSize, greaterThan(0));
      });

      test('maxMessageLength is positive', () {
        expect(AppConstants.maxMessageLength, greaterThan(0));
      });
    });

    group('Desktop Window', () {
      test('minWindowWidth is 400', () {
        expect(AppConstants.minWindowWidth, 400.0);
      });

      test('minWindowHeight is 600', () {
        expect(AppConstants.minWindowHeight, 600.0);
      });

      test('defaultWindowWidth is 1200', () {
        expect(AppConstants.defaultWindowWidth, 1200.0);
      });

      test('defaultWindowHeight is 800', () {
        expect(AppConstants.defaultWindowHeight, 800.0);
      });

      test('defaultWindowWidth is greater than minWindowWidth', () {
        expect(AppConstants.defaultWindowWidth, greaterThan(AppConstants.minWindowWidth));
      });

      test('defaultWindowHeight is greater than minWindowHeight', () {
        expect(AppConstants.defaultWindowHeight, greaterThan(AppConstants.minWindowHeight));
      });

      test('window dimensions are positive', () {
        expect(AppConstants.minWindowWidth, greaterThan(0));
        expect(AppConstants.minWindowHeight, greaterThan(0));
        expect(AppConstants.defaultWindowWidth, greaterThan(0));
        expect(AppConstants.defaultWindowHeight, greaterThan(0));
      });
    });
  });
}
