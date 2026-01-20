import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';

abstract class FriendRemoteDataSource {
  Future<List<FriendModel>> getFriends(int userId);
  Future<void> sendFriendRequest(int requesterId, int receiverId);
  Future<void> acceptFriendRequest(int requestId, int userId);
  Future<void> rejectFriendRequest(int requestId, int userId);
  Future<void> removeFriend(int userId, int friendId);
  Future<List<UserModel>> searchUsers(String query);
}

@LazySingleton(as: FriendRemoteDataSource)
class FriendRemoteDataSourceImpl implements FriendRemoteDataSource {
  final DioClient _dioClient;

  FriendRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<FriendModel>> getFriends(int userId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.friends,
        queryParameters: {'userId': userId},
      );
      final data = response.data['friends'] as List;
      return data.map((json) => FriendModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> sendFriendRequest(int requesterId, int receiverId) async {
    try {
      await _dioClient.post(
        ApiConstants.friendRequests,
        data: SendFriendRequestRequest(
          requesterId: requesterId,
          receiverId: receiverId,
        ).toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> acceptFriendRequest(int requestId, int userId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.friendRequests}/$requestId/accept',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> rejectFriendRequest(int requestId, int userId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.friendRequests}/$requestId/reject',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> removeFriend(int userId, int friendId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.friends}/$friendId',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.userSearch,
        queryParameters: {'query': query},
      );
      final data = response.data['users'] as List? ?? response.data as List;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      return ServerException(
        message: e.response!.data?['message'] ?? 'Unknown error',
        statusCode: e.response!.statusCode,
      );
    }
    return const NetworkException(message: '네트워크 오류가 발생했습니다');
  }
}
