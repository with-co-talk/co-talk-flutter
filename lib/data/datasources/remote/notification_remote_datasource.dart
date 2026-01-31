import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../base_remote_datasource.dart';

/// FCM 토큰 서버 등록 인터페이스
abstract class NotificationRemoteDataSource {
  /// FCM 토큰 서버 등록
  ///
  /// [token] FCM 토큰
  /// [platform] 플랫폼 ('android' 또는 'ios')
  /// [deviceId] 고유 디바이스 식별자
  Future<void> registerFcmToken({
    required String token,
    required String platform,
    required String deviceId,
  });

  /// FCM 토큰 서버에서 삭제
  ///
  /// [deviceId] 삭제할 디바이스의 식별자
  Future<void> unregisterFcmToken({required String deviceId});
}

@LazySingleton(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl extends BaseRemoteDataSource
    implements NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSourceImpl(this._dioClient);

  @override
  Future<void> registerFcmToken({
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    try {
      await _dioClient.post(
        ApiConstants.fcmToken,
        data: {
          'token': token,
          'platform': platform,
          'deviceId': deviceId,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> unregisterFcmToken({required String deviceId}) async {
    try {
      await _dioClient.delete(
        ApiConstants.fcmToken,
        data: {'deviceId': deviceId},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
