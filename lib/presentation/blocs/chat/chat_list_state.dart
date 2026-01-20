import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_room.dart';

enum ChatListStatus { initial, loading, success, failure }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatRoom> chatRooms;
  final String? errorMessage;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.chatRooms = const [],
    this.errorMessage,
  });

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoom>? chatRooms,
    String? errorMessage,
  }) {
    return ChatListState(
      status: status ?? this.status,
      chatRooms: chatRooms ?? this.chatRooms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, chatRooms, errorMessage];
}
