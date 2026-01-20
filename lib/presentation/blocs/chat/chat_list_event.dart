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
