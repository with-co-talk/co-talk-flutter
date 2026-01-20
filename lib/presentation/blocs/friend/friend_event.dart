import 'package:equatable/equatable.dart';

abstract class FriendEvent extends Equatable {
  const FriendEvent();

  @override
  List<Object?> get props => [];
}

class FriendListLoadRequested extends FriendEvent {
  const FriendListLoadRequested();
}

class FriendRequestSent extends FriendEvent {
  final int receiverId;

  const FriendRequestSent(this.receiverId);

  @override
  List<Object?> get props => [receiverId];
}

class FriendRequestAccepted extends FriendEvent {
  final int requestId;

  const FriendRequestAccepted(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class FriendRequestRejected extends FriendEvent {
  final int requestId;

  const FriendRequestRejected(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class FriendRemoved extends FriendEvent {
  final int friendId;

  const FriendRemoved(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class UserSearchRequested extends FriendEvent {
  final String query;

  const UserSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}
