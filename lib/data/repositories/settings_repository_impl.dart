import 'package:injectable/injectable.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/chat_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/remote/settings_remote_datasource.dart';
import '../datasources/local/chat_settings_local_datasource.dart';
import '../models/notification_settings_model.dart';
import '../models/chat_settings_model.dart';

/// 설정 관련 레포지토리 구현체
@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;
  final ChatSettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final model = await _remoteDataSource.getNotificationSettings();
    return model.toEntity();
  }

  @override
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    final model = NotificationSettingsModel.fromEntity(settings);
    await _remoteDataSource.updateNotificationSettings(model);
  }

  @override
  Future<ChatSettings> getChatSettings() async {
    final model = await _localDataSource.getChatSettings();
    return model.toEntity();
  }

  @override
  Future<void> saveChatSettings(ChatSettings settings) async {
    final model = ChatSettingsModel.fromEntity(settings);
    await _localDataSource.saveChatSettings(model);
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clearCache();
  }

  @override
  Future<void> deleteAccount(int userId, String password) async {
    await _remoteDataSource.deleteAccount(userId, password);
  }
}
