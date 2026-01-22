import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

enum ChatRoomStatus { initial, loading, success, failure }

class ChatRoomState extends Equatable {
  final ChatRoomStatus status;
  final int? roomId;
  final List<Message> messages;
  final int? nextCursor;
  final bool hasMore;
  final bool isSending;
  final String? errorMessage;

  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.roomId,
    this.messages = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isSending = false,
    this.errorMessage,
  });

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    int? roomId,
    List<Message>? messages,
    int? nextCursor,
    bool? hasMore,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roomId,
        messages,
        nextCursor,
        hasMore,
        isSending,
        errorMessage,
      ];
}
