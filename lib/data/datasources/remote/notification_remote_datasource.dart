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
  /// [deviceType] 디바이스 타입 ('ANDROID' 또는 'IOS')
  Future<void> registerFcmToken({
    required String token,
    required String deviceType,
  });

  /// FCM 토큰 서버에서 삭제
  ///
  /// [token] 삭제할 FCM 토큰
  Future<void> unregisterFcmToken({required String token});
}

@LazySingleton(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl extends BaseRemoteDataSource
    implements NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSourceImpl(this._dioClient);

  @override
  Future<void> registerFcmToken({
    required String token,
    required String deviceType,
  }) async {
    try {
      await _dioClient.post(
        ApiConstants.fcmToken,
        data: {
          'token': token,
          'deviceType': deviceType,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> unregisterFcmToken({required String token}) async {
    try {
      await _dioClient.delete(
        ApiConstants.fcmToken,
        queryParameters: {'token': token},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
