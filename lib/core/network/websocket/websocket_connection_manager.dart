import 'dart:async';

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
  /// Returns immediately if already connecting or connected.
  /// Retrieves access token from local storage for authentication.
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Already connecting or connected, skipping');
      }
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);

    final accessToken = await _authLocalDataSource.getAccessToken();
    if (accessToken == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] No access token, cannot connect');
      }
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
        reconnectDelay: WebSocketConfig.reconnectDelay,
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
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

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

  void _onConnect(StompFrame frame) {
    if (kDebugMode) {
      debugPrint('[WebSocket] Connected successfully');
    }
    _reconnectAttempts = 0;
    _updateConnectionState(WebSocketConnectionState.connected);
    onConnected?.call();
  }

  void _onDisconnect(StompFrame frame) {
    if (kDebugMode) {
      debugPrint('[WebSocket] Disconnected');
    }
    _updateConnectionState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();
    _attemptReconnect();
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
    if (_reconnectAttempts >= WebSocketConfig.maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('[WebSocket] Max reconnect attempts reached');
      }
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(WebSocketConfig.reconnectDelay, () {
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
