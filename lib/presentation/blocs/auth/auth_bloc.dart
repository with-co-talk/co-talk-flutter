import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final WebSocketService _webSocketService;

  AuthBloc(this._authRepository, this._webSocketService)
      : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
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
      if (user != null) {
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
      if (user != null) {
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
      await _authRepository.logout();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      final message = ErrorMessageMapper.toUserFriendlyMessage(e);
      emit(AuthState.failure(message));
    }
  }
}
