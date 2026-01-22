import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../data/datasources/local/auth_local_datasource.dart';
import '../constants/api_constants.dart';

/// WebSocket 연결 상태
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket으로 수신된 채팅 메시지
class WebSocketChatMessage {
  final int messageId;
  final int? senderId;
  final int chatRoomId; // 구독 시 전달받은 roomId로 설정
  final String content;
  final String type;
  final DateTime createdAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileContentType;
  final String? thumbnailUrl;
  final int? replyToMessageId;
  final int? forwardedFromMessageId;

  WebSocketChatMessage({
    required this.messageId,
    this.senderId,
    required this.chatRoomId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileContentType,
    this.thumbnailUrl,
    this.replyToMessageId,
    this.forwardedFromMessageId,
  });

  factory WebSocketChatMessage.fromJson(Map<String, dynamic> json, int roomId) {
    return WebSocketChatMessage(
      messageId: json['messageId'] as int,
      senderId: json['senderId'] as int?,
      chatRoomId: json['roomId'] as int? ?? roomId,
      content: json['content'] as String? ?? '',
      type: json['type'] as String,
      createdAt: _parseDateTime(json['createdAt']),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      fileContentType: (json['fileContentType'] ?? json['contentType']) as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      replyToMessageId: json['replyToMessageId'] as int?,
      forwardedFromMessageId: json['forwardedFromMessageId'] as int?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is List && value.length >= 6) {
      final year = value[0] as int;
      final month = value[1] as int;
      final day = value[2] as int;
      final hour = value[3] as int;
      final minute = value[4] as int;
      final second = value[5] as int;
      final nano = value.length > 6 ? value[6] as int : 0;
      final millisecond = nano ~/ 1000000;
      final microsecond = (nano ~/ 1000) % 1000;
      return DateTime(year, month, day, hour, minute, second, millisecond, microsecond);
    }
    return DateTime.now();
  }
}

/// WebSocket으로 수신된 리액션 이벤트
class WebSocketReactionEvent {
  final int? reactionId;
  final int messageId;
  final int userId;
  final String emoji;
  final String eventType; // 'ADDED' or 'REMOVED'
  final int timestamp;

  WebSocketReactionEvent({
    this.reactionId,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.eventType,
    required this.timestamp,
  });

  factory WebSocketReactionEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketReactionEvent(
      reactionId: json['reactionId'] as int?,
      messageId: json['messageId'] as int,
      userId: json['userId'] as int,
      emoji: json['emoji'] as String,
      eventType: json['eventType'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

/// STOMP WebSocket 서비스
///
/// 채팅 메시지 실시간 송수신을 담당합니다.
/// - 연결/재연결 관리
/// - 채팅방 구독/구독해제
/// - 메시지 전송/수신
@lazySingleton
class WebSocketService {
  final AuthLocalDataSource _authLocalDataSource;

  StompClient? _stompClient;
  final Map<int, StompUnsubscribe> _subscriptions = {};
  final Set<int> _pendingSubscriptions = {}; // 연결 전 대기 중인 구독

  // 연결 상태
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;

  // 메시지 스트림
  final _messageController = StreamController<WebSocketChatMessage>.broadcast();

  // 리액션 스트림
  final _reactionController = StreamController<WebSocketReactionEvent>.broadcast();

  // 재연결 설정
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  Timer? _reconnectTimer;

  WebSocketService(this._authLocalDataSource);

  /// 연결 상태 스트림
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// 현재 연결 상태
  WebSocketConnectionState get currentConnectionState => _connectionState;

  /// 메시지 수신 스트림
  Stream<WebSocketChatMessage> get messages => _messageController.stream;

  /// 리액션 이벤트 스트림
  Stream<WebSocketReactionEvent> get reactions => _reactionController.stream;

  /// 연결 여부
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// WebSocket 연결
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      print('[WebSocket] Already connecting or connected, skipping');
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);

    final accessToken = await _authLocalDataSource.getAccessToken();
    if (accessToken == null) {
      print('[WebSocket] No access token, cannot connect');
      _updateConnectionState(WebSocketConnectionState.disconnected);
      return;
    }

    final wsUrl = ApiConstants.wsBaseUrl;
    print('[WebSocket] Connecting to: $wsUrl');

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
        onDebugMessage: (msg) => print('[WebSocket STOMP] $msg'),
        reconnectDelay: _reconnectDelay,
      ),
    );

