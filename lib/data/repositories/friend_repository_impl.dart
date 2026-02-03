import 'package:injectable/injectable.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/remote/friend_remote_datasource.dart';

@LazySingleton(as: FriendRepository)
class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDataSource _remoteDataSource;

  FriendRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Friend>> getFriends() async {
    final friendModels = await _remoteDataSource.getFriends();
    return friendModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> sendFriendRequest(int receiverId) async {
    await _remoteDataSource.sendFriendRequest(receiverId);
  }

  @override
  Future<void> acceptFriendRequest(int requestId) async {
    await _remoteDataSource.acceptFriendRequest(requestId);
  }

  @override
  Future<void> rejectFriendRequest(int requestId) async {
    await _remoteDataSource.rejectFriendRequest(requestId);
  }

  @override
  Future<void> removeFriend(int friendId) async {
    await _remoteDataSource.removeFriend(friendId);
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final userModels = await _remoteDataSource.searchUsers(query);
    return userModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FriendRequest>> getReceivedFriendRequests() async {
    final requestModels = await _remoteDataSource.getReceivedFriendRequests();
    return requestModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FriendRequest>> getSentFriendRequests() async {
    final requestModels = await _remoteDataSource.getSentFriendRequests();
    return requestModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> hideFriend(int friendId) async {
    await _remoteDataSource.hideFriend(friendId);
  }

  @override
  Future<void> unhideFriend(int friendId) async {
    await _remoteDataSource.unhideFriend(friendId);
  }

  @override
  Future<List<Friend>> getHiddenFriends() async {
    final friendModels = await _remoteDataSource.getHiddenFriends();
    return friendModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> blockUser(int userId) async {
    await _remoteDataSource.blockUser(userId);
  }

  @override
  Future<void> unblockUser(int userId) async {
    await _remoteDataSource.unblockUser(userId);
  }

  @override
  Future<List<User>> getBlockedUsers() async {
    final userModels = await _remoteDataSource.getBlockedUsers();
    return userModels.map((m) => m.toEntity()).toList();
  }
}
