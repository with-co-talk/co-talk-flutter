import 'package:equatable/equatable.dart';
import 'message.dart';
import 'user.dart';

enum ChatRoomType { direct, group }

class ChatRoom extends Equatable {
  final int id;
  final String? name;
  final ChatRoomType type;
  final String? announcement;
  final List<ChatRoomMember> members;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatRoom({
    required this.id,
    this.name,
    required this.type,
    this.announcement,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (type == ChatRoomType.direct && members.isNotEmpty) {
      return members.first.user.nickname;
    }
    return members.map((m) => m.user.nickname).join(', ');
  }

  ChatRoom copyWith({
    int? id,
    String? name,
    ChatRoomType? type,
    String? announcement,
    List<ChatRoomMember>? members,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      announcement: announcement ?? this.announcement,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        announcement,
        members,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
      ];
}

class ChatRoomMember extends Equatable {
  final int id;
  final User user;
  final bool isAdmin;
  final DateTime joinedAt;

  const ChatRoomMember({
    required this.id,
    required this.user,
    this.isAdmin = false,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, user, isAdmin, joinedAt];
}
