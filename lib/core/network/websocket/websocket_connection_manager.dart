import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../data/datasources/local/auth_local_datasource.dart';
import 'websocket_config.dart';
import 'websocket_events.dart';

/// Callback type for connection state changes.
typedef ConnectionStateCallback = void Function(WebSocketConnectionState state);

/// Callback type for STOMP frame handling.
typedef FrameCallback = void Function(StompFrame frame);

/// Manages WebSocket/STOMP connection lifecycle.
///
/// Responsibilities:
/// - STOMP client creation and configuration
/// - Connection and disconnection
/// - Automatic reconnection with exponential backoff
/// - Connection state management
/// - Heartbeat handling (via STOMP)
class WebSocketConnectionManager {
  final AuthLocalDataSource _authLocalDataSource;

  StompClient? _stompClient;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isIntentionalDisconnect = false;
  DateTime? _connectingStartedAt;
  final _random = Random();

  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;

  /// Callback invoked when connection is established.
  VoidCallback? onConnected;

  /// Callback invoked when connection is lost.
  VoidCallback? onDisconnected;

  /// Callback invoked to refresh the access token before reconnection.
  /// Called when a STOMP auth error is detected, giving the app a chance
  /// to refresh the token before the next connect attempt.
  Future<void> Function()? onTokenRefreshNeeded;
  bool _needsTokenRefresh = false;

  WebSocketConnectionManager(this._authLocalDataSource);

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionState => _connectionStateController.stream;

  /// Current connection state.
  WebSocketConnectionState get currentConnectionState => _connectionState;

  /// Whether currently connected.
  ///
  /// Checks BOTH our cached state AND the STOMP client's actual connected state.
  /// This prevents sending messages to a half-open (dead) WebSocket connection
  /// when the STOMP library has detected the disconnect but our callback hasn't
  /// fired yet.
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected &&
      _stompClient != null &&
      _stompClient!.connected;

  /// The underlying STOMP client (if connected).
  StompClient? get stompClient => _stompClient;

