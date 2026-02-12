// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) =>
    ChatRoomModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String?,
      createdAt: DateParser.parse(json['createdAt']),
      lastMessage: json['lastMessage'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      lastMessageAt: ChatRoomModel._parseNullableDateTime(
        json['lastMessageAt'],
      ),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      otherUserId: (json['otherUserId'] as num?)?.toInt(),
      otherUserNickname: json['otherUserNickname'] as String?,
      otherUserAvatarUrl: json['otherUserAvatarUrl'] as String?,
      isOtherUserLeft: json['isOtherUserLeft'] as bool?,
      isOtherUserOnline: json['isOtherUserOnline'] as bool?,
      otherUserLastActiveAt: ChatRoomModel._parseNullableDateTime(
        json['otherUserLastActiveAt'],
      ),
    );

Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'type': instance.type,
      'createdAt': ChatRoomModel._dateTimeToJson(instance.createdAt),
      'lastMessage': instance.lastMessage,
      'lastMessageType': instance.lastMessageType,
      'lastMessageAt': ChatRoomModel._nullableDateTimeToJson(
        instance.lastMessageAt,
      ),
      'unreadCount': instance.unreadCount,
      'otherUserId': instance.otherUserId,
      'otherUserNickname': instance.otherUserNickname,
      'otherUserAvatarUrl': instance.otherUserAvatarUrl,
      'isOtherUserLeft': instance.isOtherUserLeft,
      'isOtherUserOnline': instance.isOtherUserOnline,
      'otherUserLastActiveAt': ChatRoomModel._nullableDateTimeToJson(
        instance.otherUserLastActiveAt,
      ),
    };

ChatRoomMemberModel _$ChatRoomMemberModelFromJson(Map<String, dynamic> json) =>
    ChatRoomMemberModel(
      userId: (json['userId'] as num).toInt(),
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$ChatRoomMemberModelToJson(
  ChatRoomMemberModel instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'nickname': instance.nickname,
  'avatarUrl': instance.avatarUrl,
  'role': instance.role,
};

CreateChatRoomRequest _$CreateChatRoomRequestFromJson(
  Map<String, dynamic> json,
) => CreateChatRoomRequest(userId2: (json['userId2'] as num).toInt());

Map<String, dynamic> _$CreateChatRoomRequestToJson(
  CreateChatRoomRequest instance,
) => <String, dynamic>{'userId2': instance.userId2};

CreateGroupChatRoomRequest _$CreateGroupChatRoomRequestFromJson(
  Map<String, dynamic> json,
) => CreateGroupChatRoomRequest(
  name: json['roomName'] as String?,
  memberIds: (json['memberIds'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CreateGroupChatRoomRequestToJson(
  CreateGroupChatRoomRequest instance,
) => <String, dynamic>{
  'roomName': instance.name,
  'memberIds': instance.memberIds,
};
