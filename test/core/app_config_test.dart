import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('environment', () {
      test('environment is a non-empty string', () {
        expect(AppConfig.environment, isA<String>());
        expect(AppConfig.environment, isNotEmpty);
      });

      test('environment is one of valid values', () {
        expect(
          ['dev', 'staging', 'prod'].contains(AppConfig.environment),
          isTrue,
        );
      });
    });

    group('environment checks', () {
      test('isProduction returns true only when environment is prod', () {
        expect(AppConfig.isProduction, equals(AppConfig.environment == 'prod'));
      });

      test('isDevelopment returns true only when environment is dev', () {
        expect(AppConfig.isDevelopment, equals(AppConfig.environment == 'dev'));
      });

      test('isStaging returns true only when environment is staging', () {
        expect(AppConfig.isStaging, equals(AppConfig.environment == 'staging'));
      });

      test('only one environment flag can be true', () {
        final trueCount = [
          AppConfig.isProduction,
          AppConfig.isDevelopment,
          AppConfig.isStaging,
        ].where((v) => v).length;

        expect(trueCount, equals(1));
      });
    });

    group('debug mode', () {
      test('isDebugMode is a boolean', () {
        expect(AppConfig.isDebugMode, isA<bool>());
      });

      test('isDebugMode is false when isProduction is true', () {
        if (AppConfig.isProduction) {
          expect(AppConfig.isDebugMode, isFalse);
        }
      });
    });

    group('logging settings', () {
      test('enableVerboseLogging equals isDebugMode', () {
        expect(AppConfig.enableVerboseLogging, equals(AppConfig.isDebugMode));
      });

      test('enableNetworkBodyLogging equals isDebugMode', () {
        expect(AppConfig.enableNetworkBodyLogging, equals(AppConfig.isDebugMode));
      });
    });

    group('consistency', () {
      test('production environment disables verbose logging', () {
        if (AppConfig.isProduction) {
          expect(AppConfig.enableVerboseLogging, isFalse);
          expect(AppConfig.enableNetworkBodyLogging, isFalse);
        }
      });
    });
  });
}
