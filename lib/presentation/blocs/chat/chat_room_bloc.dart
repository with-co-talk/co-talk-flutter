import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/desktop_notification_bridge.dart';
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
  final DesktopNotificationBridge _desktopNotificationBridge;

  StreamSubscription<WebSocketChatMessage>? _messageSubscription;
  StreamSubscription<WebSocketReadEvent>? _readEventSubscription;
  StreamSubscription<WebSocketTypingEvent>? _typingSubscription;
  StreamSubscription<WebSocketMessageDeletedEvent>? _messageDeletedSubscription;
  Timer? _typingDebounceTimer;
  Timer? _presencePingTimer;

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
    this._desktopNotificationBridge,
  ) : super(const ChatRoomState()) {
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
    _isViewingRoom = false;

    final currentUserId = await _authLocalDataSource.getUserId();

    // 데스크톱 알림 억제를 위해 현재 채팅방 ID 설정
    _desktopNotificationBridge.setActiveRoomId(event.roomId);

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      currentUserId: currentUserId,
      messages: [],
      isOfflineData: false,
    ));

    // 1. 로컬 캐시 먼저 로드 (빠른 초기 표시)
    try {
      final cachedMessages = await _chatRepository.getLocalMessages(
        event.roomId,
        limit: AppConstants.messagePageSize,
      );

      if (cachedMessages.isNotEmpty) {
        _log('Loaded ${cachedMessages.length} cached messages');
        emit(state.copyWith(
          status: ChatRoomStatus.success,
          messages: cachedMessages,
          hasMore: cachedMessages.length >= AppConstants.messagePageSize,
          isOfflineData: true,
        ));
      }
    } catch (e) {
      _log('Failed to load cached messages: $e');
    }

    // 2. 서버에서 최신 데이터 동기화
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

      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        event.roomId,
        size: AppConstants.messagePageSize,
      );
      _log('Fetched ${messages.length} messages from server');

      final lastMessageId = messages.isNotEmpty ? messages.first.id : null;

      _subscribeToWebSocket(event.roomId, lastMessageId: lastMessageId);
      if (_isViewingRoom) {
        _startPresencePing();
      } else if (state.currentUserId != null) {
        // 포커스가 없으면 서버에 "보고 있지 않다"고 알림
        // 서버가 WebSocket 구독만으로 "보고 있다"고 인식하지 않도록
        _log('Sending presenceInactive (not viewing room)');
        _webSocketService.sendPresenceInactive(
          roomId: event.roomId,
          userId: state.currentUserId!,
        );
      }

      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
        isOtherUserLeft: isOtherUserLeft,
        otherUserId: otherUserId,
        otherUserNickname: otherUserNickname,
        isOfflineData: false,
      ));

      _roomInitialized = true;

      if (_pendingForegrounded) {
        _log('Processing pending foreground event');
        _pendingForegrounded = false;
        _isViewingRoom = true;
        _startPresencePing();
        await _markAsReadWithRetry(event.roomId, emit);
      }
    } catch (e, stackTrace) {
      _log('Error in _onOpened: $e\n$stackTrace');

      // 오프라인 모드: 캐시된 메시지가 있으면 유지
      if (state.messages.isNotEmpty) {
        _log('Keeping cached messages due to network error');
        _roomInitialized = true;
        // 캐시된 데이터로 성공 상태 유지
        emit(state.copyWith(
          isOfflineData: true,
        ));
      } else {
        emit(state.copyWith(
          status: ChatRoomStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  int? _lastKnownMessageId;
  bool _isRoomSubscribed = false;
  bool _isViewingRoom = false;
  bool _roomInitialized = false;
  bool _pendingForegrounded = false;

  void _subscribeToWebSocket(int roomId, {int? lastMessageId}) {
    _log('_subscribeToWebSocket: roomId=$roomId, lastMessageId=$lastMessageId');

    _lastKnownMessageId = lastMessageId;
    _messageSubscription?.cancel();

    _webSocketService.subscribeToChatRoom(roomId);
    _isRoomSubscribed = true;

    _messageSubscription = _webSocketService.messages.listen((wsMessage) {
      _log('WebSocket message: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}, unreadCount=${wsMessage.unreadCount}');

      if (state.roomId != null && wsMessage.chatRoomId == state.roomId) {
        add(MessageReceived(_convertToMessage(wsMessage)));

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
    }, onError: (error) {
      _log('Error in message stream: $error');
    });

    _readEventSubscription = _webSocketService.readEvents.listen((readEvent) {
      _log('ReadEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');

      if (state.roomId != null && readEvent.chatRoomId == state.roomId) {
        add(MessagesReadUpdated(
          userId: readEvent.userId,
          lastReadMessageId: readEvent.lastReadMessageId,
          lastReadAt: readEvent.lastReadAt,
        ));
      }
    }, onError: (error) {
      _log('Error in readEvent stream: $error');
    });

    _typingSubscription = _webSocketService.typingEvents.listen((typingEvent) {
      if (state.roomId != null && typingEvent.chatRoomId == state.roomId) {
        if (typingEvent.userId == state.currentUserId) return;

        add(TypingStatusChanged(
          userId: typingEvent.userId,
          userNickname: typingEvent.userNickname,
          isTyping: typingEvent.isTyping,
        ));
      }
    }, onError: (error) {
      _log('Error in typing event stream: $error');
    });

    _messageDeletedSubscription = _webSocketService.messageDeletedEvents.listen((deletedEvent) {
      _log('WebSocket message deleted: messageId=${deletedEvent.messageId}, roomId=${deletedEvent.chatRoomId}');

      if (state.roomId != null && deletedEvent.chatRoomId == state.roomId) {
        add(MessageDeletedByOther(deletedEvent.messageId));
      }
    }, onError: (error) {
      _log('Error in message deleted stream: $error');
    });
  }

  Message _convertToMessage(WebSocketChatMessage wsMessage) {
    return Message(
      id: wsMessage.messageId,
      chatRoomId: wsMessage.chatRoomId,
      senderId: wsMessage.senderId ?? 0,
      senderNickname: wsMessage.senderNickname,
      senderAvatarUrl: wsMessage.senderAvatarUrl,
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
      case 'SYSTEM':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId != null) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    _isRoomSubscribed = false;
    _isViewingRoom = false;
    _roomInitialized = false;
    _pendingForegrounded = false;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _readEventSubscription?.cancel();
    _readEventSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _messageDeletedSubscription?.cancel();
    _messageDeletedSubscription = null;
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    _presencePingTimer?.cancel();
    _presencePingTimer = null;

    // 데스크톱 알림 억제 해제
    _desktopNotificationBridge.setActiveRoomId(null);

    emit(const ChatRoomState());
  }

  void _onBackgrounded(
    ChatRoomBackgrounded event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onBackgrounded: roomId=${state.roomId}, initialized=$_roomInitialized, pendingForegrounded=$_pendingForegrounded');

    // 초기화 전에 background 이벤트가 오면 pending foregrounded를 취소
    // 이렇게 하면 창이 포커스 빠진 상태에서 초기화가 완료되어도 읽음 처리를 하지 않음
    if (_pendingForegrounded) {
      _log('Cancelling pending foregrounded event');
      _pendingForegrounded = false;
    }

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
    _log('_onForegrounded: roomId=${state.roomId}, initialized=$_roomInitialized');

    if (!_roomInitialized) {
      _pendingForegrounded = true;
      return;
    }

    if (state.roomId == null || state.currentUserId == null) return;

    _isViewingRoom = true;
    _startPresencePing();

    await _markAsReadWithRetry(state.roomId!, emit);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _readEventSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    _presencePingTimer?.cancel();
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

      _log('Sending message: roomId=${state.roomId}, content=${event.content}');
      _webSocketService.sendMessage(
        roomId: state.roomId!,
        senderId: userId,
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

    // 로컬 캐시에 메시지 저장
    try {
      await _chatRepository.saveMessageLocally(event.message);
    } catch (e) {
      _log('Failed to save message locally: $e');
    }

    final existingMessage = state.messages.firstWhere(
      (m) => m.id == event.message.id,
      orElse: () => Message(id: -1, chatRoomId: 0, senderId: 0, content: '', type: MessageType.text, createdAt: DateTime.now()),
    );

    if (existingMessage.id != -1) {
      final updatedMessages = state.messages.map((m) {
        if (m.id == event.message.id) {
          return event.message;
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: updatedMessages));
      return;
    }

    if (_lastKnownMessageId != null && event.message.id <= _lastKnownMessageId!) {
      return;
    }

    emit(state.copyWith(
      messages: [event.message, ...state.messages],
      isOfflineData: false,
    ));

    if (_isViewingRoom &&
        state.currentUserId != null &&
        event.message.senderId != state.currentUserId &&
        state.roomId != null) {
      await _markAsReadWithRetry(state.roomId!, emit);
    }
  }

  Future<void> _markAsReadWithRetry(
    int roomId,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.currentUserId == null) return;

    _log('markAsRead: roomId=$roomId');

    try {
      await _chatRepository.markAsRead(roomId);
      emit(state.copyWith(isReadMarked: true));
    } catch (e) {
      _log('Failed to mark as read: $e');
    }
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

  /// 다른 사용자가 메시지를 삭제했을 때 처리 (WebSocket 수신)
  void _onMessageDeletedByOther(
    MessageDeletedByOther event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onMessageDeletedByOther: messageId=${event.messageId}');

    final updatedMessages = state.messages.map((m) {
      if (m.id == event.messageId) {
        return m.copyWith(isDeleted: true);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
  }

  void _onMessagesReadUpdated(
    MessagesReadUpdated event,
    Emitter<ChatRoomState> emit,
  ) {
    _log('_onMessagesReadUpdated: userId=${event.userId}, lastReadMessageId=${event.lastReadMessageId}');

    if (state.currentUserId == null) return;

    if (event.userId == state.currentUserId) return;

    if (event.lastReadMessageId == null) return;

    final updatedMessages = state.messages.map((message) {
      if (message.senderId == state.currentUserId &&
          message.id <= event.lastReadMessageId! &&
          message.unreadCount > 0) {
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    }).toList();

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

    _webSocketService.sendTypingStatus(
      roomId: state.roomId!,
      userId: state.currentUserId!,
      isTyping: true,
    );

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

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    _webSocketService.sendTypingStatus(
      roomId: state.roomId!,
      userId: state.currentUserId!,
      isTyping: false,
    );
  }

  Future<void> _onMessageUpdateRequested(
    MessageUpdateRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      final updatedMessage = await _chatRepository.updateMessage(
        event.messageId,
        event.content,
      );

      final updatedMessages = state.messages.map((m) {
        if (m.id == event.messageId) {
          return m.copyWith(content: updatedMessage.content);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
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
      await _chatRepository.leaveChatRoom(roomId);
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
      await _chatRepository.reinviteUser(roomId, event.inviteeId);
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

    _log('_onFileAttachmentRequested: filePath=${event.filePath}');

    final file = File(event.filePath);
    if (!await file.exists()) {
      emit(state.copyWith(errorMessage: '파일을 찾을 수 없습니다'));
      return;
    }

    final fileSize = await file.length();
    if (fileSize > AppConstants.maxFileSize) {
      emit(state.copyWith(
        errorMessage: '파일 크기는 ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB 이하여야 합니다',
      ));
      return;
    }

    emit(state.copyWith(isUploadingFile: true, uploadProgress: 0.0));

    try {
      final uploadResult = await _chatRepository.uploadFile(file);
      _log('File uploaded: ${uploadResult.fileUrl}');

      emit(state.copyWith(uploadProgress: 0.5));

      await _chatRepository.sendFileMessage(
        roomId: state.roomId!,
        fileUrl: uploadResult.fileUrl,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        contentType: uploadResult.contentType,
        thumbnailUrl: uploadResult.isImage ? uploadResult.fileUrl : null,
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
