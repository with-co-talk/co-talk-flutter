import 'package:equatable/equatable.dart';

enum ChatRoomType { direct, group }

class ChatRoom extends Equatable {
  final int id;
  final String? name;
  final ChatRoomType type;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  // 1:1 채팅방에서 상대방 정보 (그룹은 null)
  final int? otherUserId;
  final String? otherUserNickname;
  final String? otherUserAvatarUrl;

  const ChatRoom({
    required this.id,
    this.name,
    required this.type,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUserId,
    this.otherUserNickname,
    this.otherUserAvatarUrl,
  });

  /// 채팅방 표시 이름
  /// 1:1 채팅방: 상대방 닉네임
  /// 그룹 채팅방: 채팅방 이름
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (type == ChatRoomType.direct && otherUserNickname != null) {
      return otherUserNickname!;
    }
    return '채팅방';
  }

  ChatRoom copyWith({
    int? id,
    String? name,
    ChatRoomType? type,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    int? otherUserId,
    String? otherUserNickname,
    String? otherUserAvatarUrl,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserNickname: otherUserNickname ?? this.otherUserNickname,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        createdAt,
        lastMessage,
        lastMessageAt,
        unreadCount,
        otherUserId,
        otherUserNickname,
        otherUserAvatarUrl,
      ];
}

/// 채팅방 멤버 (멤버 목록 조회 API용)
class ChatRoomMember extends Equatable {
  final int userId;
  final String nickname;
  final String? avatarUrl;
  final ChatRoomMemberRole role;

  const ChatRoomMember({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.role = ChatRoomMemberRole.member,
  });

  bool get isAdmin => role == ChatRoomMemberRole.admin;

  @override
  List<Object?> get props => [userId, nickname, avatarUrl, role];
}

enum ChatRoomMemberRole { admin, member }
