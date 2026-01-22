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

  const MessagesReadUpdated({
    required this.userId,
    this.lastReadMessageId,
  });

  @override
  List<Object?> get props => [userId, lastReadMessageId];
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