    _stompClient!.activate();
  }

  /// WebSocket 연결 해제
  void disconnect() {
    // ignore: avoid_print
    print('[WebSocket] Disconnecting...');
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    // 모든 구독 해제
    for (final unsubscribe in _subscriptions.values) {
      unsubscribe();
    }
    _subscriptions.clear();
    _pendingSubscriptions.clear();

    _stompClient?.deactivate();
    _stompClient = null;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  /// 채팅방 구독
  void subscribeToChatRoom(int roomId) {
    // ignore: avoid_print
    print('[WebSocket] subscribeToChatRoom($roomId) - isConnected: $isConnected');

    if (_subscriptions.containsKey(roomId)) {
      // ignore: avoid_print
      print('[WebSocket] Already subscribed to room $roomId');
      return; // 이미 구독 중
    }

    if (!isConnected || _stompClient == null) {
      // ignore: avoid_print
      print('[WebSocket] Not connected - adding to pending subscriptions');
      _pendingSubscriptions.add(roomId);
      return;
    }

    _doSubscribe(roomId);
  }

  void _doSubscribe(int roomId) {
    if (_stompClient == null) return;

    // ignore: avoid_print
    print('[WebSocket] Subscribing to /topic/chat/room/$roomId');
    final messageUnsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/room/$roomId',
      callback: (frame) => _handleMessage(frame, roomId),
    );

    _subscriptions[roomId] = messageUnsubscribe;
    _pendingSubscriptions.remove(roomId);
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(int roomId) {
    // ignore: avoid_print
    print('[WebSocket] Unsubscribing from room $roomId');
    _pendingSubscriptions.remove(roomId);
    final unsubscribe = _subscriptions.remove(roomId);
    unsubscribe?.call();
  }

  /// 텍스트 메시지 전송
  void sendMessage({
    required int roomId,
    required int senderId,
    required String content,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/message',
      body: jsonEncode({
        'roomId': roomId,
        'senderId': senderId,
        'content': content,
      }),
    );
  }

  /// 파일 메시지 전송
  void sendFileMessage({
    required int roomId,
    required int senderId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/message/file',
      body: jsonEncode({
        'roomId': roomId,
        'senderId': senderId,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
        'thumbnailUrl': thumbnailUrl,
      }),
    );
  }

  /// 리액션 추가
  void addReaction({
    required int messageId,
    required int userId,
    required String emoji,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/reaction/add',
      body: jsonEncode({
        'messageId': messageId,
        'userId': userId,
        'emoji': emoji,
      }),
    );
  }

  /// 리액션 제거
  void removeReaction({
    required int messageId,
    required int userId,
    required String emoji,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/reaction/remove',
      body: jsonEncode({
        'messageId': messageId,
        'userId': userId,
        'emoji': emoji,
      }),
    );
  }

  // Private methods

  void _onConnect(StompFrame frame) {
    // ignore: avoid_print
    print('[WebSocket] Connected successfully');
    _reconnectAttempts = 0;
    _updateConnectionState(WebSocketConnectionState.connected);

    // 기존 구독 복원
    final roomIds = _subscriptions.keys.toList();
    _subscriptions.clear();
    for (final roomId in roomIds) {
      _doSubscribe(roomId);
    }

    // 대기 중인 구독 처리
    final pendingRoomIds = _pendingSubscriptions.toList();
    // ignore: avoid_print
    print('[WebSocket] Processing ${pendingRoomIds.length} pending subscriptions');
    for (final roomId in pendingRoomIds) {
      _doSubscribe(roomId);
    }
  }

  void _onDisconnect(StompFrame frame) {
    // ignore: avoid_print
    print('[WebSocket] Disconnected: ${frame.body}');
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }

  void _onStompError(StompFrame frame) {
    // ignore: avoid_print
    print('[WebSocket] STOMP Error: ${frame.body}');
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }

  void _onWebSocketError(dynamic error) {
    // ignore: avoid_print
    print('[WebSocket] WebSocket Error: $error');
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      _updateConnectionState(WebSocketConnectionState.reconnecting);
      connect();
    });
  }

  void _handleMessage(StompFrame frame, int roomId) {
    // ignore: avoid_print
    print('[WebSocket] _handleMessage called for roomId: $roomId');
    // ignore: avoid_print
    print('[WebSocket] Frame body: ${frame.body}');

    if (frame.body == null) {
      // ignore: avoid_print
      print('[WebSocket] Frame body is null, returning');
      return;
    }

    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      // ignore: avoid_print
      print('[WebSocket] Parsed JSON: $json');

      // 메시지 타입 확인
      if (json.containsKey('messageId')) {
        // ignore: avoid_print
        print('[WebSocket] Contains messageId, parsing as chat message');
        final message = WebSocketChatMessage.fromJson(json, roomId);
        // ignore: avoid_print
        print('[WebSocket] Parsed message: id=${message.messageId}, content=${message.content}');
        _messageController.add(message);
        // ignore: avoid_print
        print('[WebSocket] Message added to stream');
      } else if (json.containsKey('eventType')) {
        final reaction = WebSocketReactionEvent.fromJson(json);
        _reactionController.add(reaction);
      } else {
        // ignore: avoid_print
        print('[WebSocket] Unknown message type: $json');
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[WebSocket] Error parsing message: $e');
      // ignore: avoid_print
      print('[WebSocket] Stack trace: $stackTrace');
    }
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// 리소스 해제
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _reactionController.close();
  }
}
