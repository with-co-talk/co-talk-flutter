import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/date_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  group('AppDateUtils', () {
    group('formatMessageTime', () {
      test('returns time only for today', () {
        final now = DateTime.now();
        final todayMessage = DateTime(now.year, now.month, now.day, 14, 30);

        final result = AppDateUtils.formatMessageTime(todayMessage);

        // 오후 2:30 형식
        expect(result, contains('2:30'));
      });

      test('returns "어제" prefix for yesterday', () {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0);

        final result = AppDateUtils.formatMessageTime(yesterday);

        expect(result, contains('어제'));
      });

      test('returns month and day for same year but not today/yesterday', () {
        final now = DateTime.now();
        final pastDate = DateTime(now.year, 1, 15, 10, 0);

        // 오늘이나 어제가 아닌 경우에만 테스트
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final pastDateOnly = DateTime(pastDate.year, pastDate.month, pastDate.day);

        if (pastDateOnly != today && pastDateOnly != yesterday) {
          final result = AppDateUtils.formatMessageTime(pastDate);
          expect(result, contains('1월 15일'));
        }
      });

      test('returns full year format for different year', () {
        final pastYear = DateTime(2023, 6, 15, 10, 0);

        final result = AppDateUtils.formatMessageTime(pastYear);

        expect(result, contains('2023년'));
        expect(result, contains('6월'));
        expect(result, contains('15일'));
      });
    });

    group('formatChatListTime', () {
      test('returns time only for today', () {
        final now = DateTime.now();
        final todayMessage = DateTime(now.year, now.month, now.day, 9, 15);

        final result = AppDateUtils.formatChatListTime(todayMessage);

        expect(result, contains('9:15'));
      });

      test('returns "어제" for yesterday', () {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0);

        final result = AppDateUtils.formatChatListTime(yesterday);

        expect(result, '어제');
      });

      test('returns weekday name for within a week', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        final result = AppDateUtils.formatChatListTime(threeDaysAgo);

        // 요일 이름 포함 확인 (월요일, 화요일 등)
        expect(result, anyOf([
          contains('월요일'),
          contains('화요일'),
          contains('수요일'),
          contains('목요일'),
          contains('금요일'),
          contains('토요일'),
          contains('일요일'),
        ]));
      });

      test('returns month and day for same year but more than a week ago', () {
        final now = DateTime.now();
        // 2주 전 날짜
        final twoWeeksAgo = DateTime(now.year, now.month, now.day - 14, 10, 0);

        final result = AppDateUtils.formatChatListTime(twoWeeksAgo);

        expect(result, contains('월'));
        expect(result, contains('일'));
      });

      test('returns year.month.day format for different year', () {
        final pastYear = DateTime(2023, 3, 20, 10, 0);

        final result = AppDateUtils.formatChatListTime(pastYear);

        expect(result, '2023.3.20');
      });
    });

    group('formatFullDate', () {
      test('returns full date with weekday', () {
        final date = DateTime(2024, 5, 15);

        final result = AppDateUtils.formatFullDate(date);

        expect(result, contains('2024년'));
        expect(result, contains('5월'));
        expect(result, contains('15일'));
        // 요일 포함
        expect(result, anyOf([
          contains('월요일'),
          contains('화요일'),
          contains('수요일'),
          contains('목요일'),
          contains('금요일'),
          contains('토요일'),
          contains('일요일'),
        ]));
      });
    });

    group('isSameDay', () {
      test('returns true for same day', () {
        final date1 = DateTime(2024, 5, 15, 10, 30);
        final date2 = DateTime(2024, 5, 15, 22, 45);

        expect(AppDateUtils.isSameDay(date1, date2), isTrue);
      });

      test('returns false for different days', () {
        final date1 = DateTime(2024, 5, 15, 23, 59);
        final date2 = DateTime(2024, 5, 16, 0, 0);

        expect(AppDateUtils.isSameDay(date1, date2), isFalse);
      });

      test('returns false for different months', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2024, 6, 15);

        expect(AppDateUtils.isSameDay(date1, date2), isFalse);
      });

      test('returns false for different years', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2023, 5, 15);

        expect(AppDateUtils.isSameDay(date1, date2), isFalse);
      });
    });
  });
}
