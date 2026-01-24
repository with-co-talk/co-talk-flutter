import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/websocket_service.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;

  StreamSubscription<WebSocketChatMessage>? _messageSubscription;
  StreamSubscription<WebSocketReadEvent>? _readEventSubscription;
  StreamSubscription<WebSocketTypingEvent>? _typingSubscription;
  Timer? _typingDebounceTimer;
  Timer? _presencePingTimer;

  // 중복 READ 이벤트(유저 채널 + 방 채널, 재전송 등)로 인한 double-decrement 방지용
  final Map<String, DateTime> _recentReadEventKeys = {};
  static const Duration _readEventDedupeWindow = Duration(seconds: 10);
  static const int _maxReadEventKeySize = 200;

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
  ) : super(const ChatRoomState()) {
    on<ChatRoomOpened>(_onOpened);
    on<ChatRoomClosed>(_onClosed);
    on<ChatRoomBackgrounded>(_onBackgrounded);
    on<ChatRoomForegrounded>(_onForegrounded);
    on<MessagesLoadMoreRequested>(_onLoadMore);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<MessageDeleted>(_onMessageDeleted);
    on<MessagesReadUpdated>(_onMessagesReadUpdated);
    on<TypingStatusChanged>(_onTypingStatusChanged);
    on<UserStartedTyping>(_onUserStartedTyping);
    on<UserStoppedTyping>(_onUserStoppedTyping);
  }

  Future<void> _onOpened(
    ChatRoomOpened event,
    Emitter<ChatRoomState> emit,
  ) async {
    // ignore: avoid_print
    print('[ChatRoomBloc] _onOpened called with roomId: ${event.roomId}');

    // 현재 사용자 ID 가져오기
    final currentUserId = await _authLocalDataSource.getUserId();

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      currentUserId: currentUserId,
      messages: [],
    ));

    try {
      // 1. 먼저 메시지를 로드 (WebSocket 구독 전)
      // ignore: avoid_print
      print('[ChatRoomBloc] Fetching messages...');
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        event.roomId,
        size: AppConstants.messagePageSize,
      );
      // ignore: avoid_print
      print('[ChatRoomBloc] Fetched ${messages.length} messages');

      // 2. 마지막 메시지 ID 저장 (메시지 손실 방지용)
      final lastMessageId = messages.isNotEmpty ? messages.first.id : null;

      // 3. WebSocket 구독 시작 (메시지 로드 후)
      // ignore: avoid_print
      print('[ChatRoomBloc] Calling _subscribeToWebSocket...');
      _subscribeToWebSocket(event.roomId, lastMessageId: lastMessageId);
      // "읽음 처리"는 foreground(진짜 보고 있을 때) 기준으로 수행한다.
      // 데스크탑에서는 포커스가 없을 수 있으므로 opened 시점에 자동 markAsRead를 하지 않는다.
      if (_isViewingRoom) {
        _startPresencePing();
      }

      // 4. 상태 업데이트
      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));

      // NOTE: opened 시점의 자동 읽음 처리는 제거.
      // (foreground 이벤트에서 markAsRead 수행)
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Error in _onOpened: $e');
      // ignore: avoid_print
      print('[ChatRoomBloc] Stack trace: $stackTrace');
      emit(state.copyWith(
        status: ChatRoomStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  int? _lastKnownMessageId;
  bool _isRoomSubscribed = false;
  bool _isViewingRoom = false;

  void _subscribeToWebSocket(int roomId, {int? lastMessageId}) {
    // ignore: avoid_print
    print('[ChatRoomBloc] _subscribeToWebSocket called with roomId: $roomId, lastMessageId: $lastMessageId');

    // 마지막 메시지 ID 저장 (중복 방지용)
    _lastKnownMessageId = lastMessageId;

    // 기존 구독 해제
    _messageSubscription?.cancel();
    _readEventSubscription?.cancel();

    // WebSocket 채팅방 구독
    _webSocketService.subscribeToChatRoom(roomId);
    _isRoomSubscribed = true;

    // 메시지 수신 리스너 - state.roomId를 사용하여 최신 roomId 확인
    _messageSubscription = _webSocketService.messages.listen((wsMessage) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Received wsMessage: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}, content=${wsMessage.content}');
      // ignore: avoid_print
      print('[ChatRoomBloc] Current state.roomId: ${state.roomId}, wsMessage.chatRoomId: ${wsMessage.chatRoomId}');
      if (state.roomId != null && wsMessage.chatRoomId == state.roomId) {
        // ignore: avoid_print
        print('[ChatRoomBloc] Adding MessageReceived event');
        add(MessageReceived(_convertToMessage(wsMessage)));
      } else {
        // ignore: avoid_print
        print('[ChatRoomBloc] Ignoring message for different room');
      }
    }, onError: (error) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Error in message stream: $error');
    });

    // 읽음 이벤트 리스너 - state.roomId를 사용하여 최신 roomId 확인
    _readEventSubscription = _webSocketService.readEvents.listen((readEvent) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Received readEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
      if (state.roomId != null && readEvent.chatRoomId == state.roomId) {
        add(MessagesReadUpdated(
          userId: readEvent.userId,
          lastReadMessageId: readEvent.lastReadMessageId,
          lastReadAt: readEvent.lastReadAt,
        ));
      }
    }, onError: (error) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Error in read event stream: $error');
    });

    // 타이핑 이벤트 리스너
    _typingSubscription = _webSocketService.typingEvents.listen((typingEvent) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Received typingEvent: roomId=${typingEvent.chatRoomId}, userId=${typingEvent.userId}, isTyping=${typingEvent.isTyping}');
      if (state.roomId != null && typingEvent.chatRoomId == state.roomId) {
        // 본인 타이핑은 무시
        if (typingEvent.userId == state.currentUserId) return;

        add(TypingStatusChanged(
          userId: typingEvent.userId,
          userNickname: typingEvent.userNickname,
          isTyping: typingEvent.isTyping,
        ));
      }
    }, onError: (error) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Error in typing event stream: $error');
    });
  }

  Message _convertToMessage(WebSocketChatMessage wsMessage) {
    return Message(
      id: wsMessage.messageId,
      chatRoomId: wsMessage.chatRoomId,
      senderId: wsMessage.senderId ?? 0,
      content: wsMessage.content,
      type: _parseMessageType(wsMessage.type),
      createdAt: wsMessage.createdAt,
      fileUrl: wsMessage.fileUrl,
      fileName: wsMessage.fileName,
      fileSize: wsMessage.fileSize,
      fileContentType: wsMessage.fileContentType,
      thumbnailUrl: wsMessage.thumbnailUrl,
      unreadCount: wsMessage.unreadCount,
    );
  }

  MessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    // WebSocket 구독 해제
    if (state.roomId != null) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    _isRoomSubscribed = false;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _readEventSubscription?.cancel();
    _readEventSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    _presencePingTimer?.cancel();
    _presencePingTimer = null;

    emit(const ChatRoomState());
  }

  void _onBackgrounded(
    ChatRoomBackgrounded event,
    Emitter<ChatRoomState> emit,
  ) {
    // 카톡/라인 스타일:
    // - 포커스가 없어도 메시지 수신은 유지(구독 유지)해서 유실을 방지한다.
    // - 대신 presence/읽음만 inactive로 전환해 "읽음"이 발생하지 않게 한다.
    if (state.roomId == null || state.currentUserId == null || !_isRoomSubscribed) return;
    _isViewingRoom = false;
    _stopPresencePing();
    _webSocketService.sendPresenceInactive(
      roomId: state.roomId!,
      userId: state.currentUserId!,
    );
  }

  Future<void> _onForegrounded(
    ChatRoomForegrounded event,
    Emitter<ChatRoomState> emit,
  ) async {
    // 다시 활성화되면 presence ping을 재개하고, 화면에 보이는 상태이므로 읽음 처리를 다시 시도한다.
    if (state.roomId == null || state.currentUserId == null || !_isRoomSubscribed) return;
    _isViewingRoom = true;
    _startPresencePing();

    await _markAsReadWithRetry(state.roomId!, emit);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _readEventSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    _presencePingTimer?.cancel();
    // 이미 background/closed 처리로 구독 해제된 경우 중복 unsubscribe 방지
    if (state.roomId != null && _isRoomSubscribed) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    return super.close();
  }

  void _startPresencePing() {
    _stopPresencePing();
    final roomId = state.roomId;
    final userId = state.currentUserId;
    if (roomId == null || userId == null) return;

    // 방을 "보고 있는 동안" 주기적으로 TTL 갱신
    _webSocketService.sendPresencePing(roomId: roomId, userId: userId);
    _presencePingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (state.roomId == null || state.currentUserId == null) return;
      _webSocketService.sendPresencePing(
        roomId: state.roomId!,
        userId: state.currentUserId!,
      );
    });
  }

  void _stopPresencePing() {
    _presencePingTimer?.cancel();
    _presencePingTimer = null;
  }

  Future<void> _onLoadMore(
    MessagesLoadMoreRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (!state.hasMore || state.nextCursor == null || state.roomId == null) {
      return;
    }

    try {
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        state.roomId!,
        size: AppConstants.messagePageSize,
        beforeMessageId: state.nextCursor,
      );

      emit(state.copyWith(
        messages: [...state.messages, ...messages],
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null) return;

    emit(state.copyWith(isSending: true));

    try {
      final userId = await _authLocalDataSource.getUserId();
      if (userId == null) {
        emit(state.copyWith(
          isSending: false,
          errorMessage: '사용자 정보를 찾을 수 없습니다.',
        ));
        return;
      }

      // WebSocket STOMP로 메시지 전송
      // ignore: avoid_print
      print('[ChatRoomBloc] ========== Sending message ==========');
      // ignore: avoid_print
      print('[ChatRoomBloc] roomId: ${state.roomId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] senderId: $userId');
      // ignore: avoid_print
      print('[ChatRoomBloc] content: ${event.content}');
      // ignore: avoid_print
      print('[ChatRoomBloc] =====================================');
      _webSocketService.sendMessage(
        roomId: state.roomId!,
        senderId: userId,
        content: event.content,
      );

      // 메시지는 WebSocket broadcast로 수신됨 (MessageReceived 이벤트)
      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatRoomState> emit,
  ) async {
    // ignore: avoid_print
    print('[ChatRoomBloc] _onMessageReceived called');
    // ignore: avoid_print
    print('[ChatRoomBloc] state.roomId: ${state.roomId}, event.message.chatRoomId: ${event.message.chatRoomId}');

    if (state.roomId != event.message.chatRoomId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Room ID mismatch, ignoring');
      return;
    }

    // Avoid duplicate messages (이미 로드된 메시지 또는 구독 전 메시지)
    if (state.messages.any((m) => m.id == event.message.id)) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Duplicate message (already in state), ignoring');
      return;
    }

    // 구독 시작 전 메시지는 무시 (메시지 손실 방지 로직)
    if (_lastKnownMessageId != null && event.message.id <= _lastKnownMessageId!) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Message ID ${event.message.id} <= lastKnownMessageId $_lastKnownMessageId, ignoring');
      return;
    }

    // ignore: avoid_print
    print('[ChatRoomBloc] Adding message to state: ${event.message.content}');
    emit(state.copyWith(
      messages: [event.message, ...state.messages],
    ));
    // ignore: avoid_print
    print('[ChatRoomBloc] State updated, total messages: ${state.messages.length + 1}');

    // 채팅방이 열려있을 때 상대방이 보낸 메시지를 받으면 즉시 읽음 처리
    // (채팅방이 열려있다는 것은 사용자가 보고 있다는 의미이므로)
    // 읽음 처리가 완료되면 isReadMarked 상태가 변경되어 ChatRoomPage의 BlocListener가
    // ChatListBloc에 알려서 unreadCount를 0으로 업데이트함
    if (_isViewingRoom &&
        state.currentUserId != null &&
        event.message.senderId != state.currentUserId &&
        state.roomId != null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Auto marking as read for message from other user (room is open)');
      // 읽음 처리 완료를 기다림 (성공하면 isReadMarked = true로 상태 업데이트)
      await _markAsReadWithRetry(state.roomId!, emit);
    }
  }

  /// 읽음 처리를 재시도 로직과 함께 실행합니다.
  /// 서버에서 읽음 처리를 완료하면 chatRoomUpdates로 업데이트된 unreadCount를 전송하므로
  /// 클라이언트는 별도로 상태를 업데이트할 필요 없음
  Future<void> _markAsReadWithRetry(
    int roomId,
    Emitter<ChatRoomState> emit, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    // ignore: avoid_print
    print('[ChatRoomBloc] ========== Starting markAsRead ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] roomId: $roomId');
    // ignore: avoid_print
    print('[ChatRoomBloc] =========================================');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // ignore: avoid_print
        print('[ChatRoomBloc] markAsRead attempt $attempt/$maxRetries');
        await _chatRepository.markAsRead(roomId);
        // ignore: avoid_print
        print('[ChatRoomBloc] ✅ markAsRead succeeded on attempt $attempt');
        // 읽음 처리 성공을 상태로 표시 (테스트 및 UI 동기화용)
        emit(state.copyWith(isReadMarked: true));
        // ignore: avoid_print
        print('[ChatRoomBloc] Waiting for server to send chatRoomUpdates with updated unreadCount...');
        // 서버가 읽음 처리 완료 후 chatRoomUpdates로 업데이트된 unreadCount를 전송하므로
        // 클라이언트는 별도로 상태를 업데이트할 필요 없음
        return;
      } catch (e) {
        // ignore: avoid_print
        print('[ChatRoomBloc] markAsRead failed on attempt $attempt: $e');
        if (attempt < maxRetries) {
          // 재시도 전 대기 (exponential backoff)
          await Future.delayed(retryDelay * attempt);
        }
      }
    }
    // 모든 재시도 실패 - 조용히 무시 (UX에 큰 영향 없음)
    // ignore: avoid_print
    print('[ChatRoomBloc] markAsRead failed after $maxRetries attempts');
  }

  Future<void> _onMessageDeleted(
    MessageDeleted event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);

      final updatedMessages = state.messages.map((m) {
        if (m.id == event.messageId) {
          return m.copyWith(isDeleted: true);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onMessagesReadUpdated(
    MessagesReadUpdated event,
    Emitter<ChatRoomState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatRoomBloc] _onMessagesReadUpdated: userId=${event.userId}, lastReadMessageId=${event.lastReadMessageId}, lastReadAt=${event.lastReadAt}');

    // 내가 읽은 이벤트인 경우 무시 (상대방이 읽어야 내 메시지의 unreadCount가 감소)
    if (event.userId == state.currentUserId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Ignoring read event from myself');
      return;
    }

    // 중복 이벤트 제거 (같은 reader, 같은 범위(lastReadMessageId/lastReadAt)면 한 번만 처리)
    if (_isDuplicateReadEvent(event)) {
      return;
    }

    // 내 메시지의 unreadCount만 1씩 감소 (상대방이 읽었으므로)
    // 우선순위:
    // 1) lastReadMessageId가 있으면 해당 메시지까지만
    // 2) 없고 lastReadAt이 있으면 createdAt <= lastReadAt 인 메시지까지만
    // 3) 둘 다 없으면 모든 메시지
    final updatedMessages = state.messages.map((m) {
      // 내가 보낸 메시지만 처리
      if (m.senderId != state.currentUserId) return m;

      final bool shouldUpdate;
      if (event.lastReadMessageId != null) {
        shouldUpdate = m.id <= event.lastReadMessageId!;
      } else if (event.lastReadAt != null) {
        // createdAt <= lastReadAt
        shouldUpdate = !m.createdAt.isAfter(event.lastReadAt!);
      } else {
        shouldUpdate = true;
      }

      if (shouldUpdate && m.unreadCount > 0) {
        return m.copyWith(unreadCount: m.unreadCount - 1);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
  }

  bool _isDuplicateReadEvent(MessagesReadUpdated event) {
    final roomId = state.roomId;
    if (roomId == null) return false;

    final key = '$roomId:${event.userId}:${event.lastReadMessageId ?? ''}:${event.lastReadAt?.millisecondsSinceEpoch ?? ''}';
    final now = DateTime.now();

    // purge old
    _recentReadEventKeys.removeWhere((_, ts) => now.difference(ts) > _readEventDedupeWindow);

    final lastSeen = _recentReadEventKeys[key];
    if (lastSeen != null) {
      return true;
    }

    // size bound (간단 LRU: 가장 오래된 것부터 제거)
    if (_recentReadEventKeys.length >= _maxReadEventKeySize) {
      final oldestKey = _recentReadEventKeys.entries.reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
      _recentReadEventKeys.remove(oldestKey);
    }

    _recentReadEventKeys[key] = now;
    return false;
  }

  void _onTypingStatusChanged(
    TypingStatusChanged event,
    Emitter<ChatRoomState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatRoomBloc] _onTypingStatusChanged: userId=${event.userId}, isTyping=${event.isTyping}');

    final updatedTypingUsers = Map<int, String>.from(state.typingUsers);

    if (event.isTyping) {
      updatedTypingUsers[event.userId] = event.userNickname ?? '상대방';
    } else {
      updatedTypingUsers.remove(event.userId);
    }

    emit(state.copyWith(typingUsers: updatedTypingUsers));
  }

  void _onUserStartedTyping(
    UserStartedTyping event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId == null || state.currentUserId == null) return;

    // ignore: avoid_print
    print('[ChatRoomBloc] _onUserStartedTyping: sending typing status');

    _webSocketService.sendTypingStatus(
      roomId: state.roomId!,
      userId: state.currentUserId!,
      isTyping: true,
    );

    // 3초 후 자동으로 타이핑 중단
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
      add(const UserStoppedTyping());
    });
  }

  void _onUserStoppedTyping(
    UserStoppedTyping event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId == null || state.currentUserId == null) return;

    // ignore: avoid_print
    print('[ChatRoomBloc] _onUserStoppedTyping: sending stop typing status');

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    _webSocketService.sendTypingStatus(
      roomId: state.roomId!,
      userId: state.currentUserId!,
      isTyping: false,
    );
  }
}
