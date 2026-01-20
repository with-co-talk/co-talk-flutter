// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendModel _$FriendModelFromJson(Map<String, dynamic> json) => FriendModel(
  id: (json['id'] as num).toInt(),
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$FriendModelToJson(FriendModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'createdAt': instance.createdAt.toIso8601String(),
    };

FriendRequestModel _$FriendRequestModelFromJson(Map<String, dynamic> json) =>
    FriendRequestModel(
      id: (json['id'] as num).toInt(),
      requester: UserModel.fromJson(json['requester'] as Map<String, dynamic>),
      receiver: UserModel.fromJson(json['receiver'] as Map<String, dynamic>),
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FriendRequestModelToJson(FriendRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester': instance.requester,
      'receiver': instance.receiver,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };

SendFriendRequestRequest _$SendFriendRequestRequestFromJson(
  Map<String, dynamic> json,
) => SendFriendRequestRequest(
  requesterId: (json['requesterId'] as num).toInt(),
  receiverId: (json['receiverId'] as num).toInt(),
);

Map<String, dynamic> _$SendFriendRequestRequestToJson(
  SendFriendRequestRequest instance,
) => <String, dynamic>{
  'requesterId': instance.requesterId,
  'receiverId': instance.receiverId,
};

FriendListResponse _$FriendListResponseFromJson(Map<String, dynamic> json) =>
    FriendListResponse(
      friends: (json['friends'] as List<dynamic>)
          .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FriendListResponseToJson(FriendListResponse instance) =>
    <String, dynamic>{'friends': instance.friends};
