import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

enum ChatRoomStatus { initial, loading, success, failure }

class ChatRoomState extends Equatable {
  final ChatRoomStatus status;
  final int? roomId;
  final int? currentUserId;
  final List<Message> messages;
  final int? nextCursor;
  final bool hasMore;
  final bool isSending;
  final String? errorMessage;
  final Map<int, String> typingUsers; // userId -> nickname

  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.roomId,
    this.currentUserId,
    this.messages = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isSending = false,
    this.errorMessage,
    this.typingUsers = const {},
  });

  /// 누군가 타이핑 중인지 여부
  bool get isAnyoneTyping => typingUsers.isNotEmpty;

  /// 타이핑 인디케이터 텍스트
  String get typingIndicatorText {
    if (typingUsers.isEmpty) return '';
    if (typingUsers.length == 1) {
      return '${typingUsers.values.first}님이 입력 중...';
    }
    return '${typingUsers.length}명이 입력 중...';
  }

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    int? roomId,
    int? currentUserId,
    List<Message>? messages,
    int? nextCursor,
    bool? hasMore,
    bool? isSending,
    String? errorMessage,
    Map<int, String>? typingUsers,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      currentUserId: currentUserId ?? this.currentUserId,
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roomId,
        currentUserId,
        messages,
        nextCursor,
        hasMore,
        isSending,
        errorMessage,
        typingUsers,
      ];
}
