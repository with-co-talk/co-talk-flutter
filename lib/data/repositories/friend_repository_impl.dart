import 'package:injectable/injectable.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/friend_remote_datasource.dart';

@LazySingleton(as: FriendRepository)
class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;

  FriendRepositoryImpl(this._remoteDataSource, this._authLocalDataSource);

  Future<int> _getUserId() async {
    final userId = await _authLocalDataSource.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  @override
  Future<List<Friend>> getFriends() async {
    final userId = await _getUserId();
    final friendModels = await _remoteDataSource.getFriends(userId);
    return friendModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> sendFriendRequest(int receiverId) async {
    final userId = await _getUserId();
    await _remoteDataSource.sendFriendRequest(userId, receiverId);
  }

  @override
  Future<void> acceptFriendRequest(int requestId) async {
    final userId = await _getUserId();
    await _remoteDataSource.acceptFriendRequest(requestId, userId);
  }

  @override
  Future<void> rejectFriendRequest(int requestId) async {
    final userId = await _getUserId();
    await _remoteDataSource.rejectFriendRequest(requestId, userId);
  }

  @override
  Future<void> removeFriend(int friendId) async {
    final userId = await _getUserId();
    await _remoteDataSource.removeFriend(userId, friendId);
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final userModels = await _remoteDataSource.searchUsers(query);
    return userModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FriendRequest>> getReceivedFriendRequests() async {
    final userId = await _getUserId();
    final requestModels = await _remoteDataSource.getReceivedFriendRequests(userId);
    return requestModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FriendRequest>> getSentFriendRequests() async {
    final userId = await _getUserId();
    final requestModels = await _remoteDataSource.getSentFriendRequests(userId);
    return requestModels.map((m) => m.toEntity()).toList();
  }
}
