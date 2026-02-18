import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/remote/report_remote_datasource.dart';
import 'package:co_talk_flutter/data/repositories/report_repository_impl.dart';
import 'package:co_talk_flutter/data/models/report_model.dart';
import 'package:co_talk_flutter/domain/entities/report.dart';

class MockReportRemoteDataSource extends Mock
    implements ReportRemoteDataSource {}

void main() {
  late MockReportRemoteDataSource mockRemoteDataSource;
  late ReportRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockReportRemoteDataSource();
    repository = ReportRepositoryImpl(mockRemoteDataSource);
  });

  group('ReportRepository', () {
    group('reportUser', () {
      test('reports user with required fields only', () async {
        when(() => mockRemoteDataSource.reportUser(
              reportedUserId: any(named: 'reportedUserId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenAnswer((_) async {});

        await repository.reportUser(
          reportedUserId: 123,
          reason: ReportReason.spam,
        );

        verify(() => mockRemoteDataSource.reportUser(
              reportedUserId: 123,
              reason: 'SPAM',
              description: null,
            )).called(1);
      });

      test('reports user with all fields including description', () async {
        when(() => mockRemoteDataSource.reportUser(
              reportedUserId: any(named: 'reportedUserId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenAnswer((_) async {});

        await repository.reportUser(
          reportedUserId: 456,
          reason: ReportReason.harassment,
          description: 'This user is sending abusive messages',
        );

        verify(() => mockRemoteDataSource.reportUser(
              reportedUserId: 456,
              reason: 'HARASSMENT',
              description: 'This user is sending abusive messages',
            )).called(1);
      });

      test('converts all ReportReason enum values correctly', () async {
        final testCases = {
          ReportReason.spam: 'SPAM',
          ReportReason.harassment: 'HARASSMENT',
          ReportReason.inappropriateContent: 'INAPPROPRIATE_CONTENT',
          ReportReason.fakeProfile: 'FAKE_PROFILE',
          ReportReason.scam: 'SCAM',
          ReportReason.hateSpeech: 'HATE_SPEECH',
          ReportReason.violence: 'VIOLENCE',
          ReportReason.other: 'OTHER',
        };

        for (final entry in testCases.entries) {
          when(() => mockRemoteDataSource.reportUser(
                reportedUserId: any(named: 'reportedUserId'),
                reason: any(named: 'reason'),
                description: any(named: 'description'),
              )).thenAnswer((_) async {});

          await repository.reportUser(
            reportedUserId: 1,
            reason: entry.key,
          );

          verify(() => mockRemoteDataSource.reportUser(
                reportedUserId: 1,
                reason: entry.value,
                description: null,
              )).called(1);
        }
      });

      test('throws exception when report fails', () async {
        when(() => mockRemoteDataSource.reportUser(
              reportedUserId: any(named: 'reportedUserId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenThrow(Exception('Report submission failed'));

        expect(
          () => repository.reportUser(
            reportedUserId: 123,
            reason: ReportReason.spam,
          ),
          throwsException,
        );
      });
    });

    group('reportMessage', () {
      test('reports message with required fields only', () async {
        when(() => mockRemoteDataSource.reportMessage(
              reportedMessageId: any(named: 'reportedMessageId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenAnswer((_) async {});

        await repository.reportMessage(
          reportedMessageId: 789,
          reason: ReportReason.inappropriateContent,
        );

        verify(() => mockRemoteDataSource.reportMessage(
              reportedMessageId: 789,
              reason: 'INAPPROPRIATE_CONTENT',
              description: null,
            )).called(1);
      });

      test('reports message with all fields including description', () async {
        when(() => mockRemoteDataSource.reportMessage(
              reportedMessageId: any(named: 'reportedMessageId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenAnswer((_) async {});

        await repository.reportMessage(
          reportedMessageId: 999,
          reason: ReportReason.hateSpeech,
          description: 'Contains hate speech against a group',
        );

        verify(() => mockRemoteDataSource.reportMessage(
              reportedMessageId: 999,
              reason: 'HATE_SPEECH',
              description: 'Contains hate speech against a group',
            )).called(1);
      });

      test('converts all ReportReason enum values correctly', () async {
        final testCases = {
          ReportReason.spam: 'SPAM',
          ReportReason.harassment: 'HARASSMENT',
          ReportReason.inappropriateContent: 'INAPPROPRIATE_CONTENT',
          ReportReason.fakeProfile: 'FAKE_PROFILE',
          ReportReason.scam: 'SCAM',
          ReportReason.hateSpeech: 'HATE_SPEECH',
          ReportReason.violence: 'VIOLENCE',
          ReportReason.other: 'OTHER',
        };

        for (final entry in testCases.entries) {
          when(() => mockRemoteDataSource.reportMessage(
                reportedMessageId: any(named: 'reportedMessageId'),
                reason: any(named: 'reason'),
                description: any(named: 'description'),
              )).thenAnswer((_) async {});

          await repository.reportMessage(
            reportedMessageId: 1,
            reason: entry.key,
          );

          verify(() => mockRemoteDataSource.reportMessage(
                reportedMessageId: 1,
                reason: entry.value,
                description: null,
              )).called(1);
        }
      });

      test('throws exception when report fails', () async {
        when(() => mockRemoteDataSource.reportMessage(
              reportedMessageId: any(named: 'reportedMessageId'),
              reason: any(named: 'reason'),
              description: any(named: 'description'),
            )).thenThrow(Exception('Message not found'));

        expect(
          () => repository.reportMessage(
            reportedMessageId: 999,
            reason: ReportReason.spam,
          ),
          throwsException,
        );
      });
    });

    group('getMyReports', () {
      final reportModels = [
        ReportModel(
          id: 1,
          type: 'USER',
          reason: 'SPAM',
          description: 'Spamming messages',
          status: 'PENDING',
          createdAt: DateTime(2024, 1, 1),
        ),
        ReportModel(
          id: 2,
          type: 'MESSAGE',
          reason: 'HARASSMENT',
          description: null,
          status: 'REVIEWED',
          createdAt: DateTime(2024, 1, 2),
        ),
        ReportModel(
          id: 3,
          type: 'USER',
          reason: 'FAKE_PROFILE',
          description: 'Impersonating another user',
          status: 'RESOLVED',
          createdAt: DateTime(2024, 1, 3),
        ),
      ];

      test('returns list of Report entities from remote datasource', () async {
        when(() => mockRemoteDataSource.getMyReports())
            .thenAnswer((_) async => reportModels);

        final result = await repository.getMyReports();

        expect(result, hasLength(3));
        expect(result[0].id, 1);
        expect(result[0].type, ReportType.user);
        expect(result[0].reason, ReportReason.spam);
        expect(result[0].status, ReportStatus.pending);
        expect(result[1].id, 2);
        expect(result[1].type, ReportType.message);
        expect(result[1].reason, ReportReason.harassment);
        expect(result[1].status, ReportStatus.reviewed);
        expect(result[2].id, 3);
        expect(result[2].status, ReportStatus.resolved);
        verify(() => mockRemoteDataSource.getMyReports()).called(1);
      });

      test('returns empty list when no reports exist', () async {
        when(() => mockRemoteDataSource.getMyReports())
            .thenAnswer((_) async => []);

        final result = await repository.getMyReports();

        expect(result, isEmpty);
        verify(() => mockRemoteDataSource.getMyReports()).called(1);
      });

      test('converts model entities correctly', () async {
        when(() => mockRemoteDataSource.getMyReports())
            .thenAnswer((_) async => [reportModels.first]);

        final result = await repository.getMyReports();

        expect(result[0], isA<Report>());
        expect(result[0].id, reportModels.first.id);
        expect(result[0].description, reportModels.first.description);
        expect(result[0].createdAt, reportModels.first.createdAt);
      });

      test('throws exception when fetching reports fails', () async {
        when(() => mockRemoteDataSource.getMyReports())
            .thenThrow(Exception('Network error'));

        expect(
          () => repository.getMyReports(),
          throwsException,
        );
      });
    });
  });
}
