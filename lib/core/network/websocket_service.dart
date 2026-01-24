import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../data/datasources/local/auth_local_datasource.dart';
import '../constants/api_constants.dart';
import 'event_dedupe_cache.dart';

/// WebSocket payload 파싱 결과(방 토픽).
sealed class ParsedRoomPayload {
  const ParsedRoomPayload();
}

final class ParsedChatMessagePayload extends ParsedRoomPayload {
  final WebSocketChatMessage message;

  const ParsedChatMessagePayload(this.message);
}

final class ParsedReadPayload extends ParsedRoomPayload {
  final WebSocketReadEvent event;

  const ParsedReadPayload(this.event);
}

final class ParsedReactionPayload extends ParsedRoomPayload {
  final WebSocketReactionEvent event;

  const ParsedReactionPayload(this.event);
}

final class ParsedTypingPayload extends ParsedRoomPayload {
  final WebSocketTypingEvent event;

  const ParsedTypingPayload(this.event);
}

final class ParsedUnknownPayload extends ParsedRoomPayload {
  final Map<String, dynamic> raw;

  const ParsedUnknownPayload(this.raw);
}

/// WebSocket 수신 JSON을 도메인 이벤트로 변환하는 파서.
///
/// STOMP 연결 없이도 테스트 가능하도록 분리한다.
class WebSocketPayloadParser {
  const WebSocketPayloadParser();

  ParsedRoomPayload parseRoomPayload({
    required String body,
    required int roomId,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final eventType = json['eventType'] as String?;

    // 채팅 메시지 (기존 서버 payload: messageId 존재 + eventType 없음)
    if (json.containsKey('messageId') && eventType == null) {
      return ParsedChatMessagePayload(WebSocketChatMessage.fromJson(json, roomId));
    }

    if (eventType == 'READ') {
      return ParsedReadPayload(WebSocketReadEvent.fromJson(json));
    }

    if (eventType == 'ADDED' || eventType == 'REMOVED') {
      return ParsedReactionPayload(WebSocketReactionEvent.fromJson(json));
    }

    if (eventType == 'TYPING' || eventType == 'STOP_TYPING') {
      return ParsedTypingPayload(WebSocketTypingEvent.fromJson(json));
    }

    return ParsedUnknownPayload(json);
  }

  WebSocketChatRoomUpdateEvent parseChatListPayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketChatRoomUpdateEvent.fromJson(json);
  }

  WebSocketReadEvent parseReadReceiptPayload(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WebSocketReadEvent.fromJson(json);
  }
}

/// WebSocket 연결 상태
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket으로 수신된 채팅 메시지
class WebSocketChatMessage {
  final int? schemaVersion;
  final String? eventId;
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
  final int unreadCount;

  WebSocketChatMessage({
    this.schemaVersion,
    this.eventId,
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
    this.unreadCount = 0,
  });

