import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';
import 'package:co_talk_flutter/presentation/pages/profile/widgets/history_item_options_sheet.dart';

ProfileHistory makeHistory({
  int id = 1,
  bool isCurrent = false,
  bool isPrivate = false,
  String? url = 'https://example.com/img.jpg',
}) {
  return ProfileHistory(
    id: id,
    userId: 1,
    type: ProfileHistoryType.avatar,
    url: url,
    isCurrent: isCurrent,
    isPrivate: isPrivate,
    createdAt: DateTime(2024, 3, 15),
  );
}

Widget buildSheet({
  required ProfileHistory history,
  bool isMyProfile = true,
  VoidCallback? onSetCurrent,
  VoidCallback? onTogglePrivacy,
  VoidCallback? onDelete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: HistoryItemOptionsSheet(
        history: history,
        isMyProfile: isMyProfile,
        onSetCurrent: onSetCurrent,
        onTogglePrivacy: onTogglePrivacy,
        onDelete: onDelete,
      ),
    ),
  );
}

void main() {
  group('HistoryItemOptionsSheet', () {
    testWidgets('shows formatted date', (tester) async {
      final history = makeHistory();
      await tester.pumpWidget(buildSheet(history: history));

      expect(find.text('2024년 3월 15일'), findsOneWidget);
    });

    testWidgets('shows set current option when not current and isMyProfile', (tester) async {
      final history = makeHistory(isCurrent: false);
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: true));

      expect(find.text('현재 프로필로 설정'), findsOneWidget);
    });

    testWidgets('hides set current option when already current', (tester) async {
      final history = makeHistory(isCurrent: true);
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: true));

      expect(find.text('현재 프로필로 설정'), findsNothing);
    });

    testWidgets('shows privacy toggle as 나만보기 when not private', (tester) async {
      final history = makeHistory(isPrivate: false);
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: true));

      expect(find.text('나만보기'), findsOneWidget);
    });

    testWidgets('shows privacy toggle as 공개로 변경 when private', (tester) async {
      final history = makeHistory(isPrivate: true);
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: true));

      expect(find.text('공개로 변경'), findsOneWidget);
    });

    testWidgets('shows delete option when isMyProfile', (tester) async {
      final history = makeHistory();
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: true));

      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('hides all options when not my profile', (tester) async {
      final history = makeHistory();
      await tester.pumpWidget(buildSheet(history: history, isMyProfile: false));

      expect(find.text('현재 프로필로 설정'), findsNothing);
      expect(find.text('나만보기'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('calls onTogglePrivacy when privacy tile tapped', (tester) async {
      bool called = false;
      final history = makeHistory(isPrivate: false);
      await tester.pumpWidget(buildSheet(
        history: history,
        onTogglePrivacy: () => called = true,
      ));

      await tester.tap(find.text('나만보기'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onSetCurrent when set current tile tapped', (tester) async {
      bool called = false;
      final history = makeHistory(isCurrent: false);
      await tester.pumpWidget(buildSheet(
        history: history,
        onSetCurrent: () => called = true,
      ));

      await tester.tap(find.text('현재 프로필로 설정'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows delete confirmation dialog when delete tapped', (tester) async {
      final history = makeHistory(isCurrent: false);
      await tester.pumpWidget(buildSheet(history: history));

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('삭제 확인'), findsOneWidget);
      expect(find.text('이 이력을 삭제하시겠습니까?'), findsOneWidget);
    });

    testWidgets('shows current profile warning in delete dialog when isCurrent', (tester) async {
      final history = makeHistory(isCurrent: true);
      await tester.pumpWidget(buildSheet(history: history));

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.textContaining('현재 프로필로 사용 중입니다'), findsOneWidget);
    });

    testWidgets('calls onDelete when delete confirmed', (tester) async {
      bool deleted = false;
      final history = makeHistory(isCurrent: false);
      await tester.pumpWidget(buildSheet(
        history: history,
        onDelete: () => deleted = true,
      ));

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // tap the confirm delete button in the dialog
      final deleteButtons = find.text('삭제');
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('cancel in delete dialog does not call onDelete', (tester) async {
      bool deleted = false;
      final history = makeHistory(isCurrent: false);
      await tester.pumpWidget(buildSheet(
        history: history,
        onDelete: () => deleted = true,
      ));

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
    });
  });
}
