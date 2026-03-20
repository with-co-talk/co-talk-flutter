import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_event.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_state.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';
import 'package:co_talk_flutter/presentation/pages/profile/profile_history_page.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

ProfileHistory makeAvatarHistory({
  int id = 1,
  bool isCurrent = true,
  bool isPrivate = false,
  String? url = 'https://example.com/avatar.jpg',
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

ProfileHistory makeStatusHistory({
  int id = 10,
  bool isCurrent = true,
  String content = '안녕하세요',
}) {
  return ProfileHistory(
    id: id,
    userId: 1,
    type: ProfileHistoryType.statusMessage,
    content: content,
    isCurrent: isCurrent,
    createdAt: DateTime(2024, 4, 1),
  );
}

Widget buildPage({
  required MockProfileBloc bloc,
  ProfileHistoryType type = ProfileHistoryType.avatar,
  bool isMyProfile = false,
  int userId = 1,
}) {
  return MaterialApp(
    home: BlocProvider<ProfileBloc>.value(
      value: bloc,
      child: ProfileHistoryPage(
        userId: userId,
        type: type,
        isMyProfile: isMyProfile,
      ),
    ),
  );
}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUpAll(() {
    registerFallbackValue(const ProfileHistoryLoadRequested(userId: 1));
  });

  setUp(() {
    mockProfileBloc = MockProfileBloc();
  });

  tearDown(() {
    mockProfileBloc.close();
  });

  group('ProfileHistoryPage - loading state', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loading),
      );
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      await tester.pumpWidget(buildPage(bloc: mockProfileBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('background is black while loading', (tester) async {
      await tester.pumpWidget(buildPage(bloc: mockProfileBloc));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('ProfileHistoryPage - empty state (avatar)', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, histories: []),
      );
    });

    testWidgets('shows empty icon when no avatar histories', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows empty message for avatar type', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.textContaining('프로필 사진 이력이 없습니다'), findsOneWidget);
    });

    testWidgets('shows close button in app bar', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows add button when isMyProfile and empty', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('사진 추가하기'), findsOneWidget);
    });

    testWidgets('hides add button when not my profile and empty', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('사진 추가하기'), findsNothing);
    });
  });

  group('ProfileHistoryPage - empty state (background)', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, histories: []),
      );
    });

    testWidgets('shows image_outlined icon for background type', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.background,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('shows empty message for background type', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.background,
      ));
      await tester.pump();

      expect(find.textContaining('배경화면 이력이 없습니다'), findsOneWidget);
    });

    testWidgets('shows add background button when isMyProfile', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.background,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('배경 추가하기'), findsOneWidget);
    });
  });

  group('ProfileHistoryPage - empty state (statusMessage)', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, histories: []),
      );
    });

    testWidgets('shows chat_bubble_outline icon for statusMessage type', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.statusMessage,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('shows empty message for statusMessage type', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.statusMessage,
      ));
      await tester.pump();

      expect(find.textContaining('상태메시지 이력이 없습니다'), findsOneWidget);
    });

    testWidgets('shows add statusMessage button when isMyProfile', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.statusMessage,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsOneWidget);
    });
  });

  group('ProfileHistoryPage - loaded state with histories', () {
    final avatarHistory = makeAvatarHistory();

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          histories: [avatarHistory],
        ),
      );
    });

    testWidgets('shows app bar with type label for avatar', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.text('프로필 사진'), findsOneWidget);
    });

    testWidgets('shows 더보기 button when isMyProfile and histories exist', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('hides 더보기 button when not my profile', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('더보기'), findsNothing);
    });

    testWidgets('shows date overlay for current history', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.text('2024년 3월 15일'), findsOneWidget);
    });

    testWidgets('shows 현재 badge when history isCurrent', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.text('현재'), findsOneWidget);
    });
  });

  group('ProfileHistoryPage - loaded state with multiple histories', () {
    final histories = [
      makeAvatarHistory(id: 1, isCurrent: true),
      makeAvatarHistory(id: 2, isCurrent: false),
      makeAvatarHistory(id: 3, isCurrent: false),
    ];

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          histories: histories,
        ),
      );
    });

    testWidgets('shows PageView with multiple items', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows page indicator when more than one history', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      // AnimatedContainer is used for page indicator dots
      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });

  group('ProfileHistoryPage - status message loaded state', () {
    final statusHistory = makeStatusHistory();

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          histories: [statusHistory],
        ),
      );
    });

    testWidgets('shows app bar with 상태메시지 label', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.statusMessage,
      ));
      await tester.pump();

      expect(find.text('상태메시지'), findsOneWidget);
    });

    testWidgets('shows status message content text', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.statusMessage,
      ));
      await tester.pump();

      expect(find.text('안녕하세요'), findsOneWidget);
    });
  });

  group('ProfileHistoryPage - privacy badge', () {
    final privateHistory = makeAvatarHistory(isPrivate: true);

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          histories: [privateHistory],
        ),
      );
    });

    testWidgets('shows 나만보기 badge when history isPrivate', (tester) async {
      await tester.pumpWidget(buildPage(
        bloc: mockProfileBloc,
        type: ProfileHistoryType.avatar,
      ));
      await tester.pump();

      expect(find.text('나만보기'), findsOneWidget);
    });
  });
}