  factory WebSocketChatMessage.fromJson(Map<String, dynamic> json, int roomId) {
    return WebSocketChatMessage(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
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
      unreadCount: json['unreadCount'] as int? ?? 0,
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
  final int? schemaVersion;
  final String? eventId;
  final int? reactionId;
  final int messageId;
  final int userId;
  final String emoji;
  final String eventType; // 'ADDED' or 'REMOVED'
  final int timestamp;

  WebSocketReactionEvent({
    this.schemaVersion,
    this.eventId,
    this.reactionId,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.eventType,
    required this.timestamp,
  });

  factory WebSocketReactionEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketReactionEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      reactionId: json['reactionId'] as int?,
      messageId: json['messageId'] as int,
      userId: json['userId'] as int,
      emoji: json['emoji'] as String,
      eventType: json['eventType'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

/// WebSocket으로 수신된 읽음 이벤트
class WebSocketReadEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int userId;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;

  WebSocketReadEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.userId,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  factory WebSocketReadEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketReadEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      userId: json['userId'] as int? ?? json['readerId'] as int,
      lastReadMessageId: json['lastReadMessageId'] as int?,
      lastReadAt: json['lastReadAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['lastReadAt'])
          : null,
    );
  }
}

/// WebSocket으로 수신된 채팅방 업데이트 이벤트 (채팅 목록용)
class WebSocketChatRoomUpdateEvent {
  final int? schemaVersion;
  final String? eventId;
  final String? eventType; // NEW_MESSAGE, READ 등
  final int chatRoomId;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int? unreadCount;
  final int? senderId;
  final String? senderNickname;

  WebSocketChatRoomUpdateEvent({
    this.schemaVersion,
    this.eventId,
    this.eventType,
    required this.chatRoomId,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount,
    this.senderId,
    this.senderNickname,
  });

  factory WebSocketChatRoomUpdateEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketChatRoomUpdateEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      eventType: json['eventType'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      lastMessage: json['lastMessage'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? WebSocketChatMessage._parseDateTime(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] as int?,
      senderId: json['senderId'] as int?,
      senderNickname: json['senderNickname'] as String?,
    );
  }
}

/// WebSocket으로 수신된 타이핑 이벤트
class WebSocketTypingEvent {
  final int? schemaVersion;
  final String? eventId;
  final int chatRoomId;
  final int userId;
  final String? userNickname;
  final bool isTyping;

  WebSocketTypingEvent({
    this.schemaVersion,
    this.eventId,
    required this.chatRoomId,
    required this.userId,
    this.userNickname,
    required this.isTyping,
  });

  factory WebSocketTypingEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketTypingEvent(
      schemaVersion: json['schemaVersion'] as int?,
      eventId: json['eventId'] as String?,
      chatRoomId: json['chatRoomId'] as int? ?? json['roomId'] as int,
      userId: json['userId'] as int,
      userNickname: json['userNickname'] as String?,
      isTyping: json['isTyping'] as bool? ?? json['eventType'] == 'TYPING',
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
  final WebSocketPayloadParser _payloadParser;
  final EventDedupeCache _dedupeCache = EventDedupeCache(
    ttl: const Duration(seconds: 15),
    maxSize: 500,
  );

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

  // 읽음 이벤트 스트림
  final _readEventController = StreamController<WebSocketReadEvent>.broadcast();

  // 채팅방 업데이트 스트림 (채팅 목록용)
  final _chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>.broadcast();

  // 타이핑 이벤트 스트림
  final _typingController = StreamController<WebSocketTypingEvent>.broadcast();

  // 사용자 채널 구독 (전역 업데이트용)
  StompUnsubscribe? _chatListSubscription;
  StompUnsubscribe? _readReceiptSubscription;
  int? _subscribedUserId;

  // 재연결 설정
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  Timer? _reconnectTimer;

  WebSocketService(
    this._authLocalDataSource, {
    WebSocketPayloadParser payloadParser = const WebSocketPayloadParser(),
  }) : _payloadParser = payloadParser;

  /// 연결 상태 스트림
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// 현재 연결 상태
  WebSocketConnectionState get currentConnectionState => _connectionState;

  /// 메시지 수신 스트림
  Stream<WebSocketChatMessage> get messages => _messageController.stream;

  /// 리액션 이벤트 스트림
  Stream<WebSocketReactionEvent> get reactions => _reactionController.stream;

  /// 읽음 이벤트 스트림
  Stream<WebSocketReadEvent> get readEvents => _readEventController.stream;

  /// 채팅방 업데이트 스트림 (채팅 목록용)
  Stream<WebSocketChatRoomUpdateEvent> get chatRoomUpdates => _chatRoomUpdateController.stream;

  /// 타이핑 이벤트 스트림
  Stream<WebSocketTypingEvent> get typingEvents => _typingController.stream;

  /// 연결 여부
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// WebSocket 연결
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      // ignore: avoid_print
      print('[WebSocket] Already connecting or connected, skipping');
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);

    final accessToken = await _authLocalDataSource.getAccessToken();
    if (accessToken == null) {
      // ignore: avoid_print
      print('[WebSocket] No access token, cannot connect');
      _updateConnectionState(WebSocketConnectionState.disconnected);
      return;
    }

    // 전역 사용자 채널(채팅 목록/읽음 영수증)은 앱이 살아있는 동안 항상 유지되어야 한다.
    // ChatList 화면 진입 여부와 무관하게, 연결 시점에 userId가 있으면 자동으로 구독을 복원한다.
    // (이미 외부에서 subscribeToUserChannel을 호출해 _subscribedUserId가 세팅된 경우는 그대로 유지)
    _subscribedUserId ??= await _authLocalDataSource.getUserId();

    final wsUrl = ApiConstants.wsBaseUrl;
    // ignore: avoid_print
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
        // ignore: avoid_print
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

    // 사용자 채널 구독 해제
    _chatListSubscription?.call();
    _chatListSubscription = null;
    _readReceiptSubscription?.call();
    _readReceiptSubscription = null;

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
    if (_stompClient == null) {
      // ignore: avoid_print
      print('[WebSocket] _doSubscribe: _stompClient is null, cannot subscribe');
      return;
    }

    final destination = '/topic/chat/room/$roomId';
    // ignore: avoid_print
    print('[WebSocket] _doSubscribe: Subscribing to $destination');
    // ignore: avoid_print
    print('[WebSocket] _doSubscribe: _stompClient.connected = ${_stompClient!.connected}');

    final messageUnsubscribe = _stompClient!.subscribe(
      destination: destination,
      callback: (frame) {
        // ignore: avoid_print
        print('[WebSocket] CALLBACK INVOKED for $destination');
        // ignore: avoid_print
        print('[WebSocket] Frame command: ${frame.command}');
        // ignore: avoid_print
        print('[WebSocket] Frame headers: ${frame.headers}');
        // ignore: avoid_print
        print('[WebSocket] Frame body length: ${frame.body?.length ?? 0}');
        _handleMessage(frame, roomId);
      },
    );

    // ignore: avoid_print
    print('[WebSocket] _doSubscribe: Subscription registered, unsubscribe function: $messageUnsubscribe');
    _subscriptions[roomId] = messageUnsubscribe;
    _pendingSubscriptions.remove(roomId);
    // ignore: avoid_print
    print('[WebSocket] _doSubscribe: Current subscriptions count: ${_subscriptions.length}');
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(int roomId) {
    // ignore: avoid_print
    print('[WebSocket] Unsubscribing from room $roomId');
    _pendingSubscriptions.remove(roomId);
    final unsubscribe = _subscriptions.remove(roomId);
    unsubscribe?.call();
  }

  /// 사용자 채널 구독 (채팅 목록 실시간 업데이트용)
  void subscribeToUserChannel(int userId) {
    // ignore: avoid_print
    print('[WebSocket] subscribeToUserChannel($userId) - isConnected: $isConnected');

    if (_subscribedUserId == userId && _chatListSubscription != null) {
      // ignore: avoid_print
      print('[WebSocket] Already subscribed to user channel $userId');
      return;
    }

    // 기존 구독 해제
    _chatListSubscription?.call();
    _chatListSubscription = null;
    _readReceiptSubscription?.call();
    _readReceiptSubscription = null;

    if (!isConnected || _stompClient == null) {
      // ignore: avoid_print
      print('[WebSocket] Not connected - will subscribe to user channel on connect');
      _subscribedUserId = userId;
      return;
    }

    _doSubscribeUserChannel(userId);
  }

  void _doSubscribeUserChannel(int userId) {
    if (_stompClient == null) {
      // ignore: avoid_print
      print('[WebSocket] _doSubscribeUserChannel: _stompClient is null');
      return;
    }

    // 채팅 목록 업데이트 채널 구독
    final chatListDestination = '/topic/user/$userId/chat-list';
    // ignore: avoid_print
    print('[WebSocket] Subscribing to chat-list channel: $chatListDestination');

    _chatListSubscription = _stompClient!.subscribe(
      destination: chatListDestination,
      callback: (frame) {
        // ignore: avoid_print
        print('[WebSocket] ✅ Chat-list channel message received');
        _handleChatListMessage(frame);
      },
    );
    // ignore: avoid_print
    print('[WebSocket] ✅ Successfully subscribed to chat-list channel: $chatListDestination');

    // 읽음 영수증 채널 구독
    final readReceiptDestination = '/topic/user/$userId/read-receipt';
    // ignore: avoid_print
    print('[WebSocket] Subscribing to read-receipt channel: $readReceiptDestination');

    _readReceiptSubscription = _stompClient!.subscribe(
      destination: readReceiptDestination,
      callback: (frame) {
        // ignore: avoid_print
        print('[WebSocket] ✅ Read-receipt channel message received');
        _handleReadReceiptMessage(frame);
      },
    );
    // ignore: avoid_print
    print('[WebSocket] ✅ Successfully subscribed to read-receipt channel: $readReceiptDestination');
    // ignore: avoid_print
    print('[WebSocket] ========== User channel subscription completed ==========');
    // ignore: avoid_print
    print('[WebSocket] userId: $userId');
    // ignore: avoid_print
    print('[WebSocket] chat-list destination: $chatListDestination');
    // ignore: avoid_print
    print('[WebSocket] read-receipt destination: $readReceiptDestination');
    // ignore: avoid_print
    print('[WebSocket] =========================================================');

    _subscribedUserId = userId;
  }

  /// 사용자 채널 구독 해제
  void unsubscribeFromUserChannel() {
    // ignore: avoid_print
    print('[WebSocket] Unsubscribing from user channel');
    _chatListSubscription?.call();
    _chatListSubscription = null;
    _readReceiptSubscription?.call();
    _readReceiptSubscription = null;
    _subscribedUserId = null;
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

  /// 타이핑 상태 전송
  void sendTypingStatus({
    required int roomId,
    required int userId,
    required bool isTyping,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/typing',
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
        'isTyping': isTyping,
      }),
    );
  }

  /// 채팅방 presence ping (TTL 갱신용)
  void sendPresencePing({
    required int roomId,
    required int userId,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }
    _stompClient!.send(
      destination: '/app/chat/presence',
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
      }),
    );
  }

  /// 채팅방 presence inactive (TTL 즉시 해제/비활성화)
  void sendPresenceInactive({
    required int roomId,
    required int userId,
  }) {
    if (!isConnected || _stompClient == null) {
      return;
    }
    _stompClient!.send(
      destination: '/app/chat/presence/inactive',
      body: jsonEncode({
        'roomId': roomId,
        'userId': userId,
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

    // 사용자 채널 구독 복원
    if (_subscribedUserId != null) {
      _doSubscribeUserChannel(_subscribedUserId!);
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
      final parsed = _payloadParser.parseRoomPayload(body: frame.body!, roomId: roomId);
      switch (parsed) {
        case ParsedChatMessagePayload(:final message):
          if (_dedupeCache.isDuplicate(message.eventId)) return;
          _messageController.add(message);
          break;
        case ParsedReadPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _readEventController.add(event);
          break;
        case ParsedReactionPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _reactionController.add(event);
          break;
        case ParsedTypingPayload(:final event):
          if (_dedupeCache.isDuplicate(event.eventId)) return;
          _typingController.add(event);
          break;
        case ParsedUnknownPayload(:final raw):
          // ignore: avoid_print
          print('[WebSocket] Unknown message type: $raw');
          break;
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[WebSocket] Error parsing message: $e');
      // ignore: avoid_print
      print('[WebSocket] Stack trace: $stackTrace');
    }
  }

  void _handleChatListMessage(StompFrame frame) {
    // ignore: avoid_print
    print('[WebSocket] _handleChatListMessage called');
    // ignore: avoid_print
    print('[WebSocket] Frame body: ${frame.body}');

    if (frame.body == null) {
      // ignore: avoid_print
      print('[WebSocket] Frame body is null, returning');
      return;
    }

    try {
      // 채팅방 업데이트 이벤트 (NEW_MESSAGE 등)
      final update = _payloadParser.parseChatListPayload(frame.body!);
      if (_dedupeCache.isDuplicate(update.eventId)) return;
      // ignore: avoid_print
      print('[WebSocket] ========== Chat room update received ==========');
      // ignore: avoid_print
      print('[WebSocket] roomId: ${update.chatRoomId}');
      // ignore: avoid_print
      print('[WebSocket] lastMessage: ${update.lastMessage}');
      // ignore: avoid_print
      print('[WebSocket] unreadCount: ${update.unreadCount}');
      // ignore: avoid_print
      print('[WebSocket] senderId: ${update.senderId}');
      // ignore: avoid_print
      print('[WebSocket] lastMessageAt: ${update.lastMessageAt}');
      // ignore: avoid_print
      print('[WebSocket] Raw JSON: $json');
      // ignore: avoid_print
      print('[WebSocket] ===============================================');
      _chatRoomUpdateController.add(update);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[WebSocket] Error parsing chat-list message: $e');
      // ignore: avoid_print
      print('[WebSocket] Stack trace: $stackTrace');
    }
  }

  void _handleReadReceiptMessage(StompFrame frame) {
    // ignore: avoid_print
    print('[WebSocket] _handleReadReceiptMessage called');
    // ignore: avoid_print
    print('[WebSocket] Frame body: ${frame.body}');

    if (frame.body == null) {
      // ignore: avoid_print
      print('[WebSocket] Frame body is null, returning');
      return;
    }

    try {
      final readEvent = _payloadParser.parseReadReceiptPayload(frame.body!);
      if (_dedupeCache.isDuplicate(readEvent.eventId)) return;
      // ignore: avoid_print
      print('[WebSocket] Read event: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
      _readEventController.add(readEvent);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[WebSocket] Error parsing read-receipt message: $e');
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
    _readEventController.close();
    _chatRoomUpdateController.close();
    _typingController.close();
  }
}
