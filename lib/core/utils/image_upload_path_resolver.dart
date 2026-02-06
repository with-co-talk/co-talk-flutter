/// 이미지 선택·크롭 후 업로드에 사용할 경로를 결정하는 유틸.
///
/// 프로필/채팅 등 사진 올리는 곳에서 공통 사용.
/// - 크롭 지원 플랫폼(Android/iOS): 크롭 완료 시 croppedPath, 취소 시 null
/// - 크롭 미지원(Web/데스크톱): pickedPath 그대로 사용
class ImageUploadPathResolver {
  ImageUploadPathResolver._();

  /// 선택·크롭 결과에 따라 업로드할 파일 경로를 반환한다.
  ///
  /// [pickedPath]: 선택한 원본 경로 (null/빈 문자열이면 null 반환)
  /// [croppedPath]: 크롭 결과 경로 (cropSupported일 때만 사용, null/빈 문자열이면 취소로 간주해 null 반환)
  /// [cropSupported]: 현재 플랫폼에서 크롭 지원 여부
  /// Returns: 업로드할 경로. null이면 업로드하지 않음(취소 등).
  static String? resolveUploadPath({
    required String? pickedPath,
    required String? croppedPath,
    required bool cropSupported,
  }) {
    if (pickedPath == null || pickedPath.isEmpty) return null;
    if (cropSupported) {
      if (croppedPath != null && croppedPath.isNotEmpty) return croppedPath;
      return null; // 크롭 취소
    }
    return pickedPath;
  }
}
