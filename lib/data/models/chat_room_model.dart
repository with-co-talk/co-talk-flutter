import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';
import '../../domain/entities/chat_room.dart';

part 'chat_room_model.g.dart';

/// 채팅방 목록 조회 API 응답 모델
@JsonSerializable()
class ChatRoomModel {
  final int id;
  final String? name;
  final String? type;
  @JsonKey(fromJson: DateParser.parse, toJson: _dateTimeToJson)
  final DateTime createdAt;
  final String? lastMessage;
  @JsonKey(fromJson: _parseNullableDateTime, toJson: _nullableDateTimeToJson)
  final DateTime? lastMessageAt;
  final int? unreadCount;
  // 1:1 채팅방에서 상대방 정보 (그룹은 null)
  final int? otherUserId;
  final String? otherUserNickname;
  final String? otherUserAvatarUrl;

  const ChatRoomModel({
    required this.id,
    this.name,
    this.type,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount,
    this.otherUserId,
    this.otherUserNickname,
    this.otherUserAvatarUrl,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      name: name,
      type: _parseChatRoomType(type),
      createdAt: createdAt,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? 0,
      otherUserId: otherUserId,
      otherUserNickname: otherUserNickname,
      otherUserAvatarUrl: otherUserAvatarUrl,
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

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return DateParser.parse(value);
  }

  static String _dateTimeToJson(DateTime value) => value.toIso8601String();

  static String? _nullableDateTimeToJson(DateTime? value) => value?.toIso8601String();
}

/// 채팅방 멤버 목록 조회 API 응답 모델
@JsonSerializable()
class ChatRoomMemberModel {
  final int userId;
  final String nickname;
  final String? avatarUrl;
  final String? role;

  const ChatRoomMemberModel({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.role,
  });

  factory ChatRoomMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomMemberModelToJson(this);

  ChatRoomMember toEntity() {
    return ChatRoomMember(
      userId: userId,
      nickname: nickname,
      avatarUrl: avatarUrl,
      role: _parseRole(role),
    );
  }

  static ChatRoomMemberRole _parseRole(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADMIN':
        return ChatRoomMemberRole.admin;
      default:
        return ChatRoomMemberRole.member;
    }
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
  // creatorId는 JWT 토큰에서 추출하므로 제거
  @JsonKey(name: 'roomName')
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
