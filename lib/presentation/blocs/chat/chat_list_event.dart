import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class ChatListLoadRequested extends ChatListEvent {
  const ChatListLoadRequested();
}

class ChatListRefreshRequested extends ChatListEvent {
  const ChatListRefreshRequested();
}

class ChatRoomCreated extends ChatListEvent {
  final int otherUserId;

  const ChatRoomCreated(this.otherUserId);

  @override
  List<Object?> get props => [otherUserId];
}

class GroupChatRoomCreated extends ChatListEvent {
  final String? name;
  final List<int> memberIds;

  const GroupChatRoomCreated({this.name, required this.memberIds});

  @override
  List<Object?> get props => [name, memberIds];
}

/// WebSocket을 통한 채팅방 업데이트 이벤트
class ChatRoomUpdated extends ChatListEvent {
  final int chatRoomId;
  final String? eventType; // NEW_MESSAGE, READ 등 (서버에서 전달)
  final String? lastMessage;
  final String? lastMessageType; // TEXT, IMAGE, FILE
  final DateTime? lastMessageAt;
  final int? unreadCount;
  final int? senderId; // 마지막 메시지 발신자 ID (내 메시지 제외 처리용)

  const ChatRoomUpdated({
    required this.chatRoomId,
    this.eventType,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount,
    this.senderId,
  });

  @override
  List<Object?> get props => [chatRoomId, eventType, lastMessage, lastMessageType, lastMessageAt, unreadCount, senderId];
}

/// WebSocket 구독 시작 이벤트
class ChatListSubscriptionStarted extends ChatListEvent {
  final int userId;

  const ChatListSubscriptionStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// WebSocket 구독 해제 이벤트
class ChatListSubscriptionStopped extends ChatListEvent {
  const ChatListSubscriptionStopped();
}

/// 채팅방 읽음 처리 완료 이벤트 (로컬)
class ChatRoomReadCompleted extends ChatListEvent {
  final int chatRoomId;

  const ChatRoomReadCompleted(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

/// 채팅방 진입 이벤트 (unreadCount 증가 방지용)
class ChatRoomEntered extends ChatListEvent {
  final int chatRoomId;

  const ChatRoomEntered(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

/// 채팅방 퇴장 이벤트
class ChatRoomExited extends ChatListEvent {
  const ChatRoomExited();
}

/// 로그아웃 시 모든 상태와 구독을 초기화하는 이벤트
class ChatListResetRequested extends ChatListEvent {
  const ChatListResetRequested();
}

/// 사용자 온라인 상태 변경 이벤트
class UserOnlineStatusChanged extends ChatListEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastActiveAt;

  const UserOnlineStatusChanged({
    required this.userId,
    required this.isOnline,
    this.lastActiveAt,
  });

  @override
  List<Object?> get props => [userId, isOnline, lastActiveAt];
}
