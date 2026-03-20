import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/debug_logger.dart';

class TestLogger with DebugLogger {}

class CustomTagLogger with DebugLogger {
  @override
  String get logTag => 'CustomTag';
}

void main() {
  group('DebugLogger', () {
    test('logTag returns runtime type name', () {
      final logger = TestLogger();
      expect(logger.logTag, 'TestLogger');
    });

    test('logTag can be overridden', () {
      final logger = CustomTagLogger();
      expect(logger.logTag, 'CustomTag');
    });

    test('log calls debugPrint in debug mode', () {
      final logger = TestLogger();
      final logs = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      logger.log('test message');

      expect(logs, ['[TestLogger] test message']);

      // Restore
      debugPrint = debugPrintThrottled;
    });
  });
}
