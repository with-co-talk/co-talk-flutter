import 'package:equatable/equatable.dart';

enum ReportType { user, message }

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  fakeProfile,
  scam,
  hateSpeech,
  violence,
  other;

  String get apiValue {
    switch (this) {
      case ReportReason.spam: return 'SPAM';
      case ReportReason.harassment: return 'HARASSMENT';
      case ReportReason.inappropriateContent: return 'INAPPROPRIATE_CONTENT';
      case ReportReason.fakeProfile: return 'FAKE_PROFILE';
      case ReportReason.scam: return 'SCAM';
      case ReportReason.hateSpeech: return 'HATE_SPEECH';
      case ReportReason.violence: return 'VIOLENCE';
      case ReportReason.other: return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case ReportReason.spam: return '스팸';
      case ReportReason.harassment: return '괴롭힘';
      case ReportReason.inappropriateContent: return '부적절한 콘텐츠';
      case ReportReason.fakeProfile: return '허위 프로필';
      case ReportReason.scam: return '사기';
      case ReportReason.hateSpeech: return '혐오 발언';
      case ReportReason.violence: return '폭력';
      case ReportReason.other: return '기타';
    }
  }
}

enum ReportStatus { pending, reviewed, resolved, dismissed }

class Report extends Equatable {
  final int id;
  final ReportType type;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, reason, description, status, createdAt];
}
