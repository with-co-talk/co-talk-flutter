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

class ReceivedFriendRequestsLoadRequested extends FriendEvent {
  const ReceivedFriendRequestsLoadRequested();
}

class SentFriendRequestsLoadRequested extends FriendEvent {
  const SentFriendRequestsLoadRequested();
}

/// 친구 온라인 상태 변경 이벤트 (WebSocket)
class FriendOnlineStatusChanged extends FriendEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastActiveAt;

  const FriendOnlineStatusChanged({
    required this.userId,
    required this.isOnline,
    this.lastActiveAt,
  });

  @override
  List<Object?> get props => [userId, isOnline, lastActiveAt];
}

/// WebSocket 구독 시작 이벤트
class FriendListSubscriptionStarted extends FriendEvent {
  const FriendListSubscriptionStarted();
}

/// WebSocket 구독 해제 이벤트
class FriendListSubscriptionStopped extends FriendEvent {
  const FriendListSubscriptionStopped();
}

/// 친구 숨김 이벤트
class HideFriendRequested extends FriendEvent {
  final int friendId;

  const HideFriendRequested(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// 친구 숨김 해제 이벤트
class UnhideFriendRequested extends FriendEvent {
  final int friendId;

  const UnhideFriendRequested(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// 숨긴 친구 목록 로드 이벤트
class HiddenFriendsLoadRequested extends FriendEvent {
  const HiddenFriendsLoadRequested();
}

/// 사용자 차단 이벤트
class BlockUserRequested extends FriendEvent {
  final int userId;

  const BlockUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 사용자 차단 해제 이벤트
class UnblockUserRequested extends FriendEvent {
  final int userId;

  const UnblockUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 차단된 사용자 목록 로드 이벤트
class BlockedUsersLoadRequested extends FriendEvent {
  const BlockedUsersLoadRequested();
}

/// 친구 프로필 업데이트 이벤트 (WebSocket)
class FriendProfileUpdated extends FriendEvent {
  final int userId;
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? statusMessage;

  const FriendProfileUpdated({
    required this.userId,
    this.avatarUrl,
    this.backgroundUrl,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [userId, avatarUrl, backgroundUrl, statusMessage];
}
