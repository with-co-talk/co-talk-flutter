import 'package:equatable/equatable.dart';

enum ChatRoomType { direct, group, self }

class ChatRoom extends Equatable {
  final int id;
  final String? name;
  final ChatRoomType type;
  final DateTime createdAt;
  final String? lastMessage;
  final String? lastMessageType; // TEXT, IMAGE, FILE
  final DateTime? lastMessageAt;
  final int unreadCount;
  // 1:1 채팅방에서 상대방 정보 (그룹은 null)
  final int? otherUserId;
  final String? otherUserNickname;
  final String? otherUserAvatarUrl;
  // 상대방이 채팅방을 나갔는지 여부
  final bool isOtherUserLeft;
  // 상대방 온라인 상태
  final bool isOtherUserOnline;
  final DateTime? otherUserLastActiveAt;

  const ChatRoom({
    required this.id,
    this.name,
    required this.type,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUserId,
    this.otherUserNickname,
    this.otherUserAvatarUrl,
    this.isOtherUserLeft = false,
    this.isOtherUserOnline = false,
    this.otherUserLastActiveAt,
  });

  /// 채팅 목록에 표시할 마지막 메시지 미리보기 텍스트
  String get lastMessagePreview {
    if (lastMessage == null || lastMessage!.isEmpty) return '';

    switch (lastMessageType) {
      case 'IMAGE':
        return '사진을 보냈습니다';
      case 'FILE':
        return '파일을 보냈습니다';
      default:
        return lastMessage!;
    }
  }

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
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadCount,
    int? otherUserId,
    String? otherUserNickname,
    String? otherUserAvatarUrl,
    bool? isOtherUserLeft,
    bool? isOtherUserOnline,
    DateTime? otherUserLastActiveAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserNickname: otherUserNickname ?? this.otherUserNickname,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      isOtherUserLeft: isOtherUserLeft ?? this.isOtherUserLeft,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      otherUserLastActiveAt: otherUserLastActiveAt ?? this.otherUserLastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        createdAt,
        lastMessage,
        lastMessageType,
        lastMessageAt,
        unreadCount,
        otherUserId,
        otherUserNickname,
        otherUserAvatarUrl,
        isOtherUserLeft,
        isOtherUserOnline,
        otherUserLastActiveAt,
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
