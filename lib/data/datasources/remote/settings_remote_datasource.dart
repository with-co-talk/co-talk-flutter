import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../models/notification_settings_model.dart';
import '../base_remote_datasource.dart';

/// 설정 관련 원격 데이터소스 인터페이스
abstract class SettingsRemoteDataSource {
  /// 알림 설정 조회
  Future<NotificationSettingsModel> getNotificationSettings();

  /// 알림 설정 수정
  Future<void> updateNotificationSettings(NotificationSettingsModel settings);

  /// 회원 탈퇴
  Future<void> deleteAccount(int userId, String password);

  /// 비밀번호 변경
  Future<void> changePassword(String currentPassword, String newPassword);
}

/// 설정 관련 원격 데이터소스 구현체
@LazySingleton(as: SettingsRemoteDataSource)
class SettingsRemoteDataSourceImpl extends BaseRemoteDataSource
    implements SettingsRemoteDataSource {
  final DioClient _dioClient;

  SettingsRemoteDataSourceImpl(this._dioClient);

  @override
  Future<NotificationSettingsModel> getNotificationSettings() async {
    try {
      final response = await _dioClient.get(ApiConstants.notificationSettings);
      return NotificationSettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> updateNotificationSettings(NotificationSettingsModel settings) async {
    try {
      await _dioClient.put(
        ApiConstants.notificationSettings,
        data: settings.toJson(),
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> deleteAccount(int userId, String password) async {
    try {
      await _dioClient.delete(
        ApiConstants.accountDeletion,
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dioClient.put(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
