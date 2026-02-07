import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/active_room_tracker.dart';
import '../../../core/services/desktop_notification_bridge.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';
import 'managers/managers.dart';

const _uuid = Uuid();

@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;
  final DesktopNotificationBridge _desktopNotificationBridge;
  final ActiveRoomTracker _activeRoomTracker;

  // Managers
  late final WebSocketSubscriptionManager _subscriptionManager;
  late final PresenceManager _presenceManager;
  late final MessageCacheManager _cacheManager;
  late final MessageHandler _messageHandler;

  // State tracking
  bool _roomInitialized = false;
  bool _pendingForegrounded = false;

  // Pending message timeout timer
  Timer? _pendingTimeoutTimer;
  static const _pendingTimeoutCheckInterval = Duration(seconds: 10);
  static const _pendingMessageTimeout = Duration(seconds: 30);

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
    this._desktopNotificationBridge,
    this._activeRoomTracker,
  ) : super(const ChatRoomState()) {
    // Initialize managers
    _subscriptionManager = WebSocketSubscriptionManager(_webSocketService);
    _presenceManager = PresenceManager(_webSocketService);
    _cacheManager = MessageCacheManager(_chatRepository);
    _messageHandler = MessageHandler(
      _chatRepository,
      _webSocketService,
      _authLocalDataSource,
    );

    // Register event handlers
    on<ChatRoomOpened>(_onOpened);
    on<ChatRoomClosed>(_onClosed);
    on<ChatRoomBackgrounded>(_onBackgrounded);
    on<ChatRoomForegrounded>(_onForegrounded);
    on<MessagesLoadMoreRequested>(_onLoadMore);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<MessageDeleted>(_onMessageDeleted);
    on<MessageDeletedByOther>(_onMessageDeletedByOther);
    on<MessagesReadUpdated>(_onMessagesReadUpdated);
    on<TypingStatusChanged>(_onTypingStatusChanged);
    on<UserStartedTyping>(_onUserStartedTyping);
    on<UserStoppedTyping>(_onUserStoppedTyping);
    on<MessageUpdateRequested>(_onMessageUpdateRequested);
    on<ChatRoomLeaveRequested>(_onLeaveRequested);
    on<ReinviteUserRequested>(_onReinviteUserRequested);
    on<OtherUserLeftStatusChanged>(_onOtherUserLeftStatusChanged);
    on<FileAttachmentRequested>(_onFileAttachmentRequested);
    on<MessageRetryRequested>(_onMessageRetryRequested);
    on<PendingMessageDeleteRequested>(_onPendingMessageDeleteRequested);
    on<PendingMessagesTimeoutChecked>(_onPendingMessagesTimeoutChecked);
    on<ChatRoomRefreshRequested>(_onRefreshRequested);
    on<ReactionAddRequested>(_onReactionAddRequested);
    on<ReactionRemoveRequested>(_onReactionRemoveRequested);
    on<ReactionEventReceived>(_onReactionEventReceived);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ChatRoomBloc] $message');
    }
  }

  Future<void> _onOpened(
    ChatRoomOpened event,
    Emitter<ChatRoomState> emit,
  ) async {
    _log('_onOpened: roomId=${event.roomId}');

    _roomInitialized = false;
    _pendingForegrounded = false;

    // Clear stale cache from previously opened room to prevent old lastMessageId
    // from filtering new room's messages in shouldFilterMessage()
    _cacheManager.clearCache();

    final currentUserId = await _authLocalDataSource.getUserId();

    // Set active room for notification suppression
    _desktopNotificationBridge.setActiveRoomId(event.roomId);
    _activeRoomTracker.activeRoomId = event.roomId;

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      currentUserId: currentUserId,
      messages: [],
      isOfflineData: false,
    ));

    // 1. Load cached messages first (fast initial display)
    final cachedMessages = await _cacheManager.loadCachedMessages(event.roomId);
    if (cachedMessages.isNotEmpty) {
      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: cachedMessages,
        hasMore: _cacheManager.hasMore,
        isOfflineData: true,
      ));
    }

    // 2. Sync with server
    try {
      bool isOtherUserLeft = false;
      int? otherUserId;
      String? otherUserNickname;
      try {
        final chatRoom = await _chatRepository.getChatRoom(event.roomId);
        isOtherUserLeft = chatRoom.isOtherUserLeft;
        otherUserId = chatRoom.otherUserId;
        otherUserNickname = chatRoom.otherUserNickname;
      } catch (e) {
        _log('getChatRoom failed: $e');
      }

      await _cacheManager.loadMessagesFromServer(event.roomId);
      _log('Fetched ${_cacheManager.messages.length} messages from server');

      await _subscribeToWebSocket(event.roomId);

      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: _cacheManager.messages,
        nextCursor: _cacheManager.nextCursor,
        hasMore: _cacheManager.hasMore,
        isOtherUserLeft: isOtherUserLeft,
        otherUserId: otherUserId,
        otherUserNickname: otherUserNickname,
        isOfflineData: false,
      ));

      _roomInitialized = true;

      // Start pending message timeout checker
      _startPendingTimeoutChecker();

      if (_pendingForegrounded) {
        _log('Processing pending foreground event');
        _pendingForegrounded = false;
        if (state.currentUserId != null) {
          _presenceManager.sendPresenceActive(event.roomId, state.currentUserId!);
          await _messageHandler.markAsRead(event.roomId);
          emit(state.copyWith(isReadMarked: true));
        }
      } else if (state.currentUserId != null && !_presenceManager.isViewingRoom) {
        // Not viewing room, send inactive presence
        _log('Sending presenceInactive (not viewing room)');
        _presenceManager.sendPresenceInactive(event.roomId, state.currentUserId!);
      }
    } catch (e, stackTrace) {
      _log('Error in _onOpened: $e\n$stackTrace');

      // Offline mode: keep cached messages if available
      if (state.messages.isNotEmpty) {
        _log('Keeping cached messages due to network error');
        _roomInitialized = true;
        emit(state.copyWith(isOfflineData: true));
      } else {
        emit(state.copyWith(
          status: ChatRoomStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _subscribeToWebSocket(int roomId) async {
    final isConnected = _webSocketService.isConnected;
    final lastMessageId = _cacheManager.lastMessageId;
    _log('_subscribeToWebSocket: roomId=$roomId, isConnected=$isConnected, lastMessageId=$lastMessageId');

    // Ensure WebSocket is connected before subscribing
    if (!isConnected) {
      _log('_subscribeToWebSocket: WebSocket not connected, attempting to connect...');
      final connected = await _webSocketService.ensureConnected(
        timeout: const Duration(seconds: 10),
      );
      if (!connected) {
        _log('_subscribeToWebSocket: Failed to connect WebSocket');
        // Continue anyway - subscription will work when connection is restored
      } else {
        _log('_subscribeToWebSocket: WebSocket connected successfully');
      }
    }

    _subscriptionManager.subscribeToRoom(
      roomId,
      lastMessageId: lastMessageId,
      onMessage: (wsMessage) {
        _log('WebSocket message received: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}, senderId=${wsMessage.senderId}, eventType=${wsMessage.eventType}');

        if (state.roomId != null && wsMessage.chatRoomId == state.roomId) {
          _log('WebSocket message matches current room, adding MessageReceived event');
          add(MessageReceived(_subscriptionManager.convertToMessage(wsMessage)));

          if (wsMessage.eventType == 'USER_LEFT') {
            _log('USER_LEFT event: relatedUserId=${wsMessage.relatedUserId}');
            add(OtherUserLeftStatusChanged(
              isOtherUserLeft: true,
              relatedUserId: wsMessage.relatedUserId,
              relatedUserNickname: wsMessage.relatedUserNickname,
            ));
          } else if (wsMessage.eventType == 'USER_JOINED') {
            _log('USER_JOINED event: relatedUserId=${wsMessage.relatedUserId}');
            add(OtherUserLeftStatusChanged(
              isOtherUserLeft: false,
              relatedUserId: wsMessage.relatedUserId,
              relatedUserNickname: wsMessage.relatedUserNickname,
            ));
          }
        } else {
          _log('WebSocket message IGNORED: state.roomId=${state.roomId}, wsMessage.chatRoomId=${wsMessage.chatRoomId}');
        }
      },
      onReadEvent: (readEvent) {
        _log('ReadEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');

        if (state.roomId != null && readEvent.chatRoomId == state.roomId) {
          add(MessagesReadUpdated(
            userId: readEvent.userId,
            lastReadMessageId: readEvent.lastReadMessageId,
            lastReadAt: readEvent.lastReadAt,
          ));
        }
      },
      onTypingEvent: (typingEvent) {
        if (state.roomId != null && typingEvent.chatRoomId == state.roomId) {
          if (typingEvent.userId == state.currentUserId) return;

          add(TypingStatusChanged(
            userId: typingEvent.userId,
            userNickname: typingEvent.userNickname,
            isTyping: typingEvent.isTyping,
          ));
        }
      },
      onMessageDeleted: (deletedEvent) {
        _log('WebSocket message deleted: messageId=${deletedEvent.messageId}');

        if (state.roomId != null && deletedEvent.chatRoomId == state.roomId) {
          add(MessageDeletedByOther(deletedEvent.messageId));
        }
      },
      onReactionEvent: (reactionEvent) {
        _log('WebSocket reaction: messageId=${reactionEvent.messageId}, userId=${reactionEvent.userId}, emoji=${reactionEvent.emoji}, type=${reactionEvent.eventType}');

        add(ReactionEventReceived(
          messageId: reactionEvent.messageId,
          userId: reactionEvent.userId,
          emoji: reactionEvent.emoji,
          isAdd: reactionEvent.eventType == 'REACTION_ADDED',
          reactionId: reactionEvent.reactionId,
        ));
      },
    );
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId != null) {
      _subscriptionManager.unsubscribeFromRoom(state.roomId!);
    }
    _presenceManager.dispose();
    _stopPendingTimeoutChecker();
    _roomInitialized = false;
    _pendingForegrounded = false;

    // Release notification suppression
    _desktopNotificationBridge.setActiveRoomId(null);
    _activeRoomTracker.activeRoomId = null;

    emit(const ChatRoomState());
  }

  void _startPendingTimeoutChecker() {
    _stopPendingTimeoutChecker();
    _pendingTimeoutTimer = Timer.periodic(_pendingTimeoutCheckInterval, (_) {
      _checkPendingMessageTimeouts();
    });
  }

  void _stopPendingTimeoutChecker() {
    _pendingTimeoutTimer?.cancel();
    _pendingTimeoutTimer = null;
  }

  void _checkPendingMessageTimeouts() {
    if (_cacheManager.pendingMessages.isEmpty) return;
    add(const PendingMessagesTimeoutChecked());
  }

  void _onPendingMessagesTimeoutChecked(
    PendingMessagesTimeoutChecked event,
    Emitter<ChatRoomState> emit,
  ) {
    final timedOutIds = _cacheManager.timeoutPendingMessages(timeout: _pendingMessageTimeout);
    if (timedOutIds.isNotEmpty) {
      _log('Pending messages timed out: $timedOutIds');
      emit(state.copyWith(messages: _cacheManager.messages));
    }
  }

  Future<void> _onRefreshRequested(
    ChatRoomRefreshRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null) return;
    _log('_onRefreshRequested: performing gap recovery for room ${state.roomId}');

    final hasNewMessages = await _cacheManager.refreshFromServer(state.roomId!);
    if (hasNewMessages) {
      final latestId = _cacheManager.lastMessageId;
      if (latestId != null) {
        _subscriptionManager.updateLastKnownMessageId(latestId);
      }
      emit(state.copyWith(
        messages: _cacheManager.messages,
        nextCursor: _cacheManager.nextCursor,
        hasMore: _cacheManager.hasMore,
        isOfflineData: false,
      ));
    }

    if (state.currentUserId != null && _presenceManager.isViewingRoom) {
      await _messageHandler.markAsRead(state.roomId!);
      emit(state.copyWith(isReadMarked: true));
    }
  }

  void _onBackgrounded(
    ChatRoomBackgrounded event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onBackgrounded: roomId=${state.roomId}, initialized=$_roomInitialized');

    // Cancel pending foregrounded event if backgrounded before initialization
    if (_pendingForegrounded) {
      _log('Cancelling pending foregrounded event');
      _pendingForegrounded = false;
    }

    if (state.roomId == null || state.currentUserId == null || !_subscriptionManager.isRoomSubscribed) {
      return;
    }

    _presenceManager.sendPresenceInactive(state.roomId!, state.currentUserId!);

    // Only disconnect WebSocket on mobile (Android/iOS).
    // On desktop, window unfocus triggers this event but we should keep the
    // connection alive — only pause presence pings.
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (isMobile) {
      _webSocketService.disconnect();
      _log('_onBackgrounded: WebSocket disconnected (mobile)');
    } else {
      _log('_onBackgrounded: presenceInactive only (desktop)');
    }
  }

  Future<void> _onForegrounded(
    ChatRoomForegrounded event,
    Emitter<ChatRoomState> emit,
  ) async {
    _log('_onForegrounded: roomId=${state.roomId}, initialized=$_roomInitialized');

    if (!_roomInitialized) {
      _pendingForegrounded = true;
      return;
    }

    if (state.roomId == null || state.currentUserId == null) return;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      // Mobile: full reconnect + gap recovery (WebSocket was disconnected on background)
      // 1. Reset reconnect attempts for a fresh reconnection sequence
      _webSocketService.resetReconnectAttempts();

      // 2. Reconnect WebSocket
      _log('_onForegrounded: reconnecting WebSocket (mobile)...');
      final connected = await _webSocketService.ensureConnected(
        timeout: const Duration(seconds: 10),
      );

      if (connected) {
        _log('_onForegrounded: WebSocket reconnected, resubscribing to room');
        // 3. Resubscribe to ensure we receive messages
        await _subscribeToWebSocket(state.roomId!);
      } else {
        _log('_onForegrounded: Failed to reconnect WebSocket');
      }

      // 4. Gap recovery: fetch latest messages from server and merge with cache
      _log('_onForegrounded: performing gap recovery...');
      final hasNewMessages = await _cacheManager.refreshFromServer(state.roomId!);
      if (hasNewMessages) {
        _log('_onForegrounded: new messages found during gap recovery');
        final latestId = _cacheManager.lastMessageId;
        if (latestId != null) {
          _subscriptionManager.updateLastKnownMessageId(latestId);
        }
      }
    } else {
      // Desktop: WebSocket stayed connected, just resume presence
      _log('_onForegrounded: resuming presence (desktop)');
    }

    // Presence active + mark as read (both mobile and desktop)
    _presenceManager.sendPresenceActive(state.roomId!, state.currentUserId!);
    await _messageHandler.markAsRead(state.roomId!);

    // Emit updated state
    emit(state.copyWith(
      messages: _cacheManager.messages,
      nextCursor: _cacheManager.nextCursor,
      hasMore: _cacheManager.hasMore,
      isReadMarked: true,
      isOfflineData: false,
    ));
  }

  @override
  Future<void> close() {
    _stopPendingTimeoutChecker();
    if (state.roomId != null && _subscriptionManager.isRoomSubscribed) {
      _subscriptionManager.unsubscribeFromRoom(state.roomId!);
    }
    _subscriptionManager.dispose();
    _presenceManager.dispose();
    return super.close();
  }

  Future<void> _onLoadMore(
    MessagesLoadMoreRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isLoadingMore) {
      _log('_onLoadMore: Already loading, skipping');
      return;
    }

    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(
        state.messages,
        nextCursor: state.nextCursor,
        hasMore: state.hasMore,
      );
    }

    if (!_cacheManager.hasMore || _cacheManager.nextCursor == null || state.roomId == null) {
      return;
    }

    // 로딩 시작
    emit(state.copyWith(isLoadingMore: true));

    try {
      final messages = await _cacheManager.loadMoreMessages(state.roomId!);
      emit(state.copyWith(
        messages: messages,
        nextCursor: _cacheManager.nextCursor,
        hasMore: _cacheManager.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        isLoadingMore: false,
      ));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null || state.currentUserId == null) return;

    // 1. 낙관적 UI: 즉시 pending 메시지를 화면에 추가
    final localId = _uuid.v4();
    final pendingMessage = Message(
      id: -DateTime.now().millisecondsSinceEpoch, // 임시 음수 ID
      chatRoomId: state.roomId!,
      senderId: state.currentUserId!,
      content: event.content,
      createdAt: DateTime.now(),
      sendStatus: MessageSendStatus.pending,
      localId: localId,
    );

    _log('_onMessageSent: Adding pending message (localId=$localId)');
    _cacheManager.addPendingMessage(pendingMessage);
    emit(state.copyWith(messages: _cacheManager.messages));

    // 2. 실제 전송 시도
    try {
      await _messageHandler.sendMessage(
        roomId: state.roomId!,
        content: event.content,
        userId: state.currentUserId,
      );
      _log('_onMessageSent: Message sent successfully (localId=$localId)');
      // 전송 성공 시 WebSocket으로 메시지가 돌아오면 _onMessageReceived에서 처리
    } catch (e) {
      _log('_onMessageSent: Message send failed (localId=$localId): $e');
      // 3. 전송 실패 시 메시지 상태를 failed로 변경
      _cacheManager.updatePendingMessageStatus(localId, MessageSendStatus.failed);
      emit(state.copyWith(
        messages: _cacheManager.messages,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatRoomState> emit,
  ) async {
    _log('_onMessageReceived: id=${event.message.id}, roomId=${event.message.chatRoomId}, senderId=${event.message.senderId}, unreadCount=${event.message.unreadCount}');

    if (state.roomId != event.message.chatRoomId) {
      _log('_onMessageReceived: SKIPPED - roomId mismatch (state.roomId=${state.roomId}, event.chatRoomId=${event.message.chatRoomId})');
      return;
    }

    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    // Filter duplicate messages based on last known ID
    if (_subscriptionManager.shouldFilterMessage(event.message.id)) {
      _log('_onMessageReceived: FILTERED - message id ${event.message.id} <= lastKnownMessageId ${_subscriptionManager.lastKnownMessageId}');
      return;
    }

    // 내가 보낸 메시지가 서버에서 돌아온 경우: pending 메시지를 찾아서 교체
    if (event.message.senderId == state.currentUserId) {
      final replaced = _cacheManager.replacePendingMessageWithReal(
        event.message.content,
        event.message,
      );
      if (replaced) {
        _log('_onMessageReceived: Replaced pending message with real message (id=${event.message.id})');
        emit(state.copyWith(
          messages: _cacheManager.messages,
          isOfflineData: false,
        ));
        return;
      }
    }

    // 일반 메시지 추가
    _cacheManager.addMessage(event.message);
    _log('_onMessageReceived: Added message, total messages: ${_cacheManager.messages.length}');

    emit(state.copyWith(
      messages: _cacheManager.messages,
      isOfflineData: false,
    ));
    _log('_onMessageReceived: State emitted with ${state.messages.length} messages');

    if (_presenceManager.isViewingRoom &&
        state.currentUserId != null &&
        event.message.senderId != state.currentUserId &&
        state.roomId != null) {
      // Fire-and-forget: don't await markAsRead to avoid blocking the BLoC event queue.
      // This prevents MessageSent events from being delayed behind slow HTTP calls.
      _messageHandler.markAsRead(state.roomId!);
    }
  }

  Future<void> _onMessageDeleted(
    MessageDeleted event,
    Emitter<ChatRoomState> emit,
  ) async {
    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    try {
      await _messageHandler.deleteMessage(event.messageId);
      _cacheManager.markMessageAsDeleted(event.messageId);

      emit(state.copyWith(messages: _cacheManager.messages));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onMessageDeletedByOther(
    MessageDeletedByOther event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onMessageDeletedByOther: messageId=${event.messageId}');
    _cacheManager.markMessageAsDeleted(event.messageId);
    emit(state.copyWith(messages: _cacheManager.messages));
  }

  void _onMessagesReadUpdated(
    MessagesReadUpdated event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onMessagesReadUpdated: userId=${event.userId}, lastReadMessageId=${event.lastReadMessageId}, lastReadAt=${event.lastReadAt}');

    if (state.currentUserId == null) return;
    // 내가 읽은 이벤트는 무시
    if (event.userId == state.currentUserId) return;

    // 중복 읽음 이벤트 방지: (userId, lastReadMessageId) 또는 (userId, lastReadAt) 조합으로 체크
    final eventKey = '${event.userId}_${event.lastReadMessageId ?? event.lastReadAt?.millisecondsSinceEpoch ?? 'all'}';
    if (state.processedReadEvents.contains(eventKey)) {
      _log('_onMessagesReadUpdated: Duplicate read event ignored: $eventKey');
      return;
    }

    // 메시지 업데이트 함수
    Message updateMessageReadCount(Message message) {
      // 내가 보낸 메시지만 업데이트
      if (message.senderId != state.currentUserId) return message;
      // 이미 0이면 더 감소하지 않음
      if (message.unreadCount <= 0) return message;

      // 1. lastReadMessageId가 있으면 해당 ID 이하 메시지만 업데이트
      if (event.lastReadMessageId != null) {
        if (message.id <= event.lastReadMessageId!) {
          return message.copyWith(unreadCount: message.unreadCount - 1);
        }
        return message;
      }

      // 2. lastReadMessageId가 없고 lastReadAt이 있으면 해당 시간 이전 메시지만 업데이트
      if (event.lastReadAt != null) {
        if (!message.createdAt.isAfter(event.lastReadAt!)) {
          return message.copyWith(unreadCount: message.unreadCount - 1);
        }
        return message;
      }

      // 3. 둘 다 없으면 모든 메시지를 읽음 처리
      return message.copyWith(unreadCount: message.unreadCount - 1);
    }

    // Use state.messages directly to handle seed state in tests
    final updatedMessages = state.messages.map(updateMessageReadCount).toList();

    // 실제로 변경된 메시지가 있는지 확인
    bool hasChanges = false;
    for (int i = 0; i < state.messages.length; i++) {
      if (state.messages[i].unreadCount != updatedMessages[i].unreadCount) {
        hasChanges = true;
        break;
      }
    }

    // 변경된 메시지가 없으면 상태 업데이트 하지 않음
    if (!hasChanges) {
      _log('_onMessagesReadUpdated: No messages updated, skipping state emit');
      return;
    }

    // Also update cache manager for consistency
    _cacheManager.updateMessages(updateMessageReadCount);

    // 처리된 이벤트 기록
    var newProcessedEvents = Set<String>.from(state.processedReadEvents)..add(eventKey);
    // Cap the set to prevent unbounded growth
    if (newProcessedEvents.length > 500) {
      // Keep only the most recent entries by taking the last 250
      newProcessedEvents = newProcessedEvents.toList().sublist(newProcessedEvents.length - 250).toSet();
    }

    emit(state.copyWith(
      messages: updatedMessages,
      processedReadEvents: newProcessedEvents,
    ));
  }

  void _onTypingStatusChanged(
    TypingStatusChanged event,
    Emitter<ChatRoomState> emit,
  ) {
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

    _presenceManager.handleUserStartedTyping(
      roomId: state.roomId!,
      userId: state.currentUserId!,
      onStopTyping: () {
        add(const UserStoppedTyping());
      },
    );
  }

  void _onUserStoppedTyping(
    UserStoppedTyping event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId == null || state.currentUserId == null) return;

    _presenceManager.handleUserStoppedTyping(
      roomId: state.roomId!,
      userId: state.currentUserId!,
    );
  }

  Future<void> _onMessageUpdateRequested(
    MessageUpdateRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    try {
      final updatedMessage = await _messageHandler.updateMessage(
        messageId: event.messageId,
        content: event.content,
      );

      _cacheManager.updateMessage(
        event.messageId,
        (m) => m.copyWith(content: updatedMessage.content),
      );

      emit(state.copyWith(messages: _cacheManager.messages));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLeaveRequested(
    ChatRoomLeaveRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final roomId = state.roomId;
    if (roomId == null) return;

    try {
      await _messageHandler.leaveChatRoom(roomId);
      emit(state.copyWith(hasLeft: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onReinviteUserRequested(
    ReinviteUserRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final roomId = state.roomId;
    if (roomId == null) return;

    emit(state.copyWith(isReinviting: true, reinviteSuccess: false));

    try {
      await _messageHandler.reinviteUser(
        roomId: roomId,
        inviteeId: event.inviteeId,
      );
      emit(state.copyWith(
        isReinviting: false,
        reinviteSuccess: true,
        isOtherUserLeft: false,
      ));
      _log('User reinvited: inviteeId=${event.inviteeId}');
    } catch (e) {
      emit(state.copyWith(
        isReinviting: false,
        reinviteSuccess: false,
        errorMessage: e.toString(),
      ));
      _log('Failed to reinvite user: $e');
    }
  }

  void _onOtherUserLeftStatusChanged(
    OtherUserLeftStatusChanged event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onOtherUserLeftStatusChanged: isOtherUserLeft=${event.isOtherUserLeft}');

    emit(state.copyWith(
      isOtherUserLeft: event.isOtherUserLeft,
      otherUserId: event.relatedUserId,
      otherUserNickname: event.relatedUserNickname,
    ));
  }

  Future<void> _onFileAttachmentRequested(
    FileAttachmentRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null) return;

    emit(state.copyWith(isUploadingFile: true, uploadProgress: 0.0));

    try {
      await _messageHandler.handleFileAttachment(
        roomId: state.roomId!,
        filePath: event.filePath,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );

      emit(state.copyWith(
        isUploadingFile: false,
        uploadProgress: 1.0,
      ));
    } catch (e) {
      _log('File attachment failed: $e');
      emit(state.copyWith(
        isUploadingFile: false,
        uploadProgress: 0.0,
        errorMessage: '파일 전송에 실패했습니다: ${e.toString()}',
      ));
    }
  }

  /// 전송 실패 메시지 재전송 요청 처리
  Future<void> _onMessageRetryRequested(
    MessageRetryRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final pendingMessage = _cacheManager.getPendingMessage(event.localId);
    if (pendingMessage == null || state.roomId == null) return;

    _log('_onMessageRetryRequested: Retrying message (localId=${event.localId})');

    // 상태를 다시 pending으로 변경
    _cacheManager.updatePendingMessageStatus(event.localId, MessageSendStatus.pending);
    emit(state.copyWith(messages: _cacheManager.messages));

    // 재전송 시도
    try {
      await _messageHandler.sendMessage(
        roomId: state.roomId!,
        content: pendingMessage.content,
      );
      _log('_onMessageRetryRequested: Message resent successfully');
    } catch (e) {
      _log('_onMessageRetryRequested: Message retry failed: $e');
      _cacheManager.updatePendingMessageStatus(event.localId, MessageSendStatus.failed);
      emit(state.copyWith(
        messages: _cacheManager.messages,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 전송 실패 메시지 삭제 요청 처리
  void _onPendingMessageDeleteRequested(
    PendingMessageDeleteRequested event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onPendingMessageDeleteRequested: Deleting message (localId=${event.localId})');
    _cacheManager.removePendingMessage(event.localId);
    emit(state.copyWith(messages: _cacheManager.messages));
  }

  // ============================================================
  // Reaction Handlers
  // ============================================================

  /// 리액션 추가 요청 처리
  void _onReactionAddRequested(
    ReactionAddRequested event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onReactionAddRequested: messageId=${event.messageId}, emoji=${event.emoji}');

    _webSocketService.addReaction(
      messageId: event.messageId,
      emoji: event.emoji,
    );
  }

  /// 리액션 제거 요청 처리
  void _onReactionRemoveRequested(
    ReactionRemoveRequested event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onReactionRemoveRequested: messageId=${event.messageId}, emoji=${event.emoji}');

    _webSocketService.removeReaction(
      messageId: event.messageId,
      emoji: event.emoji,
    );
  }

  /// 리액션 이벤트 수신 처리 (WebSocket)
  void _onReactionEventReceived(
    ReactionEventReceived event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onReactionEventReceived: messageId=${event.messageId}, userId=${event.userId}, emoji=${event.emoji}, isAdd=${event.isAdd}');

    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    if (event.isAdd) {
      final reaction = MessageReaction(
        id: event.reactionId ?? 0,
        messageId: event.messageId,
        userId: event.userId,
        userNickname: event.userNickname,
        emoji: event.emoji,
      );
      _cacheManager.addReaction(event.messageId, reaction);
    } else {
      _cacheManager.removeReaction(event.messageId, event.userId, event.emoji);
    }

    emit(state.copyWith(messages: _cacheManager.messages));
  }
}
