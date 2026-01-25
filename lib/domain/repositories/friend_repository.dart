import '../entities/friend.dart';
import '../entities/user.dart';

abstract class FriendRepository {
  Future<List<Friend>> getFriends();
  Future<void> sendFriendRequest(int receiverId);
  Future<void> acceptFriendRequest(int requestId);
  Future<void> rejectFriendRequest(int requestId);
  Future<void> removeFriend(int friendId);
  Future<List<User>> searchUsers(String query);
  Future<List<FriendRequest>> getReceivedFriendRequests();
  Future<List<FriendRequest>> getSentFriendRequests();
}