  /// Connects to the WebSocket server.
  ///
  /// Returns immediately if already connected.
  /// If stuck in `connecting` state beyond [WebSocketConfig.connectTimeout],
  /// kills the stale attempt and starts fresh.
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connected) {
      return;
    }

    if (_connectionState == WebSocketConnectionState.connecting) {
      // Check if the current attempt is stale
      if (_connectingStartedAt != null) {
        final elapsed = DateTime.now().difference(_connectingStartedAt!);
        if (elapsed > WebSocketConfig.connectTimeout) {
          if (kDebugMode) {
            debugPrint('[WebSocket] Connection stuck in connecting for ${elapsed.inSeconds}s, force-resetting');
          }
          _forceReset();
        } else {
          if (kDebugMode) {
            debugPrint('[WebSocket] Already connecting (${elapsed.inSeconds}s ago), skipping');
          }
          return;
        }
      } else {
        return;
      }
    }

    _isIntentionalDisconnect = false;
    _connectingStartedAt = DateTime.now();
    _updateConnectionState(WebSocketConnectionState.connecting);

    final accessToken = await _authLocalDataSource.getAccessToken();
    if (accessToken == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] No access token, cannot connect');
      }
      _updateConnectionState(WebSocketConnectionState.disconnected);
      return;
    }

    // Guard: if disconnect() was called while we were awaiting the token,
    // abort this connection attempt.
    if (_isIntentionalDisconnect) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Intentional disconnect during connect(), aborting');
      }
      _connectingStartedAt = null;
      _updateConnectionState(WebSocketConnectionState.disconnected);
      return;
    }

    final wsUrl = WebSocketConfig.wsBaseUrl;
    if (kDebugMode) {
      debugPrint('[WebSocket] Connecting to: $wsUrl');
    }

    // Clean up any existing client before creating a new one
    _stompClient?.deactivate();

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: _onStompError,
        onWebSocketError: _onWebSocketError,
        onDebugMessage: kDebugMode ? (msg) {
          debugPrint('[WebSocket STOMP] $msg');
        } : (_) {},
        // Disable STOMP library's built-in reconnect; we handle reconnection ourselves
        reconnectDelay: Duration.zero,
      ),
    );

    _stompClient!.activate();
  }

  /// Disconnects from the WebSocket server.
  ///
  /// Cancels any pending reconnection attempts.
  void disconnect() {
    if (kDebugMode) {
      debugPrint('[WebSocket] Disconnecting...');
    }
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _connectingStartedAt = null;

    _stompClient?.deactivate();
    _stompClient = null;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  /// Resets reconnection counter.
  ///
  /// Call this when reconnection should start fresh.
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Force-resets a stale connection attempt.
  void _forceReset() {
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();
    _stompClient = null;
    _connectingStartedAt = null;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  void _onConnect(StompFrame frame) {
    if (kDebugMode) {
      debugPrint('[WebSocket] Connected successfully');
    }
    _reconnectAttempts = 0;
    _connectingStartedAt = null;
    _updateConnectionState(WebSocketConnectionState.connected);
    onConnected?.call();
  }

  void _onDisconnect(StompFrame frame) {
    if (kDebugMode) {
      debugPrint('[WebSocket] Disconnected (intentional=$_isIntentionalDisconnect)');
    }
    _updateConnectionState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();
    if (!_isIntentionalDisconnect) {
      _attemptReconnect();
    }
  }

  void _onStompError(StompFrame frame) {
    if (kDebugMode) {
      debugPrint('[WebSocket] STOMP Error: headers=${frame.headers}, body=${frame.body}');
    }

    final isAuthError = _isAuthError(frame);

    _updateConnectionState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();

    if (isAuthError) {
      if (kDebugMode) debugPrint('[WebSocket] Auth error detected: ${frame.body}');
      // Mark that a token refresh is needed before the next reconnection.
      _needsTokenRefresh = true;
    }
    _attemptReconnect();
  }

  /// STOMP ERROR 프레임이 인증(토큰 만료/거부) 오류인지 판정한다.
  ///
  /// 인증 오류 감지의 단일 진입점(centralized): 분산된 문자열 매칭을 한곳에 모아
  /// 재연결 전 토큰 갱신 여부를 결정한다.
  ///
  /// 우선순위:
  /// 1. 구조적 신호 — STOMP ERROR 프레임의 헤더. STOMP 명세상 ERROR 프레임은
  ///    사람이 읽을 수 있는 `message` 헤더를 가질 수 있고, 서버가 status/code
  ///    헤더로 HTTP 상태를 전달하는 경우도 있다. 헤더가 401/403/UNAUTHORIZED
  ///    계열이면 우선 신뢰한다(본문 문자열보다 견고).
  /// 2. fallback — 서버가 구조화된 헤더 없이 텍스트 본문만 보낼 때를 대비해
  ///    본문/메시지 헤더 텍스트를 robust하게 매칭한다.
  static bool _isAuthError(StompFrame frame) {
    final headers = frame.headers;

    // 1. 구조적 신호: status/code 류 헤더의 HTTP 상태 코드.
    for (final key in const ['status', 'status-code', 'code']) {
      final value = headers[key];
      if (value != null) {
        final parsed = int.tryParse(value.trim());
        if (parsed == 401 || parsed == 403) return true;
      }
    }

    // 2. 텍스트 매칭 fallback: `message` 헤더 + 본문을 합쳐 한 번에 검사한다.
    final haystack =
        '${headers['message'] ?? ''} ${frame.body ?? ''}'.toLowerCase();
    if (haystack.isEmpty) return false;
    return haystack.contains('401') ||
        haystack.contains('403') ||
        haystack.contains('unauthorized') ||
        haystack.contains('authentication') ||
        haystack.contains('access denied') ||
        haystack.contains('forbidden');
  }

  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      debugPrint('[WebSocket] WebSocket Error: $error');
    }
    _updateConnectionState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_isIntentionalDisconnect) return;

    if (_reconnectAttempts >= WebSocketConfig.maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Max reconnect attempts reached');
      }
      _updateConnectionState(WebSocketConnectionState.failed);
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff with jitter:
    // delay = min(base * 2^attempt, maxDelay) + random(0~1000ms)
    final baseMs = WebSocketConfig.initialReconnectDelay.inMilliseconds;
    final maxMs = WebSocketConfig.maxReconnectDelay.inMilliseconds;
    final exponentialMs = min(baseMs * (1 << _reconnectAttempts), maxMs);
    final jitterMs = _random.nextInt(1000);
    final delay = Duration(milliseconds: exponentialMs + jitterMs);

    if (kDebugMode) {
      debugPrint('[WebSocket] Scheduling reconnect in ${delay.inMilliseconds}ms');
    }

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (kDebugMode) {
        debugPrint('[WebSocket] Reconnect attempt $_reconnectAttempts/${WebSocketConfig.maxReconnectAttempts}');
      }
      _updateConnectionState(WebSocketConnectionState.reconnecting);
      _doReconnect();
    });
  }

  /// Performs reconnection, refreshing the token first if needed.
  Future<void> _doReconnect() async {
    if (_needsTokenRefresh && onTokenRefreshNeeded != null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Refreshing token before reconnect...');
      }
      try {
        await onTokenRefreshNeeded!();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[WebSocket] Token refresh failed during reconnect: $e');
        }
      }
      _needsTokenRefresh = false;
    }
    connect();
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Disposes resources.
  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}
