import '../entities/link_preview.dart';

/// 링크 미리보기 리포지토리 인터페이스.
/// URL에서 미리보기 정보를 조회하는 기능을 정의한다.
abstract class LinkPreviewRepository {
  /// URL에서 미리보기 정보를 조회한다.
  ///
  /// [url] 미리보기 정보를 조회할 URL
  /// 반환: 미리보기 정보, 실패 시 빈 미리보기 반환
  Future<LinkPreview> getLinkPreview(String url);
}
