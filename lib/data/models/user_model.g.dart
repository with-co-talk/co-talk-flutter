// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  nickname: json['nickname'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  status: json['status'] as String?,
  role: json['role'] as String?,
  onlineStatus: json['onlineStatus'] as String?,
  lastActiveAt: json['lastActiveAt'] == null
      ? null
      : DateTime.parse(json['lastActiveAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'nickname': instance.nickname,
  'avatarUrl': instance.avatarUrl,
  'status': instance.status,
  'role': instance.role,
  'onlineStatus': instance.onlineStatus,
  'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};
