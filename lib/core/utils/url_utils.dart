// URL 감지 및 정규화 유틸.
//
// - "이게 URL이다" 구분: https?:// 또는 www.… / ….com 등 도메인 패턴을 정규식으로 매칭.
// - 도메인 패턴만 있는 경우(스킴 없음) 표시/클릭/API 호출 시 앞에 https://를 붙여 사용.

/// URL로 인식하는 정규식.
///
/// 매칭 대상:
/// 1. https?:// 로 시작하는 문자열
/// 2. www. 로 시작하는 문자열
/// 3. xxx.com / xxx.co.kr / xxx.net 등 도메인 패턴 (일반 TLD 포함)
final urlPattern = RegExp(
  r'(https?://[^\s<>\[\]{}|\\^`"]+)|'
  r'(www\.[^\s<>\[\]{}|\\^`"]+)|'
  r'([a-zA-Z0-9][\w.-]*\.(?:com|co\.kr|net|org|io|kr|info|biz|edu|gov|me|app|dev|co\.jp|jp|asia|tv|cc|co|uk|eu)[^\s<>\[\]{}|\\^`"]*)',
  caseSensitive: false,
);

/// 끝에 붙은 구두점 제거용 정규식
final _trailingPunctuation = RegExp(r'[.,;:!?)\]\}>]+$');

/// 매칭된 URL 문자열을 "진짜 URL"로 정규화한다.
///
/// - 끝의 구두점(.,;:!? 등) 제거
/// - http:// 또는 https:// 로 시작하지 않으면 앞에 https:// 를 붙인다.
///   예: www.naver.com → https://www.naver.com, naver.com → https://naver.com
String normalizeUrl(String raw) {
  final trimmed = raw.replaceAll(_trailingPunctuation, '').trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.toLowerCase().startsWith('http://') ||
      trimmed.toLowerCase().startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}
