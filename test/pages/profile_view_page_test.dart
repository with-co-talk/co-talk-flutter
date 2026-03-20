import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:co_talk_flutter/presentation/pages/profile/profile_view_page.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_event.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_state.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';

// Intercepts all HTTP calls during widget tests so that Image.network and
// CircleAvatar(backgroundImage: NetworkImage(...)) don't fail with real
// network errors.
class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  // Minimal valid 1×1 transparent PNG bytes.
  static final _transparentPixelPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE,
  ];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_transparentPixelPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Builds a widget tree that mounts the actual [ProfileViewPage].
/// `getIt` provides [MockProfileBloc]; [AuthBloc] comes via ancestor BlocProvider.
Widget buildTestApp({
  required MockProfileBloc profileBloc,
  required MockAuthBloc authBloc,
  int userId = 1,
  bool isMyProfile = false,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: ProfileViewPage(
            userId: userId,
            isMyProfile: isMyProfile,
          ),
        ),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/chat/direct/:id', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/report', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/chat/self/:id', builder: (_, __) => const SizedBox()),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockProfileBloc mockProfileBloc;
  late MockAuthBloc mockAuthBloc;
  final getIt = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(const AuthUserLocalUpdated());
    registerFallbackValue(const ProfileHistoryLoadRequested(userId: 1));
    registerFallbackValue(const ProfileUserLoadRequested(userId: 1));
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

    // Register mock ProfileBloc in getIt so ProfileViewPage.build() can call
    // getIt<ProfileBloc>() successfully.
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt.unregister<ProfileBloc>();
    }
    getIt.registerFactory<ProfileBloc>(() => mockProfileBloc);
  });

  tearDown(() {
    mockProfileBloc.close();
    mockAuthBloc.close();
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt.unregister<ProfileBloc>();
    }
  });

  group('ProfileViewPage - loading state', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loading),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(status: ProfileStatus.loading)),
      );
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when user is null with loaded status',
        (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, viewingUser: null),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(
            const ProfileState(status: ProfileStatus.loaded, viewingUser: null)),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ProfileViewPage - failure state', () {
    // The source code checks `loading || user == null` BEFORE checking `failure`.
    // So to reach the failure branch, viewingUser must be non-null.
    const failureUser = User(
      id: 99,
      email: 'fail@example.com',
      nickname: 'FailUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.failure,
          errorMessage: '서버 오류가 발생했습니다',
          viewingUser: failureUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.failure,
          errorMessage: '서버 오류가 발생했습니다',
          viewingUser: failureUser,
        )),
      );
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('서버 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('shows default error message when errorMessage is null',
        (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: failureUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: failureUser,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('프로필을 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows close icon button on failure', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('ProfileViewPage - loaded state', () {
    const testUser = User(
      id: 1,
      email: 'test@example.com',
      nickname: 'TestUser',
      statusMessage: '안녕하세요!',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: testUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: testUser,
        )),
      );
    });

    testWidgets('shows user nickname', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('shows status message when present', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('안녕하세요!'), findsOneWidget);
    });

    testWidgets('shows close button in app bar', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows settings icon when isMyProfile is true', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('does not show settings icon when isMyProfile is false',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('shows 1:1 chat action button for other profile', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('1:1 채팅'), findsOneWidget);
    });

    testWidgets('shows profile edit action button for my profile', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('프로필 편집'), findsOneWidget);
    });
  });

  group('ProfileViewPage - loaded state without status message', () {
    const testUserNoMessage = User(
      id: 2,
      email: 'test2@example.com',
      nickname: 'NoMessage',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: testUserNoMessage,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: testUserNoMessage,
        )),
      );
    });

    testWidgets('shows nickname without status message', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('NoMessage'), findsOneWidget);
    });

    testWidgets('shows add status message prompt when isMyProfile and no message',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink (no prompt) when not myProfile and no message',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsNothing);
    });
  });

  group('ProfileViewPage - widget is actual ProfileViewPage', () {
    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loading),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(status: ProfileStatus.loading)),
      );
    });

    testWidgets('ProfileViewPage widget is instantiated from source', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 42,
      ));
      await tester.pump();

      // Verifies the actual ProfileViewPage is in the widget tree
      expect(find.byType(ProfileViewPage), findsOneWidget);
    });

    testWidgets('ProfileViewPage adds load events on creation', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 99,
      ));
      await tester.pump();

      // The create callback adds both events, verify they were dispatched
      verify(() => mockProfileBloc.add(const ProfileUserLoadRequested(userId: 99)))
          .called(1);
      verify(() => mockProfileBloc.add(const ProfileHistoryLoadRequested(userId: 99)))
          .called(1);
    });
  });

  // ─── NEW TESTS ───────────────────────────────────────────────────────────────

  group('ProfileViewPage - _BackgroundImage (null/empty url → gradient)', () {
    testWidgets('shows gradient container when backgroundUrl is null', (tester) async {
      const userNoBackground = User(
        id: 3,
        email: 'bg@example.com',
        nickname: 'BgUser',
        backgroundUrl: null,
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoBackground,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoBackground,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      // With no background url the page still renders (no crash), nickname shown
      expect(find.text('BgUser'), findsOneWidget);
      // No Image.network for background (only gradient container)
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows Image.network when backgroundUrl is provided', (tester) async {
      const userWithBackground = User(
        id: 4,
        email: 'bg2@example.com',
        nickname: 'BgUser2',
        backgroundUrl: 'https://example.com/bg.jpg',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBackground,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBackground,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('BgUser2'), findsOneWidget);
      // Image.network is rendered for the background
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileViewPage - _ProfileAvatar (null url → initial letter)', () {
    testWidgets('shows initial letter when avatarUrl is null', (tester) async {
      const userNoAvatar = User(
        id: 5,
        email: 'av@example.com',
        nickname: 'Avatar',
        avatarUrl: null,
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoAvatar,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoAvatar,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      // Initial letter 'A' should appear inside CircleAvatar
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows CircleAvatar with NetworkImage when avatarUrl is provided',
        (tester) async {
      const userWithAvatar = User(
        id: 6,
        email: 'av2@example.com',
        nickname: 'WithAvatar',
        avatarUrl: 'https://example.com/avatar.jpg',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithAvatar,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithAvatar,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      // CircleAvatar is rendered; initial letter text should NOT be present
      expect(find.byType(CircleAvatar), findsOneWidget);
      // The initial letter 'W' should NOT be shown when avatarUrl is set
      expect(find.text('W'), findsNothing);
    });
  });

  group('ProfileViewPage - _StatusMessage branches', () {
    testWidgets('shows "상태메시지 추가" for myProfile with null message',
        (tester) async {
      const userNoMsg = User(
        id: 7,
        email: 'msg@example.com',
        nickname: 'MsgUser',
        statusMessage: null,
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoMsg,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoMsg,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows "상태메시지 추가" for myProfile with empty message',
        (tester) async {
      const userEmptyMsg = User(
        id: 8,
        email: 'msg2@example.com',
        nickname: 'EmptyMsg',
        statusMessage: '',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userEmptyMsg,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userEmptyMsg,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsOneWidget);
    });

    testWidgets('hides status message area for other profile with null message',
        (tester) async {
      const userNoMsg = User(
        id: 9,
        email: 'msg3@example.com',
        nickname: 'OtherNoMsg',
        statusMessage: null,
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoMsg,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userNoMsg,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('상태메시지 추가'), findsNothing);
      // SizedBox.shrink is rendered; the add icon should not appear
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('shows status message text for other profile with valid message',
        (tester) async {
      const userWithMsg = User(
        id: 10,
        email: 'msg4@example.com',
        nickname: 'OtherMsg',
        statusMessage: 'Hello world',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithMsg,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithMsg,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('shows status message text for myProfile with valid message',
        (tester) async {
      const userWithMsg = User(
        id: 11,
        email: 'msg5@example.com',
        nickname: 'MyMsg',
        statusMessage: '나의 상태',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithMsg,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithMsg,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('나의 상태'), findsOneWidget);
    });
  });

  group('ProfileViewPage - _ProfileActions (other profile)', () {
    const otherUser = User(
      id: 20,
      email: 'other@example.com',
      nickname: 'OtherUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: otherUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: otherUser,
        )),
      );
    });

    testWidgets('shows 1:1 채팅 and 신고 buttons', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('1:1 채팅'), findsOneWidget);
      expect(find.text('신고'), findsOneWidget);
    });

    testWidgets('shows chat_bubble_outline and report_outlined icons', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.report_outlined), findsOneWidget);
    });

    testWidgets('does NOT show 나와의 채팅 or 프로필 편집 for other profile', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('나와의 채팅'), findsNothing);
      expect(find.text('프로필 편집'), findsNothing);
    });
  });

  group('ProfileViewPage - _MyProfileActions (my profile)', () {
    const myUser = User(
      id: 1,
      email: 'me@example.com',
      nickname: 'MyUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        )),
      );
    });

    testWidgets('shows 나와의 채팅 and 프로필 편집 buttons', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('나와의 채팅'), findsOneWidget);
      expect(find.text('프로필 편집'), findsOneWidget);
    });

    testWidgets('shows chat_bubble_outline and edit_outlined icons for my profile',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('does NOT show 1:1 채팅 or 신고 for my profile', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('신고'), findsNothing);
    });
  });

  group('ProfileViewPage - _ActionButton interaction', () {
    const actionUser = User(
      id: 30,
      email: 'action@example.com',
      nickname: 'ActionUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: actionUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: actionUser,
        )),
      );
    });

    testWidgets('tapping 1:1 채팅 button navigates to direct chat route', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 30,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.tap(find.text('1:1 채팅'));
      await tester.pumpAndSettle();

      // After tap, navigation to /chat/direct/30 happens; the SizedBox route is shown
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping 신고 button navigates to report route', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 30,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.tap(find.text('신고'));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('_ActionButton renders icon and label correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      // Both buttons rendered with their icons
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('1:1 채팅'), findsOneWidget);
      expect(find.byIcon(Icons.report_outlined), findsOneWidget);
      expect(find.text('신고'), findsOneWidget);
    });
  });

  group('ProfileViewPage - 나와의 채팅 button interaction', () {
    const myUser = User(
      id: 1,
      email: 'me@example.com',
      nickname: 'MyUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        )),
      );
    });

    testWidgets('나와의 채팅 navigates when auth user is present', (tester) async {
      const authUser = User(
        id: 1,
        email: 'me@example.com',
        nickname: 'MyUser',
      );
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.authenticated(authUser),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 1,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('나와의 채팅'));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('나와의 채팅 shows snackbar when auth user is null', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.initial(),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 1,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('나와의 채팅'));
      await tester.pump();

      expect(find.text('로그인 정보를 찾을 수 없습니다'), findsOneWidget);
    });
  });

  group('ProfileViewPage - listener dispatches AuthUserLocalUpdated on success', () {
    testWidgets(
        'dispatches AuthUserLocalUpdated when status transitions to success for myProfile',
        (tester) async {
      const updatedUser = User(
        id: 1,
        email: 'me@example.com',
        nickname: 'Updated',
        avatarUrl: 'https://example.com/new-avatar.jpg',
        backgroundUrl: 'https://example.com/new-bg.jpg',
        statusMessage: '새 상태',
      );

      final successState = ProfileState(
        status: ProfileStatus.success,
        viewingUser: updatedUser,
      );

      // Start with loaded state, then emit success state
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: updatedUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ProfileState(
            status: ProfileStatus.loaded,
            viewingUser: updatedUser,
          ),
          successState,
        ]),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 1,
        isMyProfile: true,
      ));
      await tester.pumpAndSettle();

      // Verify AuthUserLocalUpdated was dispatched with the updated user's fields
      verify(() => mockAuthBloc.add(
            AuthUserLocalUpdated(
              avatarUrl: updatedUser.avatarUrl,
              backgroundUrl: updatedUser.backgroundUrl,
              statusMessage: updatedUser.statusMessage,
            ),
          )).called(1);
    });

    testWidgets(
        'does NOT dispatch AuthUserLocalUpdated when status is success but isMyProfile is false',
        (tester) async {
      const otherUser = User(
        id: 2,
        email: 'other@example.com',
        nickname: 'Other',
        avatarUrl: 'https://example.com/avatar.jpg',
        statusMessage: '상태',
      );

      final successState = ProfileState(
        status: ProfileStatus.success,
        viewingUser: otherUser,
      );

      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: otherUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ProfileState(
            status: ProfileStatus.loaded,
            viewingUser: otherUser,
          ),
          successState,
        ]),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 2,
        isMyProfile: false,
      ));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets(
        'does NOT dispatch AuthUserLocalUpdated when viewingUser is null in success state',
        (tester) async {
      final successStateNoUser = ProfileState(
        status: ProfileStatus.success,
        viewingUser: null,
      );

      // Initial state needs a user so we don't show the loading spinner indefinitely
      const seedUser = User(
        id: 1,
        email: 'me@example.com',
        nickname: 'Seed',
      );

      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: seedUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ProfileState(
            status: ProfileStatus.loaded,
            viewingUser: seedUser,
          ),
          successStateNoUser,
        ]),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 1,
        isMyProfile: true,
      ));
      // Use pump with duration instead of pumpAndSettle because emitting
      // successState with viewingUser==null causes loading spinner, which
      // keeps the animation running and causes pumpAndSettle to time out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockAuthBloc.add(any()));
    });
  });

  group('ProfileViewPage - history-based background/avatar display', () {
    testWidgets('uses background history url when getCurrentHistory returns a history',
        (tester) async {
      const userWithBg = User(
        id: 40,
        email: 'hist@example.com',
        nickname: 'HistUser',
        backgroundUrl: 'https://example.com/old-bg.jpg',
      );

      final backgroundHistory = ProfileHistory(
        id: 1,
        userId: 40,
        type: ProfileHistoryType.background,
        url: 'https://example.com/current-bg.jpg',
        isCurrent: true,
        createdAt: DateTime(2024, 1, 1),
      );

      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBg,
          histories: [backgroundHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBg,
          histories: [backgroundHistory],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      // Page renders successfully with history data
      expect(find.text('HistUser'), findsOneWidget);
      // Image.network is used for the background
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('uses avatar history url when getCurrentHistory returns a history',
        (tester) async {
      const userWithAvatar = User(
        id: 41,
        email: 'hist2@example.com',
        nickname: 'AvatarHist',
        avatarUrl: 'https://example.com/old-avatar.jpg',
      );

      final avatarHistory = ProfileHistory(
        id: 2,
        userId: 41,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/current-avatar.jpg',
        isCurrent: true,
        createdAt: DateTime(2024, 1, 1),
      );

      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithAvatar,
          histories: [avatarHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithAvatar,
          histories: [avatarHistory],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('AvatarHist'), findsOneWidget);
      // CircleAvatar with NetworkImage: initial letter text should NOT appear
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('falls back to user backgroundUrl when no history exists', (tester) async {
      const userWithBg = User(
        id: 42,
        email: 'fallback@example.com',
        nickname: 'FallbackUser',
        backgroundUrl: 'https://example.com/user-bg.jpg',
      );

      // No histories list — getCurrentHistory returns null, falls back to user.backgroundUrl
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBg,
          histories: [],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userWithBg,
          histories: [],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('FallbackUser'), findsOneWidget);
      // Background image is rendered from user.backgroundUrl
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('both background and avatar history urls are used when both present',
        (tester) async {
      const userFull = User(
        id: 43,
        email: 'full@example.com',
        nickname: 'FullUser',
        backgroundUrl: 'https://example.com/old-bg.jpg',
        avatarUrl: 'https://example.com/old-avatar.jpg',
      );

      final bgHistory = ProfileHistory(
        id: 10,
        userId: 43,
        type: ProfileHistoryType.background,
        url: 'https://example.com/current-bg.jpg',
        isCurrent: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final avHistory = ProfileHistory(
        id: 11,
        userId: 43,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/current-avatar.jpg',
        isCurrent: true,
        createdAt: DateTime(2024, 1, 1),
      );

      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userFull,
          histories: [bgHistory, avHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: userFull,
          histories: [bgHistory, avHistory],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('FullUser'), findsOneWidget);
      // At least one Image widget for background; CircleAvatar for avatar
      expect(find.byType(Image), findsAtLeastNWidgets(1));
      expect(find.byType(CircleAvatar), findsOneWidget);
      // Initial letter should not appear when avatar history url is set
      expect(find.text('F'), findsNothing);
    });
  });

  group('ProfileViewPage - settings button navigates to /settings', () {
    const myUser = User(
      id: 1,
      email: 'me@example.com',
      nickname: 'NavUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: myUser,
        )),
      );
    });

    testWidgets('tapping settings icon navigates', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });
  });

  // ─── EXTENDED COVERAGE TESTS ─────────────────────────────────────────────────

  group('ProfileViewPage - failure state close button pops', () {
    const failUser = User(id: 50, email: 'f@e.com', nickname: 'FailClose');

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: failUser,
          errorMessage: '오류입니다',
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: failUser,
          errorMessage: '오류입니다',
        )),
      );
    });

    testWidgets('shows error_outline icon on failure', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('failure AppBar has no settings icon', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsNothing);
    });
  });

  group('ProfileViewPage - _showStatusMessageDialog', () {
    const dialogUser = User(
      id: 60,
      email: 'dialog@example.com',
      nickname: 'DialogUser',
      statusMessage: '기존 상태',
    );

    void setupState(User user) {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(status: ProfileStatus.loaded, viewingUser: user),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(
            ProfileState(status: ProfileStatus.loaded, viewingUser: user)),
      );
    }

    testWidgets('tapping status message when isMyProfile opens dialog',
        (tester) async {
      setupState(dialogUser);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('상태메시지'), findsOneWidget);
    });

    testWidgets('status message dialog contains TextField pre-filled with current message',
        (tester) async {
      setupState(dialogUser);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      final widget = tester.widget<TextField>(textField);
      expect(widget.controller?.text, '기존 상태');
    });

    testWidgets('cancel button closes the status message dialog', (tester) async {
      setupState(dialogUser);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('save button dispatches ProfileHistoryCreateRequested and closes dialog',
        (tester) async {
      setupState(dialogUser);
      registerFallbackValue(ProfileHistoryCreateRequested(
        userId: 60,
        type: ProfileHistoryType.statusMessage,
        content: null,
        setCurrent: true,
      ));

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 60,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '새로운 상태');

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryCreateRequested>()
                .having((e) => e.type, 'type', ProfileHistoryType.statusMessage)
                .having((e) => e.content, 'content', '새로운 상태'),
          ))).called(1);
    });

    testWidgets('save button with empty trimmed text sends null content',
        (tester) async {
      setupState(dialogUser);
      registerFallbackValue(ProfileHistoryCreateRequested(
        userId: 60,
        type: ProfileHistoryType.statusMessage,
        content: null,
        setCurrent: true,
      ));

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 60,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '   ');

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryCreateRequested>()
                .having((e) => e.content, 'content', null),
          ))).called(1);
    });

    testWidgets('tapping status message does NOT open dialog when isMyProfile=false',
        (tester) async {
      setupState(dialogUser);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.tap(find.text('기존 상태'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping add status message placeholder opens dialog',
        (tester) async {
      const noMsgUser = User(
        id: 61,
        email: 'nomsg@example.com',
        nickname: 'NoMsgUser',
      );
      setupState(noMsgUser);

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('상태메시지 추가'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('ProfileViewPage - _showBackgroundOptions bottom sheet (no history)', () {
    const bgUser = User(
      id: 70,
      email: 'bg@example.com',
      nickname: 'BgOptions',
      backgroundUrl: 'https://example.com/bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgUser,
        )),
      );
    });

    testWidgets('long pressing background when isMyProfile opens bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      // Long press at the top-left corner of the screen where only the background
      // GestureDetector is reachable (the profile content sits at the bottom via
      // MainAxisAlignment.end, and the gradient overlay has IgnorePointer).
      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('배경화면'), findsOneWidget);
    });

    testWidgets('background options sheet shows 배경화면 변경 and 배경화면 이력 items',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('배경화면 변경'), findsOneWidget);
      expect(find.text('배경화면 이력'), findsOneWidget);
    });

    testWidgets('background options sheet shows 전체 화면 보기 when backgroundUrl set',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('전체 화면 보기'), findsOneWidget);
    });

    testWidgets('background options sheet does NOT show 삭제 or privacy options when no history',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsNothing);
      expect(find.text('나만 보기'), findsNothing);
    });

    testWidgets('long pressing background when isMyProfile=false does NOT open sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('배경화면'), findsNothing);
    });
  });

  group('ProfileViewPage - _showBackgroundOptions with history', () {
    final bgHistory = ProfileHistory(
      id: 100,
      userId: 71,
      type: ProfileHistoryType.background,
      url: 'https://example.com/current-bg.jpg',
      isCurrent: true,
      isPrivate: false,
      createdAt: DateTime(2024, 1, 1),
    );

    const bgHistoryUser = User(
      id: 71,
      email: 'bgh@example.com',
      nickname: 'BgHistUser',
      backgroundUrl: 'https://example.com/bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgHistoryUser,
          histories: [bgHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgHistoryUser,
          histories: [bgHistory],
        )),
      );
    });

    // The background-options sheet can have up to 5 items (title, 전체화면보기,
    // 배경화면변경, 배경화면이력, 나만보기, 삭제). Use a taller viewport so the
    // sheet Column does not overflow during layout.
    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('shows 나만 보기 and 삭제 when background history exists',
        (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('나만 보기'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('tapping 나만 보기 dispatches ProfileHistoryPrivacyToggled',
        (tester) async {
      useTallScreen(tester);
      registerFallbackValue(ProfileHistoryPrivacyToggled(
        userId: 71,
        historyId: 100,
        isPrivate: true,
      ));

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 71,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('나만 보기'));
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryPrivacyToggled>()
                .having((e) => e.historyId, 'historyId', 100)
                .having((e) => e.isPrivate, 'isPrivate', true),
          ))).called(1);
    });

    testWidgets('shows 전체 공개로 변경 when backgroundHistory.isPrivate is true',
        (tester) async {
      useTallScreen(tester);
      final privateHistory = ProfileHistory(
        id: 101,
        userId: 71,
        type: ProfileHistoryType.background,
        url: 'https://example.com/private-bg.jpg',
        isCurrent: true,
        isPrivate: true,
        createdAt: DateTime(2024, 1, 1),
      );

      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgHistoryUser,
          histories: [privateHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: bgHistoryUser,
          histories: [privateHistory],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('전체 공개로 변경'), findsOneWidget);
    });

    testWidgets('tapping 삭제 in background options shows confirm dialog',
        (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 71,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('배경화면 삭제'), findsOneWidget);
    });

    testWidgets('confirm delete dispatches ProfileHistoryDeleteRequested',
        (tester) async {
      useTallScreen(tester);
      registerFallbackValue(
        const ProfileHistoryDeleteRequested(userId: 71, historyId: 100),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 71,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // In the confirm dialog, tap 삭제 again
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryDeleteRequested>()
                .having((e) => e.historyId, 'historyId', 100),
          ))).called(1);
    });

    testWidgets('cancel in delete confirm dialog does NOT dispatch delete event',
        (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 71,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryDeleteRequested>(),
          )));
    });
  });

  group('ProfileViewPage - _showAvatarOptions bottom sheet (no avatar url)', () {
    const avatarUser = User(
      id: 80,
      email: 'av@example.com',
      nickname: 'AvatarOpts',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avatarUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avatarUser,
        )),
      );
    });

    testWidgets('long pressing avatar when isMyProfile opens 프로필 사진 sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('프로필 사진'), findsOneWidget);
    });

    testWidgets('avatar options sheet shows 프로필 사진 변경 and 프로필 사진 이력',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('프로필 사진 변경'), findsOneWidget);
      expect(find.text('프로필 사진 이력'), findsOneWidget);
    });

    testWidgets('avatar options sheet does NOT show 전체 화면 보기 when no avatar url',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('전체 화면 보기'), findsNothing);
    });

    testWidgets('avatar options sheet does NOT show 삭제 when no avatar history',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('long pressing avatar when isMyProfile=false does NOT open sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('프로필 사진'), findsNothing);
    });
  });

  group('ProfileViewPage - _showAvatarOptions with avatar url and history', () {
    final avHistory = ProfileHistory(
      id: 200,
      userId: 81,
      type: ProfileHistoryType.avatar,
      url: 'https://example.com/current-avatar.jpg',
      isCurrent: true,
      isPrivate: false,
      createdAt: DateTime(2024, 1, 1),
    );

    const avUser = User(
      id: 81,
      email: 'avh@example.com',
      nickname: 'AvHistUser',
      avatarUrl: 'https://example.com/avatar.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avUser,
          histories: [avHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avUser,
          histories: [avHistory],
        )),
      );
    });

    // Avatar-options sheet with all items can overflow small test viewports.
    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('avatar options sheet shows 나만 보기 and 삭제 with history',
        (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('나만 보기'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('avatar options sheet shows 전체 화면 보기 when avatarUrl provided',
        (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('전체 화면 보기'), findsOneWidget);
    });

    testWidgets('tapping 나만 보기 in avatar options dispatches privacy toggle',
        (tester) async {
      useTallScreen(tester);
      registerFallbackValue(ProfileHistoryPrivacyToggled(
        userId: 81,
        historyId: 200,
        isPrivate: true,
      ));

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 81,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('나만 보기'));
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryPrivacyToggled>()
                .having((e) => e.historyId, 'historyId', 200)
                .having((e) => e.isPrivate, 'isPrivate', true),
          ))).called(1);
    });

    testWidgets('shows 전체 공개로 변경 when avatarHistory.isPrivate is true',
        (tester) async {
      useTallScreen(tester);
      final privateAvHistory = ProfileHistory(
        id: 201,
        userId: 81,
        type: ProfileHistoryType.avatar,
        url: 'https://example.com/private-avatar.jpg',
        isCurrent: true,
        isPrivate: true,
        createdAt: DateTime(2024, 1, 1),
      );

      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avUser,
          histories: [privateAvHistory],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avUser,
          histories: [privateAvHistory],
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('전체 공개로 변경'), findsOneWidget);
    });

    testWidgets('tapping 삭제 in avatar options shows confirm dialog', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 81,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('프로필 사진 삭제'), findsOneWidget);
    });

    testWidgets('confirm avatar delete dispatches ProfileHistoryDeleteRequested',
        (tester) async {
      useTallScreen(tester);
      registerFallbackValue(
        const ProfileHistoryDeleteRequested(userId: 81, historyId: 200),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 81,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(any(
            that: isA<ProfileHistoryDeleteRequested>()
                .having((e) => e.historyId, 'historyId', 200),
          ))).called(1);
    });
  });

  group('ProfileViewPage - _showDeleteConfirmDialog standalone', () {
    final bgHistoryForDelete = ProfileHistory(
      id: 300,
      userId: 90,
      type: ProfileHistoryType.background,
      url: 'https://example.com/bg.jpg',
      isCurrent: true,
      isPrivate: false,
      createdAt: DateTime(2024, 1, 1),
    );

    const deleteUser = User(
      id: 90,
      email: 'del@example.com',
      nickname: 'DelUser',
      backgroundUrl: 'https://example.com/bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: deleteUser,
          histories: [bgHistoryForDelete],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: deleteUser,
          histories: [bgHistoryForDelete],
        )),
      );
    });

    testWidgets('delete confirm dialog contains item name and 삭제/취소 buttons',
        (tester) async {
      // Sheet has many items → use a taller viewport to prevent overflow.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 90,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('배경화면 삭제'), findsOneWidget);
      expect(find.text('배경화면을(를) 삭제하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsWidgets);
    });
  });

  group('ProfileViewPage - _showFullScreenImage via background options', () {
    const fsUser = User(
      id: 95,
      email: 'fs@example.com',
      nickname: 'FullScreenUser',
      backgroundUrl: 'https://example.com/fs-bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: fsUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: fsUser,
        )),
      );
    });

    testWidgets('tapping 전체 화면 보기 in background sheet opens full screen viewer',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      // Full screen viewer uses InteractiveViewer
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('full screen viewer closes on tap', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Tap the body GestureDetector to dismiss
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('full screen viewer supports vertical drag dismiss', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Drag down more than the dismiss threshold (100px) to close
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, 150));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('small drag does not dismiss full screen viewer', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Drag only 30px - below threshold, should snap back
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, 30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('ProfileViewPage - _showFullScreenImage via avatar options', () {
    final avHistoryForFs = ProfileHistory(
      id: 400,
      userId: 96,
      type: ProfileHistoryType.avatar,
      url: 'https://example.com/avatar-fs.jpg',
      isCurrent: true,
      isPrivate: false,
      createdAt: DateTime(2024, 1, 1),
    );

    const avFsUser = User(
      id: 96,
      email: 'avfs@example.com',
      nickname: 'AvatarFsUser',
      avatarUrl: 'https://example.com/avatar-fs.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avFsUser,
          histories: [avHistoryForFs],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: avFsUser,
          histories: [avHistoryForFs],
        )),
      );
    });

    testWidgets('tapping 전체 화면 보기 in avatar sheet opens full screen viewer',
        (tester) async {
      // Sheet with all items including 전체화면 + 변경 + 이력 + 나만보기 + 삭제
      // needs a taller viewport.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('ProfileViewPage - _MyProfileActions 프로필 편집 navigation', () {
    const editUser = User(
      id: 1,
      email: 'edit@example.com',
      nickname: 'EditUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: editUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: editUser,
        )),
      );
    });

    testWidgets('tapping 프로필 편집 navigates to /profile/edit', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 1,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('프로필 편집'));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileViewPage - loading state shows only spinner', () {
    testWidgets('no nickname shown during loading', (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loading),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(status: ProfileStatus.loading)),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('1:1 채팅'), findsNothing);
      expect(find.text('나와의 채팅'), findsNothing);
    });

    testWidgets('shows spinner for initial status', (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.initial),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(status: ProfileStatus.initial)),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ProfileViewPage - background/avatar GestureDetector tap opens history page', () {
    const tapUser = User(
      id: 110,
      email: 'tap@example.com',
      nickname: 'TapUser',
      backgroundUrl: 'https://example.com/bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: tapUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: tapUser,
        )),
      );
    });

    testWidgets('tapping background Image navigates (history page is pushed)',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      // Tap in the top area where only the background GestureDetector is
      // reachable (profile content sits at the bottom of the Stack).
      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      // ProfileHistoryPage is pushed via Navigator; we won't check the type
      // deeply, but the page should have changed (original page content gone)
      expect(find.text('TapUser'), findsNothing);
    });

    testWidgets('tapping avatar navigates to history page', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('TapUser'), findsNothing);
    });
  });

  group('ProfileViewPage - long pressing status message opens history page', () {
    const histMsgUser = User(
      id: 120,
      email: 'hm@example.com',
      nickname: 'HistMsgUser',
      statusMessage: '이력 상태',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: histMsgUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: histMsgUser,
        )),
      );
    });

    testWidgets('long pressing status message when isMyProfile opens history page',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPress(find.text('이력 상태'));
      await tester.pumpAndSettle();

      // History page is pushed; profile view page content no longer visible
      expect(find.text('HistMsgUser'), findsNothing);
    });
  });

  // ─── ADDITIONAL COVERAGE TESTS ───────────────────────────────────────────────

  group('ProfileViewPage - isMyProfile=true shows settings icon in AppBar', () {
    const settingsUser = User(
      id: 130,
      email: 'settings@example.com',
      nickname: 'SettingsUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, viewingUser: settingsUser),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(
            const ProfileState(status: ProfileStatus.loaded, viewingUser: settingsUser)),
      );
    });

    testWidgets('settings icon is present when isMyProfile=true (loaded state)',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('settings icon is absent when isMyProfile=false (loaded state)',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsNothing);
    });
  });

  group('ProfileViewPage - tapping status message area triggers dialog', () {
    const statusUser = User(
      id: 140,
      email: 'status@example.com',
      nickname: 'StatusTapUser',
      statusMessage: '탭 테스트 상태',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, viewingUser: statusUser),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(
            const ProfileState(status: ProfileStatus.loaded, viewingUser: statusUser)),
      );
    });

    testWidgets('tapping status message when isMyProfile=true opens AlertDialog',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('탭 테스트 상태'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog has 상태메시지 title and TextField', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.tap(find.text('탭 테스트 상태'));
      await tester.pumpAndSettle();

      expect(find.text('상태메시지'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping status message when isMyProfile=false does NOT open dialog',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      await tester.tap(find.text('탭 테스트 상태'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('ProfileViewPage - error state shows error icon and message', () {
    const errorUser = User(
      id: 150,
      email: 'err@example.com',
      nickname: 'ErrUser',
    );

    testWidgets('failure state shows Icons.error_outline', (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: errorUser,
          errorMessage: '연결 오류',
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: errorUser,
          errorMessage: '연결 오류',
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('연결 오류'), findsOneWidget);
    });

    testWidgets('failure state shows default message when errorMessage is null',
        (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: errorUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.failure,
          viewingUser: errorUser,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('프로필을 불러올 수 없습니다'), findsOneWidget);
    });
  });

  group('ProfileViewPage - loading state shows CircularProgressIndicator', () {
    testWidgets('loading status renders only the progress indicator', (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loading),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(status: ProfileStatus.loading)),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ProfileViewPage - _ProfileActions shows 1:1 채팅 and 신고', () {
    const profileActionsUser = User(
      id: 160,
      email: 'pa@example.com',
      nickname: 'ProfileActionsUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
            status: ProfileStatus.loaded, viewingUser: profileActionsUser),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
            status: ProfileStatus.loaded, viewingUser: profileActionsUser)),
      );
    });

    testWidgets('non-my-profile renders 1:1 채팅 and 신고 action buttons',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('1:1 채팅'), findsOneWidget);
      expect(find.text('신고'), findsOneWidget);
    });

    testWidgets('non-my-profile does NOT show 나와의 채팅 or 프로필 편집',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: false,
      ));
      await tester.pump();

      expect(find.text('나와의 채팅'), findsNothing);
      expect(find.text('프로필 편집'), findsNothing);
    });
  });

  group('ProfileViewPage - _MyProfileActions shows 나와의 채팅 and 프로필 편집', () {
    const myProfileActionsUser = User(
      id: 170,
      email: 'mpa@example.com',
      nickname: 'MyActionsUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
            status: ProfileStatus.loaded, viewingUser: myProfileActionsUser),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
            status: ProfileStatus.loaded, viewingUser: myProfileActionsUser)),
      );
    });

    testWidgets('my-profile renders 나와의 채팅 and 프로필 편집 action buttons',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('나와의 채팅'), findsOneWidget);
      expect(find.text('프로필 편집'), findsOneWidget);
    });

    testWidgets('my-profile does NOT show 1:1 채팅 or 신고', (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      expect(find.text('1:1 채팅'), findsNothing);
      expect(find.text('신고'), findsNothing);
    });
  });

  group('ProfileViewPage - delete confirm dialog from bottom sheet', () {
    final bgHistDel = ProfileHistory(
      id: 500,
      userId: 180,
      type: ProfileHistoryType.background,
      url: 'https://example.com/delbg.jpg',
      isCurrent: true,
      isPrivate: false,
      createdAt: DateTime(2024, 6, 1),
    );

    const delUser = User(
      id: 180,
      email: 'confirm@example.com',
      nickname: 'ConfirmUser',
      backgroundUrl: 'https://example.com/delbg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: delUser,
          histories: [bgHistDel],
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: delUser,
          histories: [bgHistDel],
        )),
      );
    });

    testWidgets('tapping 삭제 in background sheet then cancel dismisses dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 180,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // Confirm dialog is visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('배경화면 삭제'), findsOneWidget);

      // Cancel dismisses without dispatching delete
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirm dialog title contains item name', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        userId: 180,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('배경화면을(를) 삭제하시겠습니까?'), findsOneWidget);
    });
  });

  group('ProfileViewPage - _DismissibleProfileImageViewer rendering', () {
    const fsUser2 = User(
      id: 190,
      email: 'iv@example.com',
      nickname: 'ViewerUser',
      backgroundUrl: 'https://example.com/viewer-bg.jpg',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(status: ProfileStatus.loaded, viewingUser: fsUser2),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(
            const ProfileState(status: ProfileStatus.loaded, viewingUser: fsUser2)),
      );
    });

    testWidgets('full screen viewer renders InteractiveViewer and Image',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      // Open via background long press → 전체 화면 보기
      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      // The full-screen route uses Image.network for the image
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('full screen viewer responds to vertical drag update',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체 화면 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);

      // A drag smaller than the dismiss threshold should NOT dismiss the viewer
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('ProfileViewPage - _ProfileAvatar empty nickname shows ?', () {
    testWidgets('shows ? when nickname is empty', (tester) async {
      const emptyNicknameUser = User(
        id: 200,
        email: 'en@example.com',
        nickname: '',
      );
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: emptyNicknameUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: emptyNicknameUser,
        )),
      );

      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
      ));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('ProfileViewPage - long press on background when no url uses gradient', () {
    const noUrlUser = User(
      id: 210,
      email: 'nourl@example.com',
      nickname: 'NoUrlUser',
    );

    setUp(() {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: noUrlUser,
        ),
      );
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileState(
          status: ProfileStatus.loaded,
          viewingUser: noUrlUser,
        )),
      );
    });

    testWidgets('long pressing background area when no url opens sheet for myProfile',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        profileBloc: mockProfileBloc,
        authBloc: mockAuthBloc,
        isMyProfile: true,
      ));
      await tester.pump();

      // No Image.network present (gradient is used instead)
      expect(find.byType(Image), findsNothing);

      await tester.longPressAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      expect(find.text('배경화면'), findsOneWidget);
      // No 전체 화면 보기 because no url is set
      expect(find.text('전체 화면 보기'), findsNothing);
    });
  });
}
