import '../../domain/entities/report.dart';

class ReportModel {
  final int id;
  final String type;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? 'USER',
      reason: json['reason'] as String? ?? 'OTHER',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Report toEntity() {
    return Report(
      id: id,
      type: _parseReportType(type),
      reason: _parseReportReason(reason),
      description: description,
      status: _parseReportStatus(status),
      createdAt: createdAt,
    );
  }

  static ReportType _parseReportType(String value) {
    switch (value.toUpperCase()) {
      case 'MESSAGE': return ReportType.message;
      default: return ReportType.user;
    }
  }

  static ReportReason _parseReportReason(String value) {
    switch (value.toUpperCase()) {
      case 'SPAM': return ReportReason.spam;
      case 'HARASSMENT': return ReportReason.harassment;
      case 'INAPPROPRIATE_CONTENT': return ReportReason.inappropriateContent;
      case 'FAKE_PROFILE': return ReportReason.fakeProfile;
      case 'SCAM': return ReportReason.scam;
      case 'HATE_SPEECH': return ReportReason.hateSpeech;
      case 'VIOLENCE': return ReportReason.violence;
      default: return ReportReason.other;
    }
  }

  static ReportStatus _parseReportStatus(String value) {
    switch (value.toUpperCase()) {
      case 'REVIEWED': return ReportStatus.reviewed;
      case 'RESOLVED': return ReportStatus.resolved;
      case 'DISMISSED': return ReportStatus.dismissed;
      default: return ReportStatus.pending;
    }
  }
}
