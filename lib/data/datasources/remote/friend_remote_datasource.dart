import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';
import '../base_remote_datasource.dart';

abstract class FriendRemoteDataSource {
  Future<List<FriendModel>> getFriends(int userId);
  Future<void> sendFriendRequest(int requesterId, int receiverId);
  Future<void> acceptFriendRequest(int requestId, int userId);
  Future<void> rejectFriendRequest(int requestId, int userId);
  Future<void> removeFriend(int userId, int friendId);
  Future<List<UserModel>> searchUsers(String query);
  Future<List<FriendRequestModel>> getReceivedFriendRequests(int userId);
  Future<List<FriendRequestModel>> getSentFriendRequests(int userId);
}

@LazySingleton(as: FriendRemoteDataSource)
class FriendRemoteDataSourceImpl extends BaseRemoteDataSource
    implements FriendRemoteDataSource {
  final DioClient _dioClient;

  FriendRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<FriendModel>> getFriends(int userId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.friends,
        queryParameters: {'userId': userId},
      );

      // BaseRemoteDataSource의 extractListFromResponse 사용
      final data = extractListFromResponse(response.data, 'friends');

      return data.map((json) {
        try {
          if (json is! Map<String, dynamic>) {
            throw FormatException('Expected Map<String, dynamic>, got ${json.runtimeType}');
          }

          // API 스펙: 친구 목록은 평면 구조로 반환
          // 응답: {"id":..., "nickname":"...", "avatarUrl":..., "onlineStatus":"...", "lastActiveAt":"..."}
          // FriendModel 구조: {"id":..., "user": {...}, "createdAt":"..."}

          // 평면 구조인 경우 (nickname이 직접 있음)
          if (json.containsKey('nickname') && !json.containsKey('user')) {
            final friendUserId = json['id'] as int?;

            // user 객체 생성
            final userJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'nickname': json['nickname'] as String? ?? '',
              'email': '', // API 스펙에는 email이 없음
              'avatarUrl': json['avatarUrl'],
              'onlineStatus': json['onlineStatus'],
              'lastActiveAt': json['lastActiveAt'],
            };

            // FriendModel을 위한 JSON 생성
            final friendJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'user': userJson,
              'createdAt': json['lastActiveAt'] ?? DateTime.now().toIso8601String(),
            };

            return FriendModel.fromJson(friendJson);
          } else {
            // 이미 중첩 구조인 경우 그대로 사용
            return FriendModel.fromJson(json);
          }
        } catch (e) {
          throw ServerException(
            message: '친구 목록 데이터 파싱 중 오류가 발생했습니다: ${e.toString()}. 데이터: $json',
            statusCode: null,
          );
        }
      }).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '친구 목록을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
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
      throw handleDioError(e);
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
      throw handleDioError(e);
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
      throw handleDioError(e);
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
      throw handleDioError(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.userSearch,
        queryParameters: {'query': query},
      );

      // BaseRemoteDataSource의 extractListFromResponse 사용
      final data = extractListFromResponse(response.data, 'users');
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<FriendRequestModel>> getReceivedFriendRequests(int userId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.friendRequests}/received',
        queryParameters: {'userId': userId},
      );

      // API 스펙: 응답 키는 'requests'
      final data = extractListFromResponse(response.data, 'requests');

      return data.map((json) {
        try {
          if (json is! Map<String, dynamic>) {
            throw FormatException('Expected Map<String, dynamic>, got ${json.runtimeType}');
          }
          return FriendRequestModel.fromJson(json);
        } catch (e) {
          throw ServerException(
            message: '받은 친구 요청 데이터 파싱 중 오류가 발생했습니다: ${e.toString()}. 데이터: $json',
            statusCode: null,
          );
        }
      }).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '받은 친구 요청을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  @override
  Future<List<FriendRequestModel>> getSentFriendRequests(int userId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.friendRequests}/sent',
        queryParameters: {'userId': userId},
      );

      // API 스펙: 응답 키는 'requests'
      final data = extractListFromResponse(response.data, 'requests');

      return data.map((json) {
        try {
          if (json is! Map<String, dynamic>) {
            throw FormatException('Expected Map<String, dynamic>, got ${json.runtimeType}');
          }
          return FriendRequestModel.fromJson(json);
        } catch (e) {
          throw ServerException(
            message: '보낸 친구 요청 데이터 파싱 중 오류가 발생했습니다: ${e.toString()}. 데이터: $json',
            statusCode: null,
          );
        }
      }).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '보낸 친구 요청을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

}
