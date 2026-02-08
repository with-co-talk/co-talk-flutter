import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';
import '../base_remote_datasource.dart';

abstract class FriendRemoteDataSource {
  Future<List<FriendModel>> getFriends();
  Future<void> sendFriendRequest(int receiverId);
  Future<void> acceptFriendRequest(int requestId);
  Future<void> rejectFriendRequest(int requestId);
  Future<void> removeFriend(int friendId);
  Future<List<UserModel>> searchUsers(String query);
  Future<List<FriendRequestModel>> getReceivedFriendRequests();
  Future<List<FriendRequestModel>> getSentFriendRequests();
  Future<void> hideFriend(int friendId);
  Future<void> unhideFriend(int friendId);
  Future<List<FriendModel>> getHiddenFriends();
  Future<void> blockUser(int userId);
  Future<void> unblockUser(int userId);
  Future<List<UserModel>> getBlockedUsers();
}

@LazySingleton(as: FriendRemoteDataSource)
class FriendRemoteDataSourceImpl extends BaseRemoteDataSource
    implements FriendRemoteDataSource {
  final DioClient _dioClient;

  FriendRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<FriendModel>> getFriends() async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      final response = await _dioClient.get(
        ApiConstants.friends,
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

            // lastActiveAt 파싱 (배열 또는 문자열)
            DateTime? lastActiveAt;
            final rawLastActiveAt = json['lastActiveAt'];
            if (rawLastActiveAt is List && rawLastActiveAt.length >= 6) {
              lastActiveAt = DateTime(
                rawLastActiveAt[0] as int,
                rawLastActiveAt[1] as int,
                rawLastActiveAt[2] as int,
                rawLastActiveAt[3] as int,
                rawLastActiveAt[4] as int,
                rawLastActiveAt[5] as int,
              );
            } else if (rawLastActiveAt is String) {
              lastActiveAt = DateTime.tryParse(rawLastActiveAt);
            }

            // user 객체 생성
            final userJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'nickname': json['nickname'] as String? ?? '',
              'email': json['email'] as String? ?? '',
              'avatarUrl': json['avatarUrl'],
              'onlineStatus': json['onlineStatus'],
              'lastActiveAt': lastActiveAt?.toIso8601String(),
            };

            // FriendModel을 위한 JSON 생성
            final friendJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'user': userJson,
              'createdAt': lastActiveAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'isHidden': json['isHidden'] ?? json['hidden'] ?? false,
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
  Future<void> sendFriendRequest(int receiverId) async {
    try {
      await _dioClient.post(
        ApiConstants.friendRequests,
        data: {'receiverId': receiverId},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> acceptFriendRequest(int requestId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.friendRequests}/$requestId/accept',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> rejectFriendRequest(int requestId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.friendRequests}/$requestId/reject',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> removeFriend(int friendId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.friends}/$friendId',
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
  Future<List<FriendRequestModel>> getReceivedFriendRequests() async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      final response = await _dioClient.get(
        '${ApiConstants.friendRequests}/received',
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
  Future<List<FriendRequestModel>> getSentFriendRequests() async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      final response = await _dioClient.get(
        '${ApiConstants.friendRequests}/sent',
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

  @override
  Future<void> hideFriend(int friendId) async {
    try {
      await _dioClient.post(
        ApiConstants.friendHide(friendId),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> unhideFriend(int friendId) async {
    try {
      await _dioClient.delete(
        ApiConstants.friendHide(friendId),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<FriendModel>> getHiddenFriends() async {
    try {
      final response = await _dioClient.get(
        ApiConstants.hiddenFriends,
      );

      final data = extractListFromResponse(response.data, 'friends');

      return data.map((json) {
        try {
          if (json is! Map<String, dynamic>) {
            throw FormatException('Expected Map<String, dynamic>, got ${json.runtimeType}');
          }

          // HiddenFriendDto 구조 처리: {"id": relationshipId, "friendId": actualUserId, "nickname": ..., "profileImageUrl": ..., "hiddenAt": ...}
          if (json.containsKey('friendId')) {
            // friendId가 실제 사용자 ID
            final friendUserId = json['friendId'] as int?;

            // hiddenAt 파싱 (배열 또는 문자열)
            DateTime? hiddenAt;
            final rawHiddenAt = json['hiddenAt'];
            if (rawHiddenAt is List && rawHiddenAt.length >= 6) {
              hiddenAt = DateTime(
                rawHiddenAt[0] as int,
                rawHiddenAt[1] as int,
                rawHiddenAt[2] as int,
                rawHiddenAt[3] as int,
                rawHiddenAt[4] as int,
                rawHiddenAt[5] as int,
              );
            } else if (rawHiddenAt is String) {
              hiddenAt = DateTime.tryParse(rawHiddenAt);
            }

            // user 객체 생성
            final userJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'nickname': json['nickname'] as String? ?? '',
              'email': json['email'] as String? ?? '',
              'avatarUrl': json['profileImageUrl'],
              'onlineStatus': 'OFFLINE',
              'lastActiveAt': null,
            };

            // FriendModel을 위한 JSON 생성
            final friendJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'user': userJson,
              'createdAt': hiddenAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'isHidden': true,
            };

            return FriendModel.fromJson(friendJson);
          }
          // 평면 구조인 경우 (nickname이 직접 있음) - 기존 로직 유지
          else if (json.containsKey('nickname') && !json.containsKey('user')) {
            final friendUserId = json['id'] as int?;

            // lastActiveAt 파싱 (배열 또는 문자열)
            DateTime? lastActiveAt;
            final rawLastActiveAt = json['lastActiveAt'];
            if (rawLastActiveAt is List && rawLastActiveAt.length >= 6) {
              lastActiveAt = DateTime(
                rawLastActiveAt[0] as int,
                rawLastActiveAt[1] as int,
                rawLastActiveAt[2] as int,
                rawLastActiveAt[3] as int,
                rawLastActiveAt[4] as int,
                rawLastActiveAt[5] as int,
              );
            } else if (rawLastActiveAt is String) {
              lastActiveAt = DateTime.tryParse(rawLastActiveAt);
            }

            // user 객체 생성
            final userJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'nickname': json['nickname'] as String? ?? '',
              'email': json['email'] as String? ?? '',
              'avatarUrl': json['avatarUrl'],
              'onlineStatus': json['onlineStatus'],
              'lastActiveAt': lastActiveAt?.toIso8601String(),
            };

            // FriendModel을 위한 JSON 생성
            final friendJson = <String, dynamic>{
              'id': friendUserId ?? 0,
              'user': userJson,
              'createdAt': lastActiveAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'isHidden': json['isHidden'] ?? true,
            };

            return FriendModel.fromJson(friendJson);
          } else {
            // 이미 중첩 구조인 경우 그대로 사용
            return FriendModel.fromJson(json);
          }
        } catch (e) {
          throw ServerException(
            message: '숨김 친구 목록 데이터 파싱 중 오류가 발생했습니다: ${e.toString()}. 데이터: $json',
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
        message: '숨김 친구 목록을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  @override
  Future<void> blockUser(int userId) async {
    try {
      await _dioClient.post(
        ApiConstants.blocks,
        data: {'blockedId': userId},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> unblockUser(int userId) async {
    try {
      await _dioClient.delete(
        ApiConstants.blockUser(userId),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<UserModel>> getBlockedUsers() async {
    try {
      final response = await _dioClient.get(
        ApiConstants.blocks,
      );

      final data = extractListFromResponse(response.data, 'blockedUsers');
      // Backend BlockedUserDto only returns id, nickname, avatarUrl (no email).
      // Manually construct UserModel to avoid fromJson crash on missing fields.
      return data.map((json) => UserModel(
        id: (json['id'] as num).toInt(),
        email: '',
        nickname: json['nickname'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      )).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '차단된 사용자 목록을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

}
