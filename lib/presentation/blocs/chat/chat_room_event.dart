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
