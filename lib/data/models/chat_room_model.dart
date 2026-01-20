import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/chat_room.dart';
import 'message_model.dart';
import 'user_model.dart';

part 'chat_room_model.g.dart';

@JsonSerializable()
class ChatRoomModel {
  final int id;
  final String? name;
  final String? type;
  final String? announcement;
  final List<ChatRoomMemberModel>? members;
  final MessageModel? lastMessage;
  final int? unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatRoomModel({
    required this.id,
    this.name,
    this.type,
    this.announcement,
    this.members,
    this.lastMessage,
    this.unreadCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      name: name,
      type: _parseChatRoomType(type),
      announcement: announcement,
      members: members?.map((m) => m.toEntity()).toList() ?? [],
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCount ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ChatRoomType _parseChatRoomType(String? value) {
    switch (value?.toUpperCase()) {
      case 'GROUP':
        return ChatRoomType.group;
      default:
        return ChatRoomType.direct;
    }
  }
}

@JsonSerializable()
class ChatRoomMemberModel {
  final int id;
  final UserModel user;
  final bool? isAdmin;
  final DateTime joinedAt;

  const ChatRoomMemberModel({
    required this.id,
    required this.user,
    this.isAdmin,
    required this.joinedAt,
  });

  factory ChatRoomMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomMemberModelToJson(this);

  ChatRoomMember toEntity() {
    return ChatRoomMember(
      id: id,
      user: user.toEntity(),
      isAdmin: isAdmin ?? false,
      joinedAt: joinedAt,
    );
  }
}

@JsonSerializable()
class CreateChatRoomRequest {
  final int userId1;
  final int userId2;

  const CreateChatRoomRequest({
    required this.userId1,
    required this.userId2,
  });

  factory CreateChatRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateChatRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateChatRoomRequestToJson(this);
}

@JsonSerializable()
class CreateGroupChatRoomRequest {
  final String? name;
  final List<int> memberIds;

  const CreateGroupChatRoomRequest({
    this.name,
    required this.memberIds,
  });

  factory CreateGroupChatRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupChatRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGroupChatRoomRequestToJson(this);
}

@JsonSerializable()
class ChatRoomsResponse {
  final List<ChatRoomModel> chatRooms;

  const ChatRoomsResponse({required this.chatRooms});

  factory ChatRoomsResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomsResponseToJson(this);
}
