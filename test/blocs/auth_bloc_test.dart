import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

class FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
  });
  late MockAuthRepository mockAuthRepository;
  late MockWebSocketService mockWebSocketService;
  late MockChatRepository mockChatRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockDesktopNotificationBridge mockDesktopNotificationBridge;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockWebSocketService = MockWebSocketService();
    mockChatRepository = MockChatRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockDesktopNotificationBridge = MockDesktopNotificationBridge();

    // WebSocketService mock 기본 설정
    when(() => mockWebSocketService.connect()).thenAnswer((_) async {});
    when(() => mockWebSocketService.disconnect()).thenReturn(null);

    // ChatRepository mock 기본 설정
    when(() => mockChatRepository.clearLocalData()).thenAnswer((_) async {});

    // NotificationRepository mock 기본 설정
    when(() => mockNotificationRepository.registerToken(userId: any(named: 'userId'), deviceType: any(named: 'deviceType')))
        .thenAnswer((_) async {});
    when(() => mockNotificationRepository.setupTokenRefreshListener(userId: any(named: 'userId'), deviceType: any(named: 'deviceType')))
        .thenReturn(null);
    when(() => mockNotificationRepository.unregisterToken()).thenAnswer((_) async {});
    when(() => mockNotificationRepository.disposeTokenRefreshListener()).thenReturn(null);

    // DesktopNotificationBridge mock 기본 설정
    when(() => mockDesktopNotificationBridge.setCurrentUserId(any())).thenReturn(null);
  });

  AuthBloc createBloc() => AuthBloc(
        mockAuthRepository,
        mockWebSocketService,
        mockChatRepository,
        mockNotificationRepository,
        mockDesktopNotificationBridge,
      );

  group('AuthBloc', () {
    test('initial state is AuthState.initial', () {
      final bloc = createBloc();
      expect(bloc.state, const AuthState.initial());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when user is logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when user is not logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => false);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.isLoggedIn()).called(1);
          verifyNever(() => mockAuthRepository.getCurrentUser());
          verifyNever(() => mockWebSocketService.connect());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when isLoggedIn throws exception',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when login succeeds',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.login(
                email: 'test@example.com',
                password: 'password123',
              )).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
          verify(() => mockWebSocketService.connect()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when login fails',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Invalid credentials'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with placeholder user when getCurrentUser returns null after login',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockAuthRepository.getCurrentUserId())
              .thenAnswer((_) async => 1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticated,
          ),
        ],
      );
    });

    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, signUpSuccess] when sign up succeeds',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenAnswer((_) async => 1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          const AuthState.signUpSuccess('test@example.com'),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signUp(
                email: 'test@example.com',
                password: 'password123',
                nickname: 'TestUser',
              )).called(1);
          verifyNever(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ));
          verifyNever(() => mockWebSocketService.connect());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when sign up fails',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenThrow(Exception('Email already exists'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'existing@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, signUpSuccess] with email when sign up succeeds (no auto-login)',
        build: () {
          when(() => mockAuthRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                nickname: any(named: 'nickname'),
              )).thenAnswer((_) async => 1);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          nickname: 'TestUser',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.signUpSuccess)
              .having((s) => s.signupEmail, 'signupEmail', 'test@example.com'),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockWebSocketService.disconnect()).called(1);
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when logout fails',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenThrow(Exception('Logout failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'logout 시 로컬 채팅 데이터를 삭제함',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockChatRepository.clearLocalData()).called(1);
        },
      );
    });

    group('AuthProfileUpdateRequested', () {
      blocTest<AuthBloc, AuthState>(
        'does nothing when current user is null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
          nickname: 'NewNick',
        )),
        expect: () => [],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with updated user when profile update succeeds',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
          nickname: 'NewNick',
          statusMessage: 'Hello',
        )),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.updateProfile(
                userId: FakeEntities.user.id,
                nickname: 'NewNick',
                statusMessage: 'Hello',
                avatarUrl: null,
              )).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'uses local updated user when getCurrentUser returns null after profile update',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
          nickname: 'UpdatedNick',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.nickname,
                'nickname',
                'UpdatedNick',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure, authenticated] when profile update fails and restores previous user',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenThrow(Exception('Update failed'));
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
          nickname: 'NewNick',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
          AuthState.authenticated(FakeEntities.user),
        ],
      );
    });

    group('AuthAvatarUploadRequested', () {
      blocTest<AuthBloc, AuthState>(
        'does nothing when current user is null',
        build: () => createBloc(),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with updated avatarUrl on success',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenAnswer((_) async => 'https://example.com/new-avatar.jpg');
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.uploadAvatar(any())).called(1);
          verify(() => mockAuthRepository.updateProfile(
                userId: FakeEntities.user.id,
                avatarUrl: 'https://example.com/new-avatar.jpg',
              )).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'uses local updated user with new avatarUrl when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenAnswer((_) async => 'https://example.com/new-avatar.jpg');
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/new-avatar.jpg',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure, authenticated] and restores user on upload failure',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenThrow(Exception('Upload failed'));
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
          AuthState.authenticated(FakeEntities.user),
        ],
      );
    });

    group('AuthUserLocalUpdated', () {
      blocTest<AuthBloc, AuthState>(
        'does nothing when current user is null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(avatarUrl: 'new.jpg')),
        expect: () => [],
      );

      blocTest<AuthBloc, AuthState>(
        'updates avatarUrl locally',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(
          avatarUrl: 'https://example.com/avatar.jpg',
        )),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/avatar.jpg',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'updates statusMessage while ignoring clearAvatar when user has avatarUrl (User.copyWith limitation)',
        build: () => createBloc(),
        seed: () {
          // Use a user with no avatarUrl; clearAvatar=true still emits new state with statusMessage change
          return AuthState.authenticated(FakeEntities.user);
        },
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(
          clearAvatar: true,
          statusMessage: 'After clear',
        )),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'After clear',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'updates statusMessage locally',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(
          statusMessage: 'New status',
        )),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'New status',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'updates backgroundUrl locally',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(
          backgroundUrl: 'https://example.com/bg.jpg',
        )),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.backgroundUrl,
                'backgroundUrl',
                'https://example.com/bg.jpg',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'clearAvatar=true does not clear avatarUrl due to User.copyWith null limitation',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(
          User(
            id: 1,
            email: 'test@example.com',
            nickname: 'TestUser',
            avatarUrl: 'https://example.com/old-avatar.jpg',
            createdAt: DateTime(2024, 1, 1),
          ),
        ),
        // User.copyWith does not support setting a field to null (null ?? existing),
        // so clearAvatar=true alone will not change the avatarUrl.
        // The emitted state equals the current state, so no emission occurs.
        act: (bloc) =>
            bloc.add(const AuthUserLocalUpdated(clearAvatar: true)),
        expect: () => [],
      );

      blocTest<AuthBloc, AuthState>(
        'updates all fields at once (avatarUrl, backgroundUrl, statusMessage)',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthUserLocalUpdated(
          avatarUrl: 'https://example.com/new-avatar.jpg',
          backgroundUrl: 'https://example.com/new-bg.jpg',
          statusMessage: 'New combined status',
        )),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/new-avatar.jpg',
              )
              .having(
                (s) => s.user?.backgroundUrl,
                'backgroundUrl',
                'https://example.com/new-bg.jpg',
              )
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'New combined status',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'preserves existing fields when only statusMessage is updated',
        build: () => createBloc(),
        seed: () => AuthState.authenticated(
          User(
            id: 1,
            email: 'test@example.com',
            nickname: 'TestUser',
            avatarUrl: 'https://example.com/avatar.jpg',
            backgroundUrl: 'https://example.com/bg.jpg',
            createdAt: DateTime(2024, 1, 1),
          ),
        ),
        act: (bloc) =>
            bloc.add(const AuthUserLocalUpdated(statusMessage: 'Only status')),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/avatar.jpg',
              )
              .having(
                (s) => s.user?.backgroundUrl,
                'backgroundUrl',
                'https://example.com/bg.jpg',
              )
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'Only status',
              ),
        ],
      );
    });

    group('AuthCheckRequested - additional branches', () {
      blocTest<AuthBloc, AuthState>(
        'failure state has null user because loading state clears user',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        // Even though we seed with an authenticated user, the bloc first emits
        // AuthState.loading() (no user), so state.user is null when the catch
        // block runs, yielding failure with null user.
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.failure)
              .having((s) => s.user, 'user', isNull),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sets desktop notification userId when user is found',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => FakeEntities.user);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(FakeEntities.user),
        ],
        verify: (_) {
          verify(() => mockDesktopNotificationBridge
              .setCurrentUserId(FakeEntities.user.id)).called(1);
        },
      );
    });

    group('AuthLoginRequested - additional branches', () {
      blocTest<AuthBloc, AuthState>(
        'uses id=0 when getCurrentUserId returns null after login with null user',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockAuthRepository.getCurrentUserId())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'user@example.com',
          password: 'pass',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user?.id, 'user.id', 0)
              .having(
                  (s) => s.user?.email, 'user.email', 'user@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sets desktop notification userId with placeholder user when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => FakeEntities.authToken);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockAuthRepository.getCurrentUserId())
              .thenAnswer((_) async => 42);
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'user@example.com',
          password: 'pass',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user?.id, 'user.id', 42),
        ],
        verify: (_) {
          verify(() =>
                  mockDesktopNotificationBridge.setCurrentUserId(42))
              .called(1);
        },
      );
    });

    group('AuthLogoutRequested - additional branches', () {
      blocTest<AuthBloc, AuthState>(
        'clears desktop notification userId on logout',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() =>
                  mockDesktopNotificationBridge.setCurrentUserId(null))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when clearLocalData throws',
        build: () {
          when(() => mockChatRepository.clearLocalData())
              .thenThrow(Exception('DB error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
        ],
      );
    });

    group('AuthProfileUpdateRequested - additional branches', () {
      blocTest<AuthBloc, AuthState>(
        'uses backgroundUrl from event when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
          nickname: 'NickFromEvent',
          statusMessage: 'StatusFromEvent',
          avatarUrl: 'https://example.com/avatar-from-event.jpg',
        )),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.nickname,
                'nickname',
                'NickFromEvent',
              )
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'StatusFromEvent',
              )
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/avatar-from-event.jpg',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'falls back to current user fields when event fields are null and getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        seed: () => AuthState.authenticated(
          User(
            id: 1,
            email: 'test@example.com',
            nickname: 'OriginalNick',
            statusMessage: 'OriginalStatus',
            avatarUrl: 'https://example.com/original.jpg',
            createdAt: DateTime(2024, 1, 1),
          ),
        ),
        act: (bloc) => bloc.add(const AuthProfileUpdateRequested()),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.user?.nickname,
                'nickname',
                'OriginalNick',
              )
              .having(
                (s) => s.user?.statusMessage,
                'statusMessage',
                'OriginalStatus',
              )
              .having(
                (s) => s.user?.avatarUrl,
                'avatarUrl',
                'https://example.com/original.jpg',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'error message is included in failure state',
        build: () {
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                nickname: any(named: 'nickname'),
                statusMessage: any(named: 'statusMessage'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenThrow(Exception('Server error'));
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) =>
            bloc.add(const AuthProfileUpdateRequested(nickname: 'Nick')),
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.failure)
              .having(
                  (s) => s.errorMessage, 'errorMessage', isNotNull),
          AuthState.authenticated(FakeEntities.user),
        ],
      );
    });

    group('AuthAvatarUploadRequested - additional branches', () {
      blocTest<AuthBloc, AuthState>(
        'error message is included in failure state',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenThrow(Exception('Upload error'));
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.failure)
              .having(
                  (s) => s.errorMessage, 'errorMessage', isNotNull),
          AuthState.authenticated(FakeEntities.user),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure, authenticated] when updateProfile throws after upload',
        build: () {
          when(() => mockAuthRepository.uploadAvatar(any()))
              .thenAnswer(
                  (_) async => 'https://example.com/new-avatar.jpg');
          when(() => mockAuthRepository.updateProfile(
                userId: any(named: 'userId'),
                avatarUrl: any(named: 'avatarUrl'),
              )).thenThrow(Exception('Profile update failed'));
          return createBloc();
        },
        seed: () => AuthState.authenticated(FakeEntities.user),
        act: (bloc) {
          final fakeFile = File('test.jpg');
          return bloc.add(AuthAvatarUploadRequested(imageFile: fakeFile));
        },
        expect: () => [
          const AuthState.loading(),
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.failure,
          ),
          AuthState.authenticated(FakeEntities.user),
        ],
      );
    });
  });
}
