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

  WebSocketConnectionManager(this._authLocalDataSource);

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionState => _connectionStateController.stream;

  /// Current connection state.
  WebSocketConnectionState get currentConnectionState => _connectionState;

  /// Whether currently connected.
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

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
      debugPrint('[WebSocket] STOMP Error: ${frame.body}');
    }
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }

  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      debugPrint('[WebSocket] WebSocket Error: $error');
    }
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_isIntentionalDisconnect) return;

    if (_reconnectAttempts >= WebSocketConfig.maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Max reconnect attempts reached');
      }
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
      connect();
    });
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
