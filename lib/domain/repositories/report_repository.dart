import '../entities/report.dart';

abstract class ReportRepository {
  Future<void> reportUser({
    required int reportedUserId,
    required ReportReason reason,
    String? description,
  });

  Future<void> reportMessage({
    required int reportedMessageId,
    required ReportReason reason,
    String? description,
  });

  Future<List<Report>> getMyReports();
}
