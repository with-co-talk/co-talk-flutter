import 'dart:io';

/// 파일 시그니처(매직 바이트)와 확장자로 MIME 타입을 결정합니다.
/// 서버의 "file signature does not match content type" 오류 방지를 위해
/// 확장자가 아닌 실제 바이트를 기준으로 판별합니다.
class FileMimeResolver {
  FileMimeResolver._();

  static const String _fallbackMime = 'application/octet-stream';

  /// 잘 알려진 파일 시그니처 (처음 몇 바이트 → MIME)
  static final List<_Signature> _signatures = [
    _Signature([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], 'image/png'),
    _Signature([0xFF, 0xD8, 0xFF], 'image/jpeg'),
    _Signature([0x47, 0x49, 0x46, 0x38, 0x37, 0x61], 'image/gif'),
    _Signature([0x47, 0x49, 0x46, 0x38, 0x39, 0x61], 'image/gif'),
    _Signature([0x25, 0x50, 0x44, 0x46], 'application/pdf'), // %PDF
  ];

  /// WebP는 RIFF 뒤에 WEBP가 옴
  static const List<int> _webpRiff = [0x52, 0x49, 0x46, 0x46];
  static const List<int> _webpWebp = [0x57, 0x45, 0x42, 0x50]; // WEBP at offset 8

  /// 확장자 → MIME (시그니처로 못 찾을 때만 사용)
  static const Map<String, String> _extensionMime = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heic',
    'pdf': 'application/pdf',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  /// [file]의 실제 내용(매직 바이트)을 읽어 MIME을 반환합니다.
  /// 시그니처 매칭 실패 시 확장자로 추정하고, 그래도 실패하면
  /// [application/octet-stream]을 반환합니다.
  static Future<String> resolveFromFile(File file) async {
    if (!await file.exists()) return _fallbackMime;
    final bytes = await file.readAsBytes();
    final head = bytes.length > 24 ? bytes.sublist(0, 24) : bytes;
    return resolveFromBytes(head, file.path);
  }

  /// [bytes]와 선택적 [path]로 MIME을 반환합니다.
  /// [path]가 있으면 확장자 폴백에 사용됩니다.
  static String resolveFromBytes(List<int> bytes, [String? path]) {
    if (bytes.isEmpty) return _extensionFallback(path) ?? _fallbackMime;

    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        _match(bytes, 0, _webpRiff) &&
        _match(bytes, 8, _webpWebp)) {
      return 'image/webp';
    }

    // ftyp 기반 파일 형식 검사 (offset 4에 'ftyp')
    if (bytes.length >= 12) {
      final ftyp = [0x66, 0x74, 0x79, 0x70]; // 'ftyp'
      if (_match(bytes, 4, ftyp)) {
        // offset 8에서 4바이트 brand 읽기
        final brand = bytes.sublist(8, 12);
        final brandStr = String.fromCharCodes(brand);

        // HEIC 브랜드 체크 (heic, heix, mif1, msf1)
        if (brandStr == 'heic' || brandStr == 'heix' ||
            brandStr == 'mif1' || brandStr == 'msf1') {
          return 'image/heic';
        }

        // 기타 ftyp 기반 파일은 video/mp4로 처리
        return 'video/mp4';
      }
    }

    for (final sig in _signatures) {
      if (bytes.length >= sig.pattern.length && _match(bytes, 0, sig.pattern)) {
        return sig.mime;
      }
    }

    return _extensionFallback(path) ?? _fallbackMime;
  }

  static bool _match(List<int> bytes, int offset, List<int> pattern) {
    if (offset + pattern.length > bytes.length) return false;
    for (var i = 0; i < pattern.length; i++) {
      if (bytes[offset + i] != pattern[i]) return false;
    }
    return true;
  }

  static String? _extensionFallback(String? path) {
    if (path == null || path.isEmpty) return null;
    final ext = path.split('.').last.toLowerCase();
    if (ext.isEmpty || ext == path) return null;
    return _extensionMime[ext];
  }
}

class _Signature {
  final List<int> pattern;
  final String mime;
  _Signature(this.pattern, this.mime);
}
