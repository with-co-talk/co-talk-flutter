import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_room.dart';

enum ChatListStatus { initial, loading, success, failure }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatRoom> chatRooms;
  final String? errorMessage;
  final int _cachedTotalUnreadCount;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.chatRooms = const [],
    this.errorMessage,
    int? cachedTotalUnreadCount,
  }) : _cachedTotalUnreadCount = cachedTotalUnreadCount ?? 0;

  /// 전체 읽지 않은 메시지 수 (캐싱됨)
  int get totalUnreadCount => _cachedTotalUnreadCount;

  /// chatRooms에서 totalUnreadCount 계산
  static int _calculateTotalUnread(List<ChatRoom> rooms) =>
      rooms.fold(0, (sum, room) => sum + room.unreadCount);

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoom>? chatRooms,
    String? errorMessage,
  }) {
    final newRooms = chatRooms ?? this.chatRooms;
    // chatRooms가 변경되면 totalUnreadCount 재계산
    final newTotalUnread = chatRooms != null
        ? _calculateTotalUnread(newRooms)
        : _cachedTotalUnreadCount;

    return ChatListState(
      status: status ?? this.status,
      chatRooms: newRooms,
      errorMessage: errorMessage ?? this.errorMessage,
      cachedTotalUnreadCount: newTotalUnread,
    );
  }

  @override
  List<Object?> get props => [status, chatRooms, errorMessage, _cachedTotalUnreadCount];
}
