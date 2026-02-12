import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/report.dart';
import 'package:co_talk_flutter/domain/repositories/report_repository.dart';
import 'package:co_talk_flutter/presentation/pages/report/report_page.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late MockReportRepository mockReportRepository;

  setUpAll(() {
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ReportRepository>()) {
      getIt.unregister<ReportRepository>();
    }
    getIt.registerSingleton<ReportRepository>(mockReportRepository);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidget({
    ReportType type = ReportType.user,
    int targetId = 1,
  }) {
    return MaterialApp(
      home: ReportPage(type: type, targetId: targetId),
    );
  }

  group('ReportPage', () {
    testWidgets('displays report reasons as radio buttons', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('스팸'), findsOneWidget);
      expect(find.text('괴롭힘'), findsOneWidget);
      expect(find.text('부적절한 콘텐츠'), findsOneWidget);
      expect(find.text('허위 프로필'), findsOneWidget);
      expect(find.text('사기'), findsOneWidget);
      expect(find.text('혐오 발언'), findsOneWidget);
      expect(find.text('폭력'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('shows correct title for user report', (tester) async {
      await tester.pumpWidget(createWidget(type: ReportType.user));

      expect(find.text('사용자 신고'), findsOneWidget);
    });

    testWidgets('shows correct title for message report', (tester) async {
      await tester.pumpWidget(createWidget(type: ReportType.message));

      expect(find.text('메시지 신고'), findsOneWidget);
    });

    testWidgets('submit button is disabled when no reason selected', (tester) async {
      await tester.pumpWidget(createWidget());

      final submitButton = find.widgetWithText(ElevatedButton, '신고하기');
      expect(submitButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(submitButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button is enabled after selecting a reason', (tester) async {
      await tester.pumpWidget(createWidget());

      // Select SPAM reason
      await tester.tap(find.text('스팸'));
      await tester.pump();

      final submitButton = find.widgetWithText(ElevatedButton, '신고하기');
      final button = tester.widget<ElevatedButton>(submitButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls reportUser on submit for user report', (tester) async {
      when(() => mockReportRepository.reportUser(
        reportedUserId: any(named: 'reportedUserId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(type: ReportType.user, targetId: 42));

      // Select reason
      await tester.tap(find.text('스팸'));
      await tester.pump();

      // Scroll to button
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pumpAndSettle();

      verify(() => mockReportRepository.reportUser(
        reportedUserId: 42,
        reason: ReportReason.spam,
        description: null,
      )).called(1);
    });

    testWidgets('calls reportMessage on submit for message report', (tester) async {
      when(() => mockReportRepository.reportMessage(
        reportedMessageId: any(named: 'reportedMessageId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(type: ReportType.message, targetId: 99));

      // Select reason
      await tester.tap(find.text('괴롭힘'));
      await tester.pump();

      // Scroll to button
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pumpAndSettle();

      verify(() => mockReportRepository.reportMessage(
        reportedMessageId: 99,
        reason: ReportReason.harassment,
        description: null,
      )).called(1);
    });

    testWidgets('includes description when provided', (tester) async {
      when(() => mockReportRepository.reportUser(
        reportedUserId: any(named: 'reportedUserId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(type: ReportType.user, targetId: 42));

      // Select reason
      await tester.tap(find.text('기타'));
      await tester.pump();

      // Enter description
      await tester.enterText(find.byType(TextField), '이 사용자가 문제가 있습니다');
      await tester.pump();

      // Scroll to button
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pumpAndSettle();

      verify(() => mockReportRepository.reportUser(
        reportedUserId: 42,
        reason: ReportReason.other,
        description: '이 사용자가 문제가 있습니다',
      )).called(1);
    });

    testWidgets('shows success message and closes page on successful report', (tester) async {
      when(() => mockReportRepository.reportUser(
        reportedUserId: any(named: 'reportedUserId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(type: ReportType.user, targetId: 42));

      // Select reason
      await tester.tap(find.text('스팸'));
      await tester.pump();

      // Scroll to button and submit
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump(); // Pump once to show SnackBar

      // Verify success message appears (before pumpAndSettle which closes the page)
      expect(find.text('신고가 접수되었습니다'), findsOneWidget);

      // Complete the animation
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message on failed report', (tester) async {
      when(() => mockReportRepository.reportUser(
        reportedUserId: any(named: 'reportedUserId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidget(type: ReportType.user, targetId: 42));

      // Select reason
      await tester.tap(find.text('스팸'));
      await tester.pump();

      // Scroll to button and submit
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.textContaining('신고 접수에 실패했습니다'), findsOneWidget);
    });

    testWidgets('processes submission correctly', (tester) async {
      when(() => mockReportRepository.reportUser(
        reportedUserId: any(named: 'reportedUserId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(type: ReportType.user, targetId: 42));

      // Select reason
      await tester.tap(find.text('스팸'));
      await tester.pump();

      // Scroll to button
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pump();

      // Verify button is enabled before submit
      var submitButton = find.widgetWithText(ElevatedButton, '신고하기');
      var button = tester.widget<ElevatedButton>(submitButton);
      expect(button.onPressed, isNotNull);

      // Tap submit button
      await tester.tap(submitButton);
      await tester.pump(); // Pump once to show SnackBar

      // Verify repository was called
      verify(() => mockReportRepository.reportUser(
        reportedUserId: 42,
        reason: ReportReason.spam,
        description: null,
      )).called(1);

      // Verify success message (before pumpAndSettle which closes the page)
      expect(find.text('신고가 접수되었습니다'), findsOneWidget);

      // Complete the animation
      await tester.pumpAndSettle();
    });
  });
}
