import 'package:injectable/injectable.dart';
import '../../domain/entities/profile_history.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote/profile_remote_datasource.dart';
import '../models/profile_history_model.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> getUserById(int userId) async {
    final model = await _remoteDataSource.getUserById(userId);
    return model.toEntity();
  }

  @override
  Future<List<ProfileHistory>> getProfileHistory(
    int userId, {
    ProfileHistoryType? type,
  }) async {
    final typeString = type != null ? ProfileHistoryModel.typeToString(type) : null;
    final models = await _remoteDataSource.getProfileHistory(
      userId,
      type: typeString,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ProfileHistory> createProfileHistory({
    required int userId,
    required ProfileHistoryType type,
    String? url,
    String? content,
    bool isPrivate = false,
    bool setCurrent = true,
  }) async {
    final model = await _remoteDataSource.createProfileHistory(
      userId: userId,
      type: ProfileHistoryModel.typeToString(type),
      url: url,
      content: content,
      isPrivate: isPrivate,
      setCurrent: setCurrent,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateProfileHistory(
    int userId,
    int historyId, {
    required bool isPrivate,
  }) async {
    await _remoteDataSource.updateProfileHistory(
      userId,
      historyId,
      isPrivate: isPrivate,
    );
  }

  @override
  Future<void> deleteProfileHistory(int userId, int historyId) async {
    await _remoteDataSource.deleteProfileHistory(userId, historyId);
  }

  @override
  Future<void> setCurrentProfile(int userId, int historyId) async {
    await _remoteDataSource.setCurrentProfile(userId, historyId);
  }
}
