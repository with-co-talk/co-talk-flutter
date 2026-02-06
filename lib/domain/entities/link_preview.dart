import 'package:equatable/equatable.dart';

/// 링크 미리보기 정보를 나타내는 엔티티.
/// URL에서 추출한 Open Graph 메타데이터를 담는다.
class LinkPreview extends Equatable {
  /// 원본 URL
  final String url;

  /// 페이지 제목
  final String? title;

  /// 페이지 설명
  final String? description;

  /// 대표 이미지 URL
  final String? imageUrl;

  /// 도메인명
  final String? domain;

  /// 사이트명
  final String? siteName;

  /// 파비콘 URL
  final String? favicon;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
    this.siteName,
    this.favicon,
  });

  /// 미리보기 정보가 유효한지 확인한다.
  /// 제목이나 이미지가 있으면 유효하다고 판단한다.
  bool get isValid => title != null || imageUrl != null;

  /// 빈 미리보기를 생성한다.
  factory LinkPreview.empty(String url) {
    return LinkPreview(url: url);
  }

  @override
  List<Object?> get props => [
        url,
        title,
        description,
        imageUrl,
        domain,
        siteName,
        favicon,
      ];
}
