import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('a h:mm', 'ko_KR').format(dateTime);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return '어제 ${DateFormat('a h:mm', 'ko_KR').format(dateTime)}';
    }

    if (dateTime.year == now.year) {
      return DateFormat('M월 d일', 'ko_KR').format(dateTime);
    }

    return DateFormat('yyyy년 M월 d일', 'ko_KR').format(dateTime);
  }

  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('a h:mm', 'ko_KR').format(dateTime);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return '어제';
    }

    final weekAgo = today.subtract(const Duration(days: 7));
    if (messageDate.isAfter(weekAgo)) {
      return DateFormat('EEEE', 'ko_KR').format(dateTime);
    }

    if (dateTime.year == now.year) {
      return DateFormat('M월 d일', 'ko_KR').format(dateTime);
    }

    return DateFormat('yyyy.M.d', 'ko_KR').format(dateTime);
  }

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(dateTime);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
