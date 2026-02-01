import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/desktop_notification_bridge.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final WebSocketService _webSocketService;
  final ChatRepository _chatRepository;
  final NotificationRepository _notificationRepository;
  final DesktopNotificationBridge _desktopNotificationBridge;

  AuthBloc(
    this._authRepository,
    this._webSocketService,
    this._chatRepository,
    this._notificationRepository,
    this._desktopNotificationBridge,
  ) : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthAvatarUploadRequested>(_onAvatarUploadRequested);
    on<AuthUserLocalUpdated>(_onUserLocalUpdated);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          // WebSocket 연결
          _webSocketService.connect();
          // FCM 토큰 등록 (모바일만)
          await _registerFcmTokenIfMobile();
          // 데스크톱 알림에 현재 사용자 ID 설정
          _desktopNotificationBridge.setCurrentUserId(user.id);
          emit(AuthState.authenticated(user));
        } else {
          emit(const AuthState.unauthenticated());
        }
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      // 인증 확인 실패 시 사용자 친화적인 메시지 제공
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      final user = await _authRepository.getCurrentUser();
      // WebSocket 연결
      _webSocketService.connect();
      // FCM 토큰 등록 (모바일만)
      await _registerFcmTokenIfMobile();
      if (user != null) {
        // 데스크톱 알림에 현재 사용자 ID 설정
        _desktopNotificationBridge.setCurrentUserId(user.id);
        emit(AuthState.authenticated(user));
      } else {
        // 로그인은 성공했지만 사용자 정보를 가져올 수 없는 경우
        // 임시 사용자 정보로 authenticated 상태 전환
        final userId = await _authRepository.getCurrentUserId();
        final placeholderUser = User(
          id: userId ?? 0,
          email: event.email,
          nickname: event.email.split('@').first,
        );
        // 데스크톱 알림에 현재 사용자 ID 설정
        _desktopNotificationBridge.setCurrentUserId(placeholderUser.id);
        emit(AuthState.authenticated(placeholderUser));
      }
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        nickname: event.nickname,
      );

      // Auto login after sign up
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      final user = await _authRepository.getCurrentUser();
      // WebSocket 연결
      _webSocketService.connect();
      // FCM 토큰 등록 (모바일만)
      await _registerFcmTokenIfMobile();
      if (user != null) {
        // 데스크톱 알림에 현재 사용자 ID 설정
        _desktopNotificationBridge.setCurrentUserId(user.id);
        emit(AuthState.authenticated(user));
      } else {
        // 회원가입 후 사용자 정보를 가져올 수 없는 경우
        // 임시 사용자 정보로 authenticated 상태 전환
        final userId = await _authRepository.getCurrentUserId();
        final placeholderUser = User(
          id: userId ?? 0,
          email: event.email,
          nickname: event.nickname,
        );
        // 데스크톱 알림에 현재 사용자 ID 설정
        _desktopNotificationBridge.setCurrentUserId(placeholderUser.id);
        emit(AuthState.authenticated(placeholderUser));
      }
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      // WebSocket 연결 해제
      _webSocketService.disconnect();
      // FCM 토큰 삭제 (모바일만)
      await _unregisterFcmTokenIfMobile();
      // 데스크톱 알림 사용자 ID 초기화
      _desktopNotificationBridge.setCurrentUserId(null);
      // 로컬 채팅 데이터 삭제
      await _chatRepository.clearLocalData();
      await _authRepository.logout();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
    }
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    emit(const AuthState.loading());

    try {
      await _authRepository.updateProfile(
        userId: currentUser.id,
        nickname: event.nickname,
        statusMessage: event.statusMessage,
        avatarUrl: event.avatarUrl,
      );

      // 프로필 업데이트 후 사용자 정보 다시 가져오기
      final updatedUser = await _authRepository.getCurrentUser();
      if (updatedUser != null) {
        emit(AuthState.authenticated(updatedUser));
      } else {
        // 업데이트는 성공했지만 사용자 정보를 가져오지 못한 경우
        // 로컬에서 업데이트된 정보로 대체
        final localUpdatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          nickname: event.nickname ?? currentUser.nickname,
          statusMessage: event.statusMessage ?? currentUser.statusMessage,
          avatarUrl: event.avatarUrl ?? currentUser.avatarUrl,
          status: currentUser.status,
          onlineStatus: currentUser.onlineStatus,
          createdAt: currentUser.createdAt,
        );
        emit(AuthState.authenticated(localUpdatedUser));
      }
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      // 실패 시 이전 상태 유지하고 에러 메시지만 표시
      emit(AuthState.failure(message));
      // 바로 이전 authenticated 상태로 복원
      emit(AuthState.authenticated(currentUser));
    }
  }

  Future<void> _onAvatarUploadRequested(
    AuthAvatarUploadRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    emit(const AuthState.loading());

    try {
      // 1. 이미지 업로드
      final avatarUrl = await _authRepository.uploadAvatar(event.imageFile);

      // 2. 프로필 업데이트
      await _authRepository.updateProfile(
        userId: currentUser.id,
        avatarUrl: avatarUrl,
      );

      // 3. 사용자 정보 다시 가져오기
      final updatedUser = await _authRepository.getCurrentUser();
      if (updatedUser != null) {
        emit(AuthState.authenticated(updatedUser));
      } else {
        // 로컬에서 업데이트
        final localUpdatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          nickname: currentUser.nickname,
          avatarUrl: avatarUrl,
          status: currentUser.status,
          onlineStatus: currentUser.onlineStatus,
          createdAt: currentUser.createdAt,
        );
        emit(AuthState.authenticated(localUpdatedUser));
      }
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
      emit(AuthState.authenticated(currentUser));
    }
  }

  void _onUserLocalUpdated(
    AuthUserLocalUpdated event,
    Emitter<AuthState> emit,
  ) {
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      avatarUrl: event.avatarUrl ?? currentUser.avatarUrl,
      backgroundUrl: event.backgroundUrl ?? currentUser.backgroundUrl,
      statusMessage: event.statusMessage ?? currentUser.statusMessage,
    );

    emit(AuthState.authenticated(updatedUser));
  }

  /// 모바일 플랫폼에서 FCM 토큰 등록 (현재 Android만 지원)
  /// TODO: iOS 푸시 알림 활성화 시 Platform.isIOS 조건 추가
  Future<void> _registerFcmTokenIfMobile() async {
    // 현재 Android만 지원 - iOS는 Apple Developer 유료 가입 후 활성화
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      await _notificationRepository.registerToken(platform: 'android');
      _notificationRepository.setupTokenRefreshListener(platform: 'android');
    } catch (e) {
      // FCM 토큰 등록 실패는 치명적이지 않음 - 로그만 남김
      // ignore: avoid_print
      print('[AuthBloc] Failed to register FCM token: $e');
    }
  }

  /// 모바일 플랫폼에서 FCM 토큰 삭제 (현재 Android만 지원)
  /// TODO: iOS 푸시 알림 활성화 시 Platform.isIOS 조건 추가
  Future<void> _unregisterFcmTokenIfMobile() async {
    // 현재 Android만 지원 - iOS는 Apple Developer 유료 가입 후 활성화
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      _notificationRepository.disposeTokenRefreshListener();
      await _notificationRepository.unregisterToken();
    } catch (e) {
      // FCM 토큰 삭제 실패는 치명적이지 않음 - 로그만 남김
      // ignore: avoid_print
      print('[AuthBloc] Failed to unregister FCM token: $e');
    }
  }
}
