// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) =>
    ChatRoomModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      announcement: json['announcement'] as String?,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatRoomMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] == null
          ? null
          : MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'announcement': instance.announcement,
      'members': instance.members,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

ChatRoomMemberModel _$ChatRoomMemberModelFromJson(Map<String, dynamic> json) =>
    ChatRoomMemberModel(
      id: (json['id'] as num).toInt(),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isAdmin: json['isAdmin'] as bool?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$ChatRoomMemberModelToJson(
  ChatRoomMemberModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'isAdmin': instance.isAdmin,
  'joinedAt': instance.joinedAt.toIso8601String(),
};

CreateChatRoomRequest _$CreateChatRoomRequestFromJson(
  Map<String, dynamic> json,
) => CreateChatRoomRequest(
  userId1: (json['userId1'] as num).toInt(),
  userId2: (json['userId2'] as num).toInt(),
);

Map<String, dynamic> _$CreateChatRoomRequestToJson(
  CreateChatRoomRequest instance,
) => <String, dynamic>{
  'userId1': instance.userId1,
  'userId2': instance.userId2,
};

CreateGroupChatRoomRequest _$CreateGroupChatRoomRequestFromJson(
  Map<String, dynamic> json,
) => CreateGroupChatRoomRequest(
  name: json['name'] as String?,
  memberIds: (json['memberIds'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CreateGroupChatRoomRequestToJson(
  CreateGroupChatRoomRequest instance,
) => <String, dynamic>{'name': instance.name, 'memberIds': instance.memberIds};

ChatRoomsResponse _$ChatRoomsResponseFromJson(Map<String, dynamic> json) =>
    ChatRoomsResponse(
      chatRooms: (json['chatRooms'] as List<dynamic>)
          .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatRoomsResponseToJson(ChatRoomsResponse instance) =>
    <String, dynamic>{'chatRooms': instance.chatRooms};
