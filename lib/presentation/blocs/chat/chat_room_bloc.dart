import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/active_room_tracker.dart';
import '../../../core/services/desktop_notification_bridge.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friend_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
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
  final FriendRepository _friendRepository;
  final SettingsRepository _settingsRepository;

  // Managers
  late final WebSocketSubscriptionManager _subscriptionManager;
  late final PresenceManager _presenceManager;
  late final MessageCacheManager _cacheManager;
  late final MessageHandler _messageHandler;

  // State tracking
  bool _roomInitialized = false;
  bool _pendingForegrounded = false;

  // WebSocket reconnection subscription for gap recovery
  StreamSubscription<void>? _reconnectedSubscription;

  // Typing indicator auto-timeout timers (5s per user)
  final Map<int, Timer> _typingTimeoutTimers = {};

  // Pending message timeout timer
  Timer? _pendingTimeoutTimer;
  static const _pendingTimeoutCheckInterval = Duration(seconds: 10);
  static const _pendingMessageTimeout = Duration(seconds: 15);

  // markAsRead debounce timer: coalesces rapid consecutive calls into one
  Timer? _markAsReadDebounceTimer;
  // markAsRead retry timer: separate from debounce to allow independent cancellation
  Timer? _markAsReadRetryTimer;

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
    this._desktopNotificationBridge,
    this._activeRoomTracker,
    this._friendRepository,
    this._settingsRepository,
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
    on<MessageUpdatedByOther>(_onMessageUpdatedByOther);
    on<LinkPreviewUpdated>(_onLinkPreviewUpdated);
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
    on<MessageSendCompleted>(_onMessageSendCompleted);
    on<PendingMessageDeleteRequested>(_onPendingMessageDeleteRequested);
    on<PendingMessagesTimeoutChecked>(_onPendingMessagesTimeoutChecked);
    on<ChatRoomRefreshRequested>(_onRefreshRequested);
    on<ReactionAddRequested>(_onReactionAddRequested);
    on<ReactionRemoveRequested>(_onReactionRemoveRequested);
    on<ReactionEventReceived>(_onReactionEventReceived);
    on<ReplyToMessageSelected>(_onReplyToMessageSelected);
    on<ReplyCancelled>(_onReplyCancelled);
    on<MessageForwardRequested>(_onMessageForwardRequested);
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

    // Fetch blocked user IDs for message filtering
    Set<int> blockedUserIds = {};
    try {
      final blockedUsers = await _friendRepository.getBlockedUsers();
      blockedUserIds = blockedUsers.map((u) => u.id).toSet();
    } catch (e) {
      _log('Failed to fetch blocked users: $e');
    }

    // Load typing indicator setting
    bool showTypingIndicator = false;
    try {
      final chatSettings = await _settingsRepository.getChatSettings();
      showTypingIndicator = chatSettings.showTypingIndicator;
    } catch (e) {
      _log('Failed to load chat settings: $e');
    }

    // Set active room for notification suppression
    _desktopNotificationBridge.setActiveRoomId(event.roomId);
    _activeRoomTracker.activeRoomId = event.roomId;

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      currentUserId: currentUserId,
      messages: [],
      isOfflineData: false,
      blockedUserIds: blockedUserIds,
      showTypingIndicator: showTypingIndicator,
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
      String? roomName;
      ChatRoomType? roomType;
      try {
        final chatRoom = await _chatRepository.getChatRoom(event.roomId);
        isOtherUserLeft = chatRoom.isOtherUserLeft;
        otherUserId = chatRoom.otherUserId;
        otherUserNickname = chatRoom.otherUserNickname;
        roomName = chatRoom.name;
        roomType = chatRoom.type;
      } catch (e) {
        _log('getChatRoom failed: $e');
      }

      await _cacheManager.loadMessagesFromServer(event.roomId);
      _log('Fetched ${_cacheManager.messages.length} messages from server');

      await _subscribeToWebSocket(event.roomId);

      // Subscribe to reconnection events for gap recovery
      _reconnectedSubscription?.cancel();
      _reconnectedSubscription = _webSocketService.reconnected.listen((_) {
        if (state.roomId != null && state.status == ChatRoomStatus.success) {
          _log('WebSocket reconnected, triggering gap recovery');
          add(const ChatRoomRefreshRequested());
        }
      });

      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: _cacheManager.messages,
        nextCursor: _cacheManager.nextCursor,
        hasMore: _cacheManager.hasMore,
        isOtherUserLeft: isOtherUserLeft,
        otherUserId: otherUserId,
        otherUserNickname: otherUserNickname,
        roomName: roomName,
        roomType: roomType,
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
      onMessageUpdated: (updatedEvent) {
        _log('WebSocket message updated: messageId=${updatedEvent.messageId}');

        if (state.roomId != null && updatedEvent.chatRoomId == state.roomId) {
          add(MessageUpdatedByOther(
            messageId: updatedEvent.messageId,
            newContent: updatedEvent.newContent,
          ));
        }
      },
      onLinkPreviewUpdated: (event) {
        _log('WebSocket link preview updated: messageId=${event.messageId}');
        if (state.roomId != null && event.chatRoomId == state.roomId) {
          add(LinkPreviewUpdated(
            messageId: event.messageId,
            linkPreviewUrl: event.linkPreviewUrl,
            linkPreviewTitle: event.linkPreviewTitle,
            linkPreviewDescription: event.linkPreviewDescription,
            linkPreviewImageUrl: event.linkPreviewImageUrl,
          ));
        }
      },
      onReactionEvent: (reactionEvent) {
        _log('WebSocket reaction: messageId=${reactionEvent.messageId}, userId=${reactionEvent.userId}, emoji=${reactionEvent.emoji}, type=${reactionEvent.eventType}');

        add(ReactionEventReceived(
          messageId: reactionEvent.messageId,
          userId: reactionEvent.userId,
          emoji: reactionEvent.emoji,
          isAdd: reactionEvent.eventType == 'ADDED',
          reactionId: reactionEvent.reactionId,
        ));
      },
    );
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onClosed: roomId=${state.roomId}, cleaning up resources');

    if (state.roomId != null) {
      _subscriptionManager.unsubscribeFromRoom(state.roomId!);
    }
    _reconnectedSubscription?.cancel();
    _reconnectedSubscription = null;
    // Send presenceInactive to server before disposing (so server stops suppressing push)
    // Guard: only send if not already sent by _onBackgrounded
    if (state.roomId != null && state.currentUserId != null && _presenceManager.isViewingRoom) {
      _presenceManager.sendPresenceInactive(state.roomId!, state.currentUserId!);
    }
    _presenceManager.dispose();
    _stopPendingTimeoutChecker();
    // Clean up typing timeout timers
    for (final timer in _typingTimeoutTimers.values) {
      timer.cancel();
    }
    _typingTimeoutTimers.clear();
    _roomInitialized = false;
    _pendingForegrounded = false;

    // Release notification suppression
    _desktopNotificationBridge.setActiveRoomId(null);
    _activeRoomTracker.activeRoomId = null;
    _log('_onClosed: activeRoomId cleared for notification suppression');

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
      final newCursor = _cacheManager.nextCursor;
      emit(state.copyWith(
        messages: _cacheManager.messages,
        nextCursor: newCursor,
        clearNextCursor: newCursor == null,
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

    // Cancel any pending markAsRead timers to prevent race condition
    // where message arrives while focused, timer starts, then window blurs
    // before timer fires
    _markAsReadDebounceTimer?.cancel();
    _markAsReadDebounceTimer = null;
    _markAsReadRetryTimer?.cancel();
    _markAsReadRetryTimer = null;

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

    if (isMobile && !_webSocketService.isConnected) {
      // Mobile: full reconnect + gap recovery (WebSocket was actually disconnected)
      // 1. Reset reconnect attempts for a fresh reconnection sequence
      _webSocketService.resetReconnectAttempts();

      // 2. Reconnect WebSocket
      _log('_onForegrounded: reconnecting WebSocket (mobile, was disconnected)...');
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

      // 5. Resolve pending messages that were actually sent to server
      //    (gap recovery already fetched them, no need to retry)
    } else if (isMobile) {
      // Mobile but still connected (brief lifecycle event, debounced background didn't fire)
      _log('_onForegrounded: WebSocket still connected, skipping reconnect (mobile)');
    } else {
      // Desktop: WebSocket stayed connected, just resume presence
      _log('_onForegrounded: resuming presence (desktop)');
    }

    // Presence active + mark as read (both mobile and desktop)
    _presenceManager.sendPresenceActive(state.roomId!, state.currentUserId!);
    await _messageHandler.markAsRead(state.roomId!);

    // Emit updated state
    final newCursor = _cacheManager.nextCursor;
    emit(state.copyWith(
      messages: _cacheManager.messages,
      nextCursor: newCursor,
      clearNextCursor: newCursor == null,
      hasMore: _cacheManager.hasMore,
      isReadMarked: true,
      isOfflineData: false,
    ));
  }

  void _onReplyToMessageSelected(
    ReplyToMessageSelected event,
    Emitter<ChatRoomState> emit,
  ) {
    emit(state.copyWith(replyToMessage: event.message));
  }

  void _onReplyCancelled(
    ReplyCancelled event,
    Emitter<ChatRoomState> emit,
  ) {
    emit(state.copyWith(clearReplyToMessage: true));
  }

  Future<void> _onMessageForwardRequested(
    MessageForwardRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    emit(state.copyWith(isForwarding: true, forwardSuccess: false));
    try {
      await _chatRepository.forwardMessage(event.messageId, event.targetRoomId);
      emit(state.copyWith(isForwarding: false, forwardSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isForwarding: false,
        forwardSuccess: false,
        errorMessage: '메시지 전달에 실패했습니다: ${e.toString()}',
      ));
    }
  }

  void _sendReplyInBackground({
    required String localId,
    required int replyToMessageId,
    required String content,
  }) {
    _chatRepository.replyToMessage(replyToMessageId, content).then((_) {
      if (!isClosed) {
        add(MessageSendCompleted(localId: localId, success: true));
      }
    }).catchError((Object e) {
      if (!isClosed) {
        add(MessageSendCompleted(
          localId: localId,
          success: false,
          error: e.toString(),
        ));
      }
    });
  }

  @override
  Future<void> close() {
    _stopPendingTimeoutChecker();
    _markAsReadDebounceTimer?.cancel();
    _markAsReadRetryTimer?.cancel();
    _reconnectedSubscription?.cancel();
    for (final timer in _typingTimeoutTimers.values) {
      timer.cancel();
    }
    _typingTimeoutTimers.clear();
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

  void _onMessageSent(
    MessageSent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId == null || state.currentUserId == null) return;

    final localId = _uuid.v4();
    final replyToMessage = state.replyToMessage;

    final pendingMessage = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatRoomId: state.roomId!,
      senderId: state.currentUserId!,
      content: event.content,
      createdAt: DateTime.now(),
      sendStatus: MessageSendStatus.pending,
      localId: localId,
      replyToMessageId: replyToMessage?.id,
      replyToMessage: replyToMessage,
    );

    _log('_onMessageSent: Adding pending message (localId=$localId${replyToMessage != null ? ', replyTo=${replyToMessage.id}' : ''})');
    _cacheManager.addPendingMessage(pendingMessage);

    // Clear reply state immediately after creating the pending message
    emit(state.copyWith(messages: _cacheManager.messages, clearReplyToMessage: true));

    if (replyToMessage != null) {
      // Reply message: use reply API
      _sendReplyInBackground(
        localId: localId,
        replyToMessageId: replyToMessage.id,
        content: event.content,
      );
    } else {
      // Normal message: use standard send
      _sendMessageInBackground(
        localId: localId,
        roomId: state.roomId!,
        content: event.content,
        userId: state.currentUserId,
      );
    }
  }

  /// Sends a message in the background without blocking the BLoC event queue.
  ///
  /// Results are dispatched via [MessageSendCompleted] events.
  void _sendMessageInBackground({
    required String localId,
    required int roomId,
    required String content,
    int? userId,
  }) {
    _messageHandler.sendMessage(
      roomId: roomId,
      content: content,
      userId: userId,
    ).then((_) {
      if (!isClosed) {
        add(MessageSendCompleted(localId: localId, success: true));
      }
    }).catchError((Object e) {
      if (!isClosed) {
        add(MessageSendCompleted(
          localId: localId,
          success: false,
          error: e.toString(),
        ));
      }
    });
  }

  /// Handles the result of a background message send.
  void _onMessageSendCompleted(
    MessageSendCompleted event,
    Emitter<ChatRoomState> emit,
  ) {
    if (event.success) {
      _log('_onMessageSendCompleted: sent (localId=${event.localId})');
      // 전송 성공 → 즉시 "sent" 상태로 변경 (에코를 기다리지 않음).
      // 에코가 오면 _onMessageReceived에서 서버 메시지로 교체.
      _cacheManager.updatePendingMessageStatus(
        event.localId,
        MessageSendStatus.sent,
      );
      emit(state.copyWith(messages: _cacheManager.messages));
    } else {
      _log('_onMessageSendCompleted: failed (localId=${event.localId}): ${event.error}');
      _cacheManager.updatePendingMessageStatus(
        event.localId,
        MessageSendStatus.failed,
      );
      emit(state.copyWith(
        messages: _cacheManager.messages,
        errorMessage: event.error,
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

    // Filter messages from blocked users
    if (state.blockedUserIds.contains(event.message.senderId)) {
      _log('_onMessageReceived: FILTERED - message from blocked user ${event.message.senderId}');
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
        // Update lastKnownMessageId to prevent drift-based filtering
        _subscriptionManager.updateLastKnownMessageId(event.message.id);
        emit(state.copyWith(
          messages: _cacheManager.messages,
          isOfflineData: false,
        ));
        return;
      }
    }

    // 일반 메시지 추가
    _cacheManager.addMessage(event.message);
    // Update lastKnownMessageId to prevent drift-based filtering
    _subscriptionManager.updateLastKnownMessageId(event.message.id);
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
      // Debounce markAsRead: coalesce rapid consecutive messages into a single REST call.
      // Without debounce, 10 messages arriving at once would fire 10 HTTP POST requests,
      // each triggering read receipts + chat list updates on the server.
      _markAsReadDebounceTimer?.cancel();
      _markAsReadRetryTimer?.cancel();
      final roomId = state.roomId!;
      _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!isClosed && state.roomId == roomId && _presenceManager.isViewingRoom) {
          _messageHandler.markAsRead(roomId).catchError((e) {
            if (kDebugMode) debugPrint('[ChatRoomBloc] markAsRead failed, retrying: $e');
            _markAsReadRetryTimer = Timer(const Duration(seconds: 2), () {
              if (!isClosed && state.roomId == roomId && _presenceManager.isViewingRoom) {
                _messageHandler.markAsRead(roomId).catchError((_) {});
              }
            });
          });
        }
      });
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

  void _onMessageUpdatedByOther(
    MessageUpdatedByOther event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onMessageUpdatedByOther: messageId=${event.messageId}');
    _cacheManager.updateMessage(
      event.messageId,
      (m) => m.copyWith(content: event.newContent),
    );
    emit(state.copyWith(messages: _cacheManager.messages));
  }

  void _onLinkPreviewUpdated(
    LinkPreviewUpdated event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onLinkPreviewUpdated: messageId=${event.messageId}');
    _cacheManager.updateMessage(
      event.messageId,
      (m) => m.copyWith(
        linkPreviewUrl: event.linkPreviewUrl,
        linkPreviewTitle: event.linkPreviewTitle,
        linkPreviewDescription: event.linkPreviewDescription,
        linkPreviewImageUrl: event.linkPreviewImageUrl,
      ),
    );
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

    // 처리된 이벤트 기록 (LinkedHashSet을 사용하여 삽입 순서 보장)
    var newProcessedEvents = LinkedHashSet<String>.from(state.processedReadEvents)..add(eventKey);
    // Cap the set to prevent unbounded growth
    if (newProcessedEvents.length > 500) {
      // Keep only the most recent entries by taking the last 250
      final eventsList = newProcessedEvents.toList();
      newProcessedEvents = LinkedHashSet<String>.from(
        eventsList.sublist(eventsList.length - 250),
      );
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
    // 입력중 표시 설정이 꺼져 있으면 무시
    if (!state.showTypingIndicator) return;

    final updatedTypingUsers = Map<int, String>.from(state.typingUsers);

    // 기존 타이머 취소
    _typingTimeoutTimers[event.userId]?.cancel();

    if (event.isTyping) {
      updatedTypingUsers[event.userId] = event.userNickname ?? '상대방';
      // 5초 자동 타임아웃: 서버 의존 없이 자동 해제
      _typingTimeoutTimers[event.userId] = Timer(const Duration(seconds: 5), () {
        if (!isClosed) {
          add(TypingStatusChanged(
            userId: event.userId,
            userNickname: event.userNickname,
            isTyping: false,
          ));
        }
      });
    } else {
      updatedTypingUsers.remove(event.userId);
      _typingTimeoutTimers.remove(event.userId);
    }

    emit(state.copyWith(typingUsers: updatedTypingUsers));
  }

  void _onUserStartedTyping(
    UserStartedTyping event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId == null || state.currentUserId == null) return;
    // 입력중 표시 설정이 꺼져 있으면 타이핑 상태를 전송하지 않음
    if (!state.showTypingIndicator) return;

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
    if (!state.showTypingIndicator) return;

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
      final raw = e.toString().toLowerCase();
      final isSignatureError = raw.contains('signature') ||
          raw.contains('content type') ||
          raw.contains('content-type');
      final errorMessage = isSignatureError
          ? '이미지/파일 형식이 올바르지 않습니다. 다른 사진으로 시도해 주세요.'
          : '파일 전송에 실패했습니다: ${e.toString()}';
      emit(state.copyWith(
        isUploadingFile: false,
        uploadProgress: 0.0,
        errorMessage: errorMessage,
      ));
    }
  }

  /// 전송 실패 메시지 재전송 요청 처리
  void _onMessageRetryRequested(
    MessageRetryRequested event,
    Emitter<ChatRoomState> emit,
  ) {
    final pendingMessage = _cacheManager.getPendingMessage(event.localId);
    if (pendingMessage == null || state.roomId == null) return;

    _log('_onMessageRetryRequested: Retrying message (localId=${event.localId})');

    // 상태를 다시 pending으로 변경
    _cacheManager.updatePendingMessageStatus(event.localId, MessageSendStatus.pending);
    emit(state.copyWith(messages: _cacheManager.messages));

    // Fire-and-forget 재전송 (BLoC 큐 차단하지 않음)
    _sendMessageInBackground(
      localId: event.localId,
      roomId: state.roomId!,
      content: pendingMessage.content,
      userId: state.currentUserId,
    );
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

    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    // Optimistic UI update - add reaction immediately
    final currentUserId = state.currentUserId;
    if (currentUserId != null) {
      final optimisticReaction = MessageReaction(
        id: 0, // temporary ID, will be replaced by server echo
        messageId: event.messageId,
        userId: currentUserId,
        emoji: event.emoji,
      );
      _cacheManager.addReaction(event.messageId, optimisticReaction);
      emit(state.copyWith(messages: _cacheManager.messages));
    }

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

    // Sync cache manager with state if out of sync (for tests with seeded state)
    if (_cacheManager.messages.isEmpty && state.messages.isNotEmpty) {
      _cacheManager.syncMessages(state.messages);
    }

    // Optimistic UI update - remove reaction immediately
    final currentUserId = state.currentUserId;
    if (currentUserId != null) {
      _cacheManager.removeReaction(event.messageId, currentUserId, event.emoji);
      emit(state.copyWith(messages: _cacheManager.messages));
    }

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
