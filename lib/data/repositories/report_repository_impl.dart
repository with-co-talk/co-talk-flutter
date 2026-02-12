import 'package:injectable/injectable.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/remote/report_remote_datasource.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> reportUser({
    required int reportedUserId,
    required ReportReason reason,
    String? description,
  }) async {
    await _remoteDataSource.reportUser(
      reportedUserId: reportedUserId,
      reason: reason.apiValue,
      description: description,
    );
  }

  @override
  Future<void> reportMessage({
    required int reportedMessageId,
    required ReportReason reason,
    String? description,
  }) async {
    await _remoteDataSource.reportMessage(
      reportedMessageId: reportedMessageId,
      reason: reason.apiValue,
      description: description,
    );
  }

  @override
  Future<List<Report>> getMyReports() async {
    final models = await _remoteDataSource.getMyReports();
    return models.map((m) => m.toEntity()).toList();
  }
}
