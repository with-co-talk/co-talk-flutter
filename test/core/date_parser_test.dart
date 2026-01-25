import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/date_parser.dart';

void main() {
  group('DateParser', () {
    group('parse', () {
      test('parses ISO 8601 string correctly', () {
        const isoString = '2026-01-22T03:04:10.946596Z';
        final result = DateParser.parse(isoString);

        expect(result, isA<DateTime>());
        expect(result.year, 2026);
        expect(result.month, 1);
        expect(result.day, 22);
      });

      test('parses Java LocalDateTime array format correctly', () {
        // [year, month, day, hour, minute, second, nanosecond]
        final dateArray = [2026, 1, 22, 3, 4, 10, 946596000];
        final result = DateParser.parse(dateArray);

        expect(result, isA<DateTime>());
        expect(result.year, 2026);
        expect(result.month, 1);
        expect(result.day, 22);
        expect(result.hour, 3);
        expect(result.minute, 4);
        expect(result.second, 10);
        expect(result.millisecond, 946); // nanosecond / 1000000
        expect(result.microsecond, 596); // (nanosecond / 1000) % 1000
      });

      test('parses array without nanosecond', () {
        final dateArray = [2026, 1, 22, 3, 4, 10];
        final result = DateParser.parse(dateArray);

        expect(result, isA<DateTime>());
        expect(result.year, 2026);
        expect(result.month, 1);
        expect(result.day, 22);
        expect(result.microsecond, 0);
      });

      test('returns current time for null input', () {
        final before = DateTime.now();
        final result = DateParser.parse(null);
        final after = DateTime.now();

        expect(result, isA<DateTime>());
        expect(result.isAfter(before) || result.isAtSameMomentAs(before), true);
        expect(result.isBefore(after) || result.isAtSameMomentAs(after), true);
      });

      test('returns current time for invalid array (too short)', () {
        final dateArray = [2026, 1, 22]; // Only 3 elements
        final before = DateTime.now();
        final result = DateParser.parse(dateArray);
        final after = DateTime.now();

        expect(result, isA<DateTime>());
        expect(result.isAfter(before) || result.isAtSameMomentAs(before), true);
        expect(result.isBefore(after) || result.isAtSameMomentAs(after), true);
      });

      test('returns current time for invalid type', () {
        final before = DateTime.now();
        final result = DateParser.parse(12345);
        final after = DateTime.now();

        expect(result, isA<DateTime>());
        expect(result.isAfter(before) || result.isAtSameMomentAs(before), true);
        expect(result.isBefore(after) || result.isAtSameMomentAs(after), true);
      });

      test('handles invalid ISO 8601 string gracefully', () {
        const invalidString = 'not-a-date';
        final before = DateTime.now();
        final result = DateParser.parse(invalidString);
        final after = DateTime.now();

        expect(result, isA<DateTime>());
        expect(result.isAfter(before) || result.isAtSameMomentAs(before), true);
        expect(result.isBefore(after) || result.isAtSameMomentAs(after), true);
      });
    });

    group('isValidDateArray', () {
      test('returns true for valid date array', () {
        final dateArray = [2026, 1, 22, 3, 4, 10, 946596000];
        expect(DateParser.isValidDateArray(dateArray), true);
      });

      test('returns true for array without nanosecond', () {
        final dateArray = [2026, 1, 22, 3, 4, 10];
        expect(DateParser.isValidDateArray(dateArray), true);
      });

      test('returns false for array that is too short', () {
        final dateArray = [2026, 1, 22]; // Only 3 elements
        expect(DateParser.isValidDateArray(dateArray), false);
      });

      test('returns false for non-array', () {
        expect(DateParser.isValidDateArray('not-an-array'), false);
      });

      test('returns false for array with non-integer elements', () {
        final dateArray = [2026, 1, '22', 3, 4, 10];
        expect(DateParser.isValidDateArray(dateArray), false);
      });

      test('returns false for null', () {
        expect(DateParser.isValidDateArray(null), false);
      });
    });

    group('toIso8601String', () {
      test('converts DateTime to ISO 8601 string', () {
        final dateTime = DateTime(2026, 1, 22, 3, 4, 10, 946);
        final result = DateParser.toIso8601String(dateTime);

        expect(result, isA<String>());
        expect(result, contains('2026-01-22'));
        expect(result, contains('T'));
      });

      test('maintains UTC information', () {
        final dateTime = DateTime.utc(2026, 1, 22, 3, 4, 10);
        final result = DateParser.toIso8601String(dateTime);

        expect(result, endsWith('Z'));
      });
    });

    group('integration test', () {
      test('parses array and converts back to ISO string', () {
        final dateArray = [2026, 1, 22, 3, 4, 10, 946596000];
        final parsed = DateParser.parse(dateArray);
        final isoString = DateParser.toIso8601String(parsed);

        expect(isoString, isA<String>());
        expect(isoString, contains('2026-01-22'));
        // 시간 부분은 타임존에 따라 달라질 수 있으므로 날짜만 확인
      });

      test('round-trip ISO string parsing', () {
        const originalIso = '2026-01-22T03:04:10.946Z';
        final parsed = DateParser.parse(originalIso);
        final reconstructed = DateParser.toIso8601String(parsed);

        expect(reconstructed, contains('2026-01-22'));
        // 시간은 타임존에 따라 변환될 수 있으므로 날짜만 확인
      });
    });
  });
}
