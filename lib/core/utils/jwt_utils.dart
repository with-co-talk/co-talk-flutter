import 'dart:convert';

/// JWT 관련 유틸리티.
///
/// 서버(백엔드)에서는 JWT subject(`sub`)에 userId를 문자열로 넣는다.
/// 예: JwtTokenProvider.createAccessToken(...) -> subject(userId.toString())
class JwtUtils {
  JwtUtils._();

  /// JWT의 payload(subject: `sub`)에서 userId를 추출합니다.
  ///
  /// - 형식이 올바르지 않거나, `sub`가 없거나, 숫자로 파싱할 수 없으면 null 반환
  static int? extractUserIdFromSubject(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      final payload = _decodeBase64UrlJson(parts[1]);
      final sub = payload['sub'];
      if (sub == null) return null;

      return int.tryParse(sub.toString());
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodeBase64UrlJson(String input) {
    final normalized = base64Url.normalize(input);
    final bytes = base64Url.decode(normalized);
    final jsonStr = utf8.decode(bytes);
    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw const FormatException('JWT payload is not a JSON object');
  }
}

