import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/link_preview.dart';

part 'link_preview_model.g.dart';

/// 링크 미리보기 API 응답 모델.
@JsonSerializable()
class LinkPreviewModel {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? domain;
  final String? siteName;
  final String? favicon;

  const LinkPreviewModel({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
    this.siteName,
    this.favicon,
  });

  factory LinkPreviewModel.fromJson(Map<String, dynamic> json) =>
      _$LinkPreviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$LinkPreviewModelToJson(this);

  /// 엔티티로 변환한다.
  LinkPreview toEntity() {
    return LinkPreview(
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
      domain: domain,
      siteName: siteName,
      favicon: favicon,
    );
  }
}
