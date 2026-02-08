import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../models/profile_history_model.dart';
import '../../models/user_model.dart';
import '../base_remote_datasource.dart';

abstract class ProfileRemoteDataSource {
  /// 사용자 프로필 조회
  Future<UserModel> getUserById(int userId);
  /// 프로필 이력 목록 조회
  Future<List<ProfileHistoryModel>> getProfileHistory(
    int userId, {
    String? type,
  });

  /// 프로필 이력 생성
  Future<ProfileHistoryModel> createProfileHistory({
    required int userId,
    required String type,
    String? url,
    String? content,
    bool isPrivate = false,
    bool setCurrent = true,
  });

  /// 프로필 이력 수정 (나만보기 토글)
  Future<void> updateProfileHistory(
    int userId,
    int historyId, {
    required bool isPrivate,
  });

  /// 프로필 이력 삭제
  Future<void> deleteProfileHistory(int userId, int historyId);

  /// 현재 프로필로 설정
  Future<void> setCurrentProfile(int userId, int historyId);
}

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl extends BaseRemoteDataSource
    implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<UserModel> getUserById(int userId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.userProfile(userId),
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<ProfileHistoryModel>> getProfileHistory(
    int userId, {
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) {
        queryParams['type'] = type;
      }

      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] GET ${ApiConstants.profileHistory(userId)}, params=$queryParams');
      }

      final response = await _dioClient.get(
        ApiConstants.profileHistory(userId),
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] Response: ${response.data}');
      }

      final List<dynamic> data = response.data['histories'] ?? response.data;
      return data
          .map((json) => ProfileHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] Error: $e');
      }
      throw handleDioError(e);
    }
  }

  @override
  Future<ProfileHistoryModel> createProfileHistory({
    required int userId,
    required String type,
    String? url,
    String? content,
    bool isPrivate = false,
    bool setCurrent = true,
  }) async {
    try {
      final requestData = {
        'type': type,
        if (url != null) 'url': url,
        if (content != null) 'content': content,
        'isPrivate': isPrivate,
        'setCurrent': setCurrent,
      };

      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] POST ${ApiConstants.profileHistory(userId)}, data=$requestData');
      }

      final response = await _dioClient.post(
        ApiConstants.profileHistory(userId),
        data: requestData,
      );

      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] Create response: ${response.data}');
      }

      return ProfileHistoryModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileRemoteDataSource] Create error: $e');
      }
      throw handleDioError(e);
    }
  }

  @override
  Future<void> updateProfileHistory(
    int userId,
    int historyId, {
    required bool isPrivate,
  }) async {
    try {
      await _dioClient.put(
        ApiConstants.profileHistoryItem(userId, historyId),
        data: {'isPrivate': isPrivate},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> deleteProfileHistory(int userId, int historyId) async {
    try {
      await _dioClient.delete(
        ApiConstants.profileHistoryItem(userId, historyId),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> setCurrentProfile(int userId, int historyId) async {
    try {
      await _dioClient.put(
        ApiConstants.profileHistoryCurrent(userId, historyId),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
