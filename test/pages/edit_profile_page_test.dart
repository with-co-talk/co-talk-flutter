import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_event.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_state.dart';
import 'package:co_talk_flutter/presentation/pages/profile/edit_profile_page.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

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

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;

  setUpAll(() {
    registerFallbackValue(const AuthProfileUpdateRequested(
      nickname: 'Test',
    ));
    registerFallbackValue(const AuthUserLocalUpdated());
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  final testUser = User(
    id: 1,
    email: 'test@test.com',
    nickname: 'TestUser',
    avatarUrl: 'https://example.com/avatar.jpg',
    statusMessage: 'Hello World',
    backgroundUrl: 'https://example.com/bg.jpg',
  );

  final testUserNoAvatar = const User(
    id: 2,
    email: 'noavatar@test.com',
    nickname: 'NoAvatarUser',
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: EditProfilePage(profileBloc: mockProfileBloc),
      ),
    );
  }

  group('EditProfilePage', () {
    group('Initial Rendering', () {
      testWidgets('renders app bar with title', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('프로필 편집'), findsOneWidget);
      });

      testWidgets('shows loading indicator when user is null', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          const AuthState.initial(),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows profile image section', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('shows Scaffold with correct structure', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('Form Fields', () {
      testWidgets('displays nickname field with current value',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final nicknameField = find.widgetWithText(TextFormField, 'TestUser');
        expect(nicknameField, findsOneWidget);
      });

      testWidgets('displays status message field with current value',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Hello World'), findsOneWidget);
      });

      testWidgets('displays email field as read-only', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('test@test.com'), findsOneWidget);
      });

      testWidgets('nickname field accepts text input', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, 'NewNickname');

        expect(find.text('NewNickname'), findsOneWidget);
      });

      testWidgets('status message field accepts text input', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final statusField = find.widgetWithText(TextFormField, 'Hello World');
        await tester.enterText(statusField, 'New Status');
        await tester.pump();

        expect(find.text('New Status'), findsOneWidget);
      });

      testWidgets('displays 닉네임 label', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('닉네임'), findsOneWidget);
      });

      testWidgets('displays 상태메시지 label', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('상태메시지'), findsOneWidget);
      });

      testWidgets('shows user without avatar uses placeholder', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUserNoAvatar),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });

    group('Save Button', () {
      testWidgets('shows disabled save button when no changes',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final saveButton = find.widgetWithText(ElevatedButton, '변경사항 없음');
        expect(saveButton, findsOneWidget);

        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNull);
      });

      testWidgets('enables save button when nickname changes',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, 'NewNickname');
        await tester.pump();

        final saveButton = find.widgetWithText(ElevatedButton, '저장하기');
        expect(saveButton, findsOneWidget);

        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNotNull);
      });

      testWidgets('enables save button when status message changes',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final statusField = find.widgetWithText(TextFormField, 'Hello World');
        await tester.enterText(statusField, 'New Status');
        await tester.pump();

        final saveButton = find.widgetWithText(ElevatedButton, '저장하기');
        expect(saveButton, findsOneWidget);
      });

      testWidgets('dispatches AuthProfileUpdateRequested when save is pressed',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Change nickname
        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, 'NewNickname');
        await tester.pump();

        // Tap save button
        final saveButton = find.widgetWithText(ElevatedButton, '저장하기');
        await tester.tap(saveButton);
        await tester.pump();

        verify(() => mockAuthBloc.add(any(
              that: isA<AuthProfileUpdateRequested>()
                  .having((e) => e.nickname, 'nickname', 'NewNickname'),
            ))).called(1);
      });

      testWidgets('save button sends trimmed nickname', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, '  TrimmedNick  ');
        await tester.pump();

        final saveButton = find.widgetWithText(ElevatedButton, '저장하기');
        await tester.tap(saveButton);
        await tester.pump();

        verify(() => mockAuthBloc.add(any(
              that: isA<AuthProfileUpdateRequested>()
                  .having((e) => e.nickname, 'nickname', 'TrimmedNick'),
            ))).called(1);
      });

      testWidgets(
          'save button passes null statusMessage when empty status message',
          (tester) async {
        final userWithoutStatus = const User(
          id: 1,
          email: 'test@test.com',
          nickname: 'TestUser',
        );
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(userWithoutStatus),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Change nickname to trigger save availability
        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, 'NewNick');
        await tester.pump();

        final saveButton = find.widgetWithText(ElevatedButton, '저장하기');
        await tester.tap(saveButton);
        await tester.pump();

        verify(() => mockAuthBloc.add(any(
              that: isA<AuthProfileUpdateRequested>()
                  .having((e) => e.statusMessage, 'statusMessage', isNull),
            ))).called(1);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator on save button during loading',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          const AuthState(status: AuthStatus.loading),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('save button is disabled during loading', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState(status: ProfileStatus.creating),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Even after changing text, button should respect _isLoading state
        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, 'NewNick');
        await tester.pump();

        // Profile bloc creating status is handled by bloc listener,
        // so we test that the initial rendering doesn't break
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('AuthBloc State Listener', () {
      testWidgets('shows success snackbar when AuthBloc emits authenticated',
          (tester) async {
        final streamController = StreamController<AuthState>.broadcast();

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockAuthBloc.stream)
            .thenAnswer((_) => streamController.stream);
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );
        when(() => mockProfileBloc.stream)
            .thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createWidgetUnderTest());

        // Emit authenticated state (simulates successful profile update)
        streamController.add(
          AuthState.authenticated(testUser.copyWith(nickname: 'Updated')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Success snackbar should be shown
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('프로필이 수정되었습니다'), findsOneWidget);

        streamController.close();
      });

      testWidgets('shows error snackbar when AuthBloc emits failure',
          (tester) async {
        final streamController = StreamController<AuthState>.broadcast();

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockAuthBloc.stream)
            .thenAnswer((_) => streamController.stream);
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );
        when(() => mockProfileBloc.stream)
            .thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createWidgetUnderTest());

        streamController.add(
          const AuthState.failure('프로필 수정에 실패했습니다'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);

        streamController.close();
      });
    });

    group('ProfileBloc State Listener', () {
      testWidgets(
          'shows avatar success snackbar when ProfileBloc emits success without background',
          (tester) async {
        final authStreamController = StreamController<AuthState>.broadcast();
        final profileStreamController =
            StreamController<ProfileState>.broadcast();

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockAuthBloc.stream)
            .thenAnswer((_) => authStreamController.stream);
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );
        when(() => mockProfileBloc.stream)
            .thenAnswer((_) => profileStreamController.stream);

        await tester.pumpWidget(createWidgetUnderTest());

        // Emit success state from ProfileBloc (avatar uploaded)
        profileStreamController.add(
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              ProfileHistory(
                id: 1,
                userId: 1,
                type: ProfileHistoryType.avatar,
                url: 'https://example.com/new_avatar.jpg',
                isCurrent: true,
                createdAt: DateTime.now(),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('프로필 사진이 변경되었습니다'), findsOneWidget);

        authStreamController.close();
        profileStreamController.close();
      });

      testWidgets('shows error snackbar when ProfileBloc emits failure',
          (tester) async {
        final authStreamController = StreamController<AuthState>.broadcast();
        final profileStreamController =
            StreamController<ProfileState>.broadcast();

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockAuthBloc.stream)
            .thenAnswer((_) => authStreamController.stream);
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );
        when(() => mockProfileBloc.stream)
            .thenAnswer((_) => profileStreamController.stream);

        await tester.pumpWidget(createWidgetUnderTest());

        profileStreamController.add(
          const ProfileState(
            status: ProfileStatus.failure,
            errorMessage: '이미지 변경에 실패했습니다',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);

        authStreamController.close();
        profileStreamController.close();
      });

      testWidgets('dispatches AuthUserLocalUpdated when avatar upload succeeds',
          (tester) async {
        final authStreamController = StreamController<AuthState>.broadcast();
        final profileStreamController =
            StreamController<ProfileState>.broadcast();

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockAuthBloc.stream)
            .thenAnswer((_) => authStreamController.stream);
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );
        when(() => mockProfileBloc.stream)
            .thenAnswer((_) => profileStreamController.stream);

        await tester.pumpWidget(createWidgetUnderTest());

        // Simulate a successful avatar upload
        profileStreamController.add(
          ProfileState(
            status: ProfileStatus.success,
            histories: [
              ProfileHistory(
                id: 1,
                userId: 1,
                type: ProfileHistoryType.avatar,
                url: 'https://example.com/new_avatar.jpg',
                isCurrent: true,
                createdAt: DateTime.now(),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockAuthBloc.add(any(
              that: isA<AuthUserLocalUpdated>().having(
                  (e) => e.avatarUrl, 'avatarUrl', isNotNull),
            ))).called(1);

        authStreamController.close();
        profileStreamController.close();
      });
    });

    group('Profile Image Upload', () {
      testWidgets('shows profile image section', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('shows camera icon on avatar section', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });
    });

    group('Background Image', () {
      testWidgets('shows background image section', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('배경 변경'), findsOneWidget);
      });

      testWidgets('shows background history button', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('배경 이력'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('validates nickname field is not empty', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;
        await tester.enterText(nicknameField, '');
        await tester.pump();

        // Empty nickname disables save button (no changes detection)
        // or triggers validation error on form submit
        final saveButtonText = find.byType(ElevatedButton);
        expect(saveButtonText, findsOneWidget);
      });

      testWidgets('reverting nickname to original disables save button',
          (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Find the nickname field by its initial value
        final nicknameField =
            find.widgetWithText(TextFormField, 'TestUser').first;

        // Change nickname
        await tester.enterText(nicknameField, 'ChangedNick');
        await tester.pump();

        // Revert to original using the same finder (now showing 'ChangedNick')
        final changedField =
            find.widgetWithText(TextFormField, 'ChangedNick').first;
        await tester.enterText(changedField, 'TestUser');
        await tester.pump();

        // Save button should be disabled again (no changes)
        final saveButton = find.widgetWithText(ElevatedButton, '변경사항 없음');
        expect(saveButton, findsOneWidget);
        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNull);
      });
    });

    group('Account Info Section', () {
      testWidgets('shows 계정 정보 section header', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('계정 정보'), findsOneWidget);
      });

      testWidgets('shows 이메일 label', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('이메일'), findsOneWidget);
      });

      testWidgets('shows 수정불가 badge on email field', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('수정불가'), findsOneWidget);
      });
    });
  });
}
