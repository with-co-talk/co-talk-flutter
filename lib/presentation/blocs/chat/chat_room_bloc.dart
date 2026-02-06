import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/desktop_notification_bridge.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';
import 'managers/managers.dart';

@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;
  final DesktopNotificationBridge _desktopNotificationBridge;

  // Managers
  late final WebSocketSubscriptionManager _subscriptionManager;
  late final PresenceManager _presenceManager;
  late final MessageCacheManager _cacheManager;
  late final MessageHandler _messageHandler;

  // State tracking
  bool _roomInitialized = false;
  bool _pendingForegrounded = false;

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
    this._desktopNotificationBridge,
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

    final currentUserId = await _authLocalDataSource.getUserId();

    // Set active room for desktop notification suppression
    _desktopNotificationBridge.setActiveRoomId(event.roomId);

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

      _subscribeToWebSocket(event.roomId);

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

  void _subscribeToWebSocket(int roomId) {
    _log('_subscribeToWebSocket: roomId=$roomId');

    _subscriptionManager.subscribeToRoom(
      roomId,
      lastMessageId: _cacheManager.lastMessageId,
      onMessage: (wsMessage) {
        _log('WebSocket message: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}');

        if (state.roomId != null && wsMessage.chatRoomId == state.roomId) {
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
    _roomInitialized = false;
    _pendingForegrounded = false;

    // Release desktop notification suppression
    _desktopNotificationBridge.setActiveRoomId(null);

    emit(const ChatRoomState());
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

    _presenceManager.sendPresenceActive(state.roomId!, state.currentUserId!);
    await _messageHandler.markAsRead(state.roomId!);
    emit(state.copyWith(isReadMarked: true));
  }

  @override
  Future<void> close() {
    _subscriptionManager.dispose();
    _presenceManager.dispose();
    if (state.roomId != null && _subscriptionManager.isRoomSubscribed) {
      _subscriptionManager.unsubscribeFromRoom(state.roomId!);
    }
    return super.close();
  }

  Future<void> _onLoadMore(
    MessagesLoadMoreRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (!_cacheManager.hasMore || _cacheManager.nextCursor == null || state.roomId == null) {
      return;
    }

    try {
      final messages = await _cacheManager.loadMoreMessages(state.roomId!);
      emit(state.copyWith(
        messages: messages,
        nextCursor: _cacheManager.nextCursor,
        hasMore: _cacheManager.hasMore,
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
      await _messageHandler.sendMessage(
        roomId: state.roomId!,
        content: event.content,
      );
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
    _log('_onMessageReceived: id=${event.message.id}, unreadCount=${event.message.unreadCount}');

    if (state.roomId != event.message.chatRoomId) return;

    // Filter duplicate messages based on last known ID
    if (_subscriptionManager.shouldFilterMessage(event.message.id)) {
      return;
    }

    await _cacheManager.addMessage(event.message);

    emit(state.copyWith(
      messages: _cacheManager.messages,
      isOfflineData: false,
    ));

    if (_presenceManager.isViewingRoom &&
        state.currentUserId != null &&
        event.message.senderId != state.currentUserId &&
        state.roomId != null) {
      await _messageHandler.markAsRead(state.roomId!);
    }
  }

  Future<void> _onMessageDeleted(
    MessageDeleted event,
    Emitter<ChatRoomState> emit,
  ) async {
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
    _log('_onMessagesReadUpdated: userId=${event.userId}, lastReadMessageId=${event.lastReadMessageId}');

    if (state.currentUserId == null) return;
    if (event.userId == state.currentUserId) return;
    if (event.lastReadMessageId == null) return;

    // Use state.messages directly to handle seed state in tests
    final updatedMessages = state.messages.map((message) {
      if (message.senderId == state.currentUserId &&
          message.id <= event.lastReadMessageId! &&
          message.unreadCount > 0) {
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    }).toList();

    // Also update cache manager for consistency
    _cacheManager.updateMessages((message) {
      if (message.senderId == state.currentUserId &&
          message.id <= event.lastReadMessageId! &&
          message.unreadCount > 0) {
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    });

    emit(state.copyWith(messages: updatedMessages));
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
}
