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

  // Hide friend functionality
  Future<void> hideFriend(int friendId);
  Future<void> unhideFriend(int friendId);
  Future<List<Friend>> getHiddenFriends();

  // Block functionality
  Future<void> blockUser(int userId);
  Future<void> unblockUser(int userId);
  Future<List<User>> getBlockedUsers();
}
