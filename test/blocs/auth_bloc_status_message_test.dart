import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/core/services/desktop_notification_bridge.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/domain/repositories/auth_repository.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/domain/repositories/notification_repository.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockWebSocketService extends Mock implements WebSocketService {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockDesktopNotificationBridge extends Mock implements DesktopNotificationBridge {}
class MockFile extends Mock implements File {}

void main() {
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

    when(() => mockDesktopNotificationBridge.setCurrentUserId(any())).thenReturn(null);
  });

  group('🔴 RED: AuthBloc statusMessage 업데이트 테스트', () {
    const testUser = User(
      id: 1,
      email: 'test@test.com',
      nickname: 'TestUser',
      statusMessage: '기존 상태메시지',
    );

    const updatedUser = User(
      id: 1,
      email: 'test@test.com',
      nickname: 'TestUser',
      statusMessage: '새로운 상태메시지',
    );

    blocTest<AuthBloc, AuthState>(
      '🔴 RED: 프로필 업데이트 시 statusMessage가 서버로 전송되어야 함',
      build: () {
        when(() => mockAuthRepository.updateProfile(
          userId: any(named: 'userId'),
          nickname: any(named: 'nickname'),
          statusMessage: any(named: 'statusMessage'),
          avatarUrl: any(named: 'avatarUrl'),
        )).thenAnswer((_) async {});

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => updatedUser);

        return AuthBloc(
          mockAuthRepository,
          mockWebSocketService,
          mockChatRepository,
          mockNotificationRepository,
          mockDesktopNotificationBridge,
        );
      },
      seed: () => AuthState.authenticated(testUser),
      act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
        statusMessage: '새로운 상태메시지',
      )),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(updatedUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.updateProfile(
          userId: 1,
          statusMessage: '새로운 상태메시지',
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      '🔴 RED: 닉네임과 상태메시지 동시 업데이트 가능해야 함',
      build: () {
        const bothUpdatedUser = User(
          id: 1,
          email: 'test@test.com',
          nickname: '새닉네임',
          statusMessage: '새상태메시지',
        );

        when(() => mockAuthRepository.updateProfile(
          userId: any(named: 'userId'),
          nickname: any(named: 'nickname'),
          statusMessage: any(named: 'statusMessage'),
          avatarUrl: any(named: 'avatarUrl'),
        )).thenAnswer((_) async {});

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => bothUpdatedUser);

        return AuthBloc(
          mockAuthRepository,
          mockWebSocketService,
          mockChatRepository,
          mockNotificationRepository,
          mockDesktopNotificationBridge,
        );
      },
      seed: () => AuthState.authenticated(testUser),
      act: (bloc) => bloc.add(const AuthProfileUpdateRequested(
        nickname: '새닉네임',
        statusMessage: '새상태메시지',
      )),
      expect: () => [
        const AuthState.loading(),
        isA<AuthState>().having((s) => s.user?.nickname, 'nickname', '새닉네임')
            .having((s) => s.user?.statusMessage, 'statusMessage', '새상태메시지'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.updateProfile(
          userId: 1,
          nickname: '새닉네임',
          statusMessage: '새상태메시지',
        )).called(1);
      },
    );
  });
}
