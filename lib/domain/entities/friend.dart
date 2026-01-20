import 'package:equatable/equatable.dart';
import 'user.dart';

class Friend extends Equatable {
  final int id;
  final User user;
  final DateTime createdAt;

  const Friend({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, user, createdAt];
}

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest extends Equatable {
  final int id;
  final User requester;
  final User receiver;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.requester,
    required this.receiver,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, requester, receiver, status, createdAt];
}
