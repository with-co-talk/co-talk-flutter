import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomOpened extends ChatRoomEvent {
  final int roomId;

  const ChatRoomOpened(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class ChatRoomClosed extends ChatRoomEvent {
  const ChatRoomClosed();
}

/// 앱/창이 비활성화되어 채팅방을 "보고 있지 않음" 상태로 전환
class ChatRoomBackgrounded extends ChatRoomEvent {
  const ChatRoomBackgrounded();
}

/// 앱/창이 다시 활성화되어 채팅방을 "보고 있음" 상태로 전환
class ChatRoomForegrounded extends ChatRoomEvent {
  const ChatRoomForegrounded();
}

class MessagesLoadMoreRequested extends ChatRoomEvent {
  const MessagesLoadMoreRequested();
}

class MessageSent extends ChatRoomEvent {
  final String content;

  const MessageSent(this.content);

  @override
  List<Object?> get props => [content];
}

class MessageReceived extends ChatRoomEvent {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageDeleted extends ChatRoomEvent {
  final int messageId;

  const MessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// 읽음 상태 업데이트 이벤트
class MessagesReadUpdated extends ChatRoomEvent {
  final int userId;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;

  const MessagesReadUpdated({
    required this.userId,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  @override
  List<Object?> get props => [userId, lastReadMessageId, lastReadAt];
}

/// 타이핑 상태 변경 이벤트 (WebSocket 수신)
class TypingStatusChanged extends ChatRoomEvent {
  final int userId;
  final String? userNickname;
  final bool isTyping;

  const TypingStatusChanged({
    required this.userId,
    this.userNickname,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, userNickname, isTyping];
}

/// 사용자가 타이핑 시작 이벤트
class UserStartedTyping extends ChatRoomEvent {
  const UserStartedTyping();
}

/// 사용자가 타이핑 중단 이벤트
class UserStoppedTyping extends ChatRoomEvent {
  const UserStoppedTyping();
}
