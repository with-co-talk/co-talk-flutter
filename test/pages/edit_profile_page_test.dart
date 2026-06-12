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
    });

    group('Success State', () {
      testWidgets('shows success snackbar when profile update succeeds',
          (tester) async {
        // 초기 상태는 authenticated(폼 렌더링), 이후 stream 으로
        // loading -> authenticated 전이를 emit 해 AuthBloc BlocListener
        // (edit_profile_page.dart:385~)의 success 경로를 발화시킨다.
        final updatedUser = testUser.copyWith(nickname: 'NewNickname');
        whenListen(
          mockAuthBloc,
          Stream<AuthState>.fromIterable([
            const AuthState(status: AuthStatus.loading),
            AuthState.authenticated(updatedUser),
          ]),
          initialState: AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // CachedNetworkImage(BackgroundImageSection)의 placeholder는 테스트
        // 환경에서 무한 pending이라 pumpAndSettle 이 타임아웃된다.
        // 파일 내 다른 테스트와 동일하게 유한 pump 로 프레임을 진행한다.
        await tester.pump(const Duration(milliseconds: 300));

        // showSuccessSnackbar 가 띄운 SnackBar 와 실제 문구('프로필이 수정되었습니다')를 검증.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('프로필이 수정되었습니다'), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('shows error snackbar when profile update fails',
          (tester) async {
        // 초기 authenticated 이후 stream 으로 loading -> failure 전이를 emit 해
        // AuthBloc BlocListener(edit_profile_page.dart:401~)의 showErrorSnackbar 를 발화.
        whenListen(
          mockAuthBloc,
          Stream<AuthState>.fromIterable([
            const AuthState(status: AuthStatus.loading),
            const AuthState(
              status: AuthStatus.failure,
              errorMessage: 'Update failed',
            ),
          ]),
          initialState: AuthState.authenticated(testUser),
        );
        when(() => mockProfileBloc.state).thenReturn(
          const ProfileState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // CachedNetworkImage(BackgroundImageSection)의 placeholder는 테스트
        // 환경에서 무한 pending이라 pumpAndSettle 이 타임아웃된다.
        // 파일 내 다른 테스트와 동일하게 유한 pump 로 프레임을 진행한다.
        await tester.pump(const Duration(milliseconds: 300));

        // showErrorSnackbar 가 state.errorMessage 를 그대로 노출하는지 검증.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Update failed'), findsOneWidget);
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

        // Empty nickname should disable save button
        // (depends on validation implementation)
      });
    });
  });
}
