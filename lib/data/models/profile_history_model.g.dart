// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileHistoryModel _$ProfileHistoryModelFromJson(Map<String, dynamic> json) =>
    ProfileHistoryModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      type: json['type'] as String,
      url: json['url'] as String?,
      content: json['content'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProfileHistoryModelToJson(
  ProfileHistoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'type': instance.type,
  'url': instance.url,
  'content': instance.content,
  'isPrivate': instance.isPrivate,
  'isCurrent': instance.isCurrent,
  'createdAt': instance.createdAt.toIso8601String(),
};
