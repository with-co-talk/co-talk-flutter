// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_preview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkPreviewModel _$LinkPreviewModelFromJson(Map<String, dynamic> json) =>
    LinkPreviewModel(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      domain: json['domain'] as String?,
      siteName: json['siteName'] as String?,
      favicon: json['favicon'] as String?,
    );

Map<String, dynamic> _$LinkPreviewModelToJson(LinkPreviewModel instance) =>
    <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'domain': instance.domain,
      'siteName': instance.siteName,
      'favicon': instance.favicon,
    };
