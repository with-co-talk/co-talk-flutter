/// 서버에서 반환하는 다양한 날짜 형식을 DateTime으로 변환하는 유틸리티
class DateParser {
  DateParser._();

  /// 서버에서 반환하는 다양한 날짜 형식을 DateTime으로 변환
  ///
  /// 지원하는 형식:
  /// - ISO 8601 문자열: "2026-01-22T03:04:10.946596Z"
  /// - Java LocalDateTime 배열: [2026, 1, 22, 3, 4, 10, 946596000]
  /// - null: 현재 시간 반환
  ///
  /// [dateTime] 변환할 날짜 데이터
  /// Returns: 변환된 DateTime 객체
  static DateTime parse(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }

    // 이미 문자열인 경우
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }

    // 배열 형식인 경우: [year, month, day, hour, minute, second, nanosecond]
    // Java의 LocalDateTime.toArray()가 반환하는 형식
    if (dateTime is List && dateTime.length >= 6) {
      try {
        final year = dateTime[0] as int;
        final month = dateTime[1] as int;
        final day = dateTime[2] as int;
        final hour = dateTime[3] as int;
        final minute = dateTime[4] as int;
        final second = dateTime[5] as int;
        // nanosecond를 millisecond와 microsecond로 변환 (7번째 요소가 있는 경우)
        final nano = dateTime.length > 6 ? dateTime[6] as int : 0;
        final millisecond = nano ~/ 1000000;
        final microsecond = (nano ~/ 1000) % 1000;

        return DateTime(year, month, day, hour, minute, second, millisecond, microsecond);
      } catch (e) {
        return DateTime.now();
      }
    }

    // 그 외의 경우 현재 시간 사용
    return DateTime.now();
  }

  /// 날짜 배열이 유효한지 검증
  static bool isValidDateArray(dynamic dateTime) {
    if (dateTime is! List) return false;
    if (dateTime.length < 6) return false;

    try {
      for (int i = 0; i < 6; i++) {
        if (dateTime[i] is! int) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// DateTime을 ISO 8601 문자열로 변환
  static String toIso8601String(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
