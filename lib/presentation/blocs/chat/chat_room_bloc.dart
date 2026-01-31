import 'dart:async';
import 'dart:io';

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
    on<MessageUpdateRequested>(_onMessageUpdateRequested);
    on<ChatRoomLeaveRequested>(_onLeaveRequested);
    on<ReinviteUserRequested>(_onReinviteUserRequested);
    on<OtherUserLeftStatusChanged>(_onOtherUserLeftStatusChanged);
    on<FileAttachmentRequested>(_onFileAttachmentRequested);
  }

  Future<void> _onOpened(
    ChatRoomOpened event,
    Emitter<ChatRoomState> emit,
  ) async {
    // ignore: avoid_print
    print('[ChatRoomBloc] _onOpened called with roomId: ${event.roomId}');

    // 플래그 초기화 (블록이 재사용될 경우를 대비)
    _roomInitialized = false;
    _pendingForegrounded = false;
    _isViewingRoom = false;

    // 현재 사용자 ID 가져오기
    final currentUserId = await _authLocalDataSource.getUserId();

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      currentUserId: currentUserId,
      messages: [],
    ));

    try {
      // 0. 채팅방 정보 가져오기 (상대방 나감 여부 확인) - 선택적, 실패해도 계속 진행
      bool isOtherUserLeft = false;
      int? otherUserId;
      String? otherUserNickname;
      try {
        // ignore: avoid_print
        print('[ChatRoomBloc] Fetching chat room info...');
        final chatRoom = await _chatRepository.getChatRoom(event.roomId);
        isOtherUserLeft = chatRoom.isOtherUserLeft;
        otherUserId = chatRoom.otherUserId;
        otherUserNickname = chatRoom.otherUserNickname;
        // ignore: avoid_print
        print('[ChatRoomBloc] Chat room info: isOtherUserLeft=$isOtherUserLeft, otherUserId=$otherUserId, otherUserNickname=$otherUserNickname');
      } catch (e) {
        // getChatRoom API가 없어도 채팅방은 정상 동작해야 함
        // ignore: avoid_print
        print('[ChatRoomBloc] getChatRoom failed (API may not exist): $e');
      }

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

      // 4. 상태 업데이트 (채팅방 정보 포함)
      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
        isOtherUserLeft: isOtherUserLeft,
        otherUserId: otherUserId,
        otherUserNickname: otherUserNickname,
      ));

      // 5. 방 초기화 완료 표시
      _roomInitialized = true;
      // ignore: avoid_print
      print('[ChatRoomBloc] Room initialization completed, _roomInitialized=true, _pendingForegrounded=$_pendingForegrounded');

      // 6. 대기 중인 foreground 이벤트가 있으면 처리
      // (ChatRoomForegrounded가 ChatRoomOpened 완료 전에 도착한 경우)
      if (_pendingForegrounded) {
        // ignore: avoid_print
        print('[ChatRoomBloc] Processing pending foreground event');
        _pendingForegrounded = false;
        _isViewingRoom = true;
        _startPresencePing();
        await _markAsReadWithRetry(event.roomId, emit);
      }
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
  bool _roomInitialized = false;
  bool _pendingForegrounded = false;

  void _subscribeToWebSocket(int roomId, {int? lastMessageId}) {
    // ignore: avoid_print
    print('[ChatRoomBloc] _subscribeToWebSocket called with roomId: $roomId, lastMessageId: $lastMessageId');

    // 마지막 메시지 ID 저장 (중복 방지용)
    _lastKnownMessageId = lastMessageId;

    // 기존 구독 해제
    _messageSubscription?.cancel();

    // WebSocket 채팅방 구독
    _webSocketService.subscribeToChatRoom(roomId);
    _isRoomSubscribed = true;

    // 메시지 수신 리스너 - state.roomId를 사용하여 최신 roomId 확인
    // 서버가 보내주는 메시지의 unreadCount를 그대로 사용 (서버가 최종 소스)
    _messageSubscription = _webSocketService.messages.listen((wsMessage) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ========== WebSocket Message Received ==========');
      // ignore: avoid_print
      print('[ChatRoomBloc] messageId: ${wsMessage.messageId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] roomId: ${wsMessage.chatRoomId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] content: ${wsMessage.content}');
      // ignore: avoid_print
      print('[ChatRoomBloc] unreadCount: ${wsMessage.unreadCount}');
      // ignore: avoid_print
      print('[ChatRoomBloc] senderId: ${wsMessage.senderId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] Current state.roomId: ${state.roomId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] ================================================');
      
      if (state.roomId != null && wsMessage.chatRoomId == state.roomId) {
        // ignore: avoid_print
        print('[ChatRoomBloc] ✅ Room ID matches, adding MessageReceived event');
        // 서버가 보내준 메시지의 unreadCount를 그대로 사용
        // (서버가 읽음 처리 후 업데이트된 unreadCount를 포함해서 보내줄 수 있음)
        add(MessageReceived(_convertToMessage(wsMessage)));

        // USER_LEFT/USER_JOINED 이벤트 처리 (1:1 채팅방에서 상대방 상태 변경)
        if (wsMessage.eventType == 'USER_LEFT') {
          // ignore: avoid_print
          print('[ChatRoomBloc] 🚪 USER_LEFT event: relatedUserId=${wsMessage.relatedUserId}, relatedUserNickname=${wsMessage.relatedUserNickname}');
          add(OtherUserLeftStatusChanged(
            isOtherUserLeft: true,
            relatedUserId: wsMessage.relatedUserId,
            relatedUserNickname: wsMessage.relatedUserNickname,
          ));
        } else if (wsMessage.eventType == 'USER_JOINED') {
          // ignore: avoid_print
          print('[ChatRoomBloc] 👋 USER_JOINED event: relatedUserId=${wsMessage.relatedUserId}, relatedUserNickname=${wsMessage.relatedUserNickname}');
          add(OtherUserLeftStatusChanged(
            isOtherUserLeft: false,
            relatedUserId: wsMessage.relatedUserId,
            relatedUserNickname: wsMessage.relatedUserNickname,
          ));
        }
      } else {
        // ignore: avoid_print
        print('[ChatRoomBloc] ❌ Ignoring message for different room (state.roomId=${state.roomId}, wsMessage.roomId=${wsMessage.chatRoomId})');
      }
    }, onError: (error) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ❌ Error in message stream: $error');
    });

    // readEvents 리스너: 서버가 읽음 처리 후 업데이트된 메시지를 보내주지 않을 경우를 대비
    // readEvents를 받으면 해당 사용자가 읽은 메시지의 unreadCount를 감소시킴
    _readEventSubscription = _webSocketService.readEvents.listen((readEvent) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ========== ReadEvent Received ==========');
      // ignore: avoid_print
      print('[ChatRoomBloc] roomId: ${readEvent.chatRoomId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] userId: ${readEvent.userId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] lastReadMessageId: ${readEvent.lastReadMessageId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] state.roomId: ${state.roomId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] state.currentUserId: ${state.currentUserId}');
      // ignore: avoid_print
      print('[ChatRoomBloc] ========================================');
      
      if (state.roomId != null && readEvent.chatRoomId == state.roomId) {
        // ignore: avoid_print
        print('[ChatRoomBloc] ✅ Room ID matches, adding MessagesReadUpdated event');
        add(MessagesReadUpdated(
          userId: readEvent.userId,
          lastReadMessageId: readEvent.lastReadMessageId,
          lastReadAt: readEvent.lastReadAt,
        ));
      } else {
        // ignore: avoid_print
        print('[ChatRoomBloc] ❌ Ignoring readEvent for different room');
      }
    }, onError: (error) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ❌ Error in readEvent stream: $error');
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
      senderNickname: wsMessage.senderNickname,
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
    // WebSocket 구독 해제
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
    // ignore: avoid_print
    print('[ChatRoomBloc] ========== _onForegrounded called ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] state.roomId: ${state.roomId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] state.currentUserId: ${state.currentUserId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] _isRoomSubscribed: $_isRoomSubscribed');
    // ignore: avoid_print
    print('[ChatRoomBloc] _roomInitialized: $_roomInitialized');
    // ignore: avoid_print
    print('[ChatRoomBloc] ===========================================');

    // 방 초기화가 완료되지 않았으면 대기 상태로 설정
    // (ChatRoomOpened가 완료되면 pending foreground 이벤트를 처리함)
    if (!_roomInitialized) {
      // ignore: avoid_print
      print('[ChatRoomBloc] _onForegrounded: room not initialized yet, setting _pendingForegrounded=true');
      _pendingForegrounded = true;
      return;
    }

    // 다시 활성화되면 presence ping을 재개하고, 화면에 보이는 상태이므로 읽음 처리를 다시 시도한다.
    if (state.roomId == null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] _onForegrounded: roomId is null, returning');
      return;
    }
    if (state.currentUserId == null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] _onForegrounded: currentUserId is null, returning');
      return;
    }

    // _isRoomSubscribed 체크를 제거: 구독이 완료되지 않았어도 markAsRead는 호출 가능
    // (서버는 roomId만 있으면 읽음 처리를 할 수 있음)
    // 구독이 완료되지 않았으면 나중에 구독이 완료되면 자동으로 markAsRead가 호출될 수 있지만,
    // 여기서도 호출하는 것이 더 안전함 (타이밍 이슈 방지)
    if (!_isRoomSubscribed) {
      // ignore: avoid_print
      print('[ChatRoomBloc] _onForegrounded: _isRoomSubscribed is false, but proceeding with markAsRead anyway');
    }

    _isViewingRoom = true;
    _startPresencePing();

    // REST API로 읽음 처리 (하이브리드 방식)
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
    print('[ChatRoomBloc] ========== _onMessageReceived ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] messageId: ${event.message.id}');
    // ignore: avoid_print
    print('[ChatRoomBloc] roomId: state=${state.roomId}, event=${event.message.chatRoomId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] unreadCount from server: ${event.message.unreadCount}');
    // ignore: avoid_print
    print('[ChatRoomBloc] senderId: ${event.message.senderId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] currentUserId: ${state.currentUserId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] =========================================');

    if (state.roomId != event.message.chatRoomId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Room ID mismatch, ignoring');
      return;
    }

    // 기존 메시지가 있으면 서버가 보내준 unreadCount로 업데이트
    // (서버가 읽음 처리 후 업데이트된 메시지를 보내줄 수 있음)
    final existingMessage = state.messages.firstWhere(
      (m) => m.id == event.message.id,
      orElse: () => Message(id: -1, chatRoomId: 0, senderId: 0, content: '', type: MessageType.text, createdAt: DateTime.now()),
    );
    
    if (existingMessage.id != -1) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ========== UPDATING EXISTING MESSAGE ==========');
      // ignore: avoid_print
      print('[ChatRoomBloc] messageId: ${event.message.id}');
      // ignore: avoid_print
      print('[ChatRoomBloc] OLD unreadCount: ${existingMessage.unreadCount}');
      // ignore: avoid_print
      print('[ChatRoomBloc] NEW unreadCount: ${event.message.unreadCount}');
      // ignore: avoid_print
      print('[ChatRoomBloc] Changed: ${existingMessage.unreadCount != event.message.unreadCount}');
      // ignore: avoid_print
      print('[ChatRoomBloc] ===============================================');
      
      final updatedMessages = state.messages.map((m) {
        if (m.id == event.message.id) {
          return event.message; // 서버가 보내준 값으로 교체 (unreadCount 포함)
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: updatedMessages));
      
      // ignore: avoid_print
      print('[ChatRoomBloc] ✅ State updated with new unreadCount');
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
      // 읽음 처리 전송 (REST API로 전송, 하이브리드 방식)
      await _markAsReadWithRetry(state.roomId!, emit);
    }
  }

  /// 읽음 처리를 REST API로 전송합니다 (하이브리드 방식).
  /// 서버에서 읽음 처리를 완료하면 WebSocket으로 업데이트된 메시지나 readEvents를 전송하므로
  /// 클라이언트는 별도로 상태를 업데이트할 필요 없음
  Future<void> _markAsReadWithRetry(
    int roomId,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.currentUserId == null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] _markAsReadWithRetry: currentUserId is null, cannot send');
      return;
    }

    // ignore: avoid_print
    print('[ChatRoomBloc] ========== Sending markAsRead via REST API ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] roomId: $roomId');
    // ignore: avoid_print
    print('[ChatRoomBloc] userId: ${state.currentUserId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] ======================================================');
    
    try {
      // REST API로 읽음 처리 전송 (하이브리드 방식: 요청은 REST, 업데이트는 WebSocket)
      // 서버가 읽음 처리를 완료하면 WebSocket으로 업데이트된 메시지나 readEvents를 전송함
      await _chatRepository.markAsRead(roomId);
      
      // 읽음 처리 전송 완료를 상태로 표시 (테스트 및 UI 동기화용)
      emit(state.copyWith(isReadMarked: true));
      // ignore: avoid_print
      print('[ChatRoomBloc] ✅ markAsRead sent via REST API, waiting for server WebSocket response...');
    } catch (e) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ❌ Failed to mark as read: $e');
      // 에러가 발생해도 상태는 유지 (서버가 재시도하거나 나중에 다시 시도 가능)
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

  /// readEvents를 처리하여 메시지의 unreadCount를 업데이트
  /// 서버가 읽음 처리 후 업데이트된 메시지를 다시 보내주지 않을 경우를 대비
  void _onMessagesReadUpdated(
    MessagesReadUpdated event,
    Emitter<ChatRoomState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatRoomBloc] ========== _onMessagesReadUpdated ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] userId: ${event.userId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] lastReadMessageId: ${event.lastReadMessageId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] state.currentUserId: ${state.currentUserId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] ============================================');

    if (state.currentUserId == null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] currentUserId is null, ignoring');
      return;
    }

    // 내가 보낸 메시지에 대해서만 unreadCount 업데이트
    // (상대방이 읽었으면 내가 보낸 메시지의 unreadCount가 감소해야 함)
    if (event.userId == state.currentUserId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] This is my own read event, ignoring (I don\'t need to update my own messages)');
      return;
    }

    // 상대방이 읽은 경우, 내가 보낸 메시지 중 lastReadMessageId 이하의 메시지들의 unreadCount를 감소
    if (event.lastReadMessageId == null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] lastReadMessageId is null, cannot update');
      return;
    }

    // ignore: avoid_print
    print('[ChatRoomBloc] Updating unreadCount for messages <= ${event.lastReadMessageId}');
    
    final updatedMessages = state.messages.map((message) {
      // 내가 보낸 메시지이고, 상대방이 읽은 메시지 ID 이하인 경우 unreadCount 감소
      if (message.senderId == state.currentUserId && 
          message.id <= event.lastReadMessageId! &&
          message.unreadCount > 0) {
        // ignore: avoid_print
        print('[ChatRoomBloc] Updating message ${message.id}: unreadCount ${message.unreadCount} -> ${message.unreadCount - 1}');
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
    // ignore: avoid_print
    print('[ChatRoomBloc] ✅ State updated with new unreadCount');
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
      // 재초대 성공 시 isOtherUserLeft를 false로 변경
      emit(state.copyWith(
        isReinviting: false,
        reinviteSuccess: true,
        isOtherUserLeft: false,
      ));
      // ignore: avoid_print
      print('[ChatRoomBloc] User reinvited successfully: inviteeId=${event.inviteeId}');
    } catch (e) {
      emit(state.copyWith(
        isReinviting: false,
        reinviteSuccess: false,
        errorMessage: e.toString(),
      ));
      // ignore: avoid_print
      print('[ChatRoomBloc] Failed to reinvite user: $e');
    }
  }

  /// WebSocket에서 USER_LEFT/USER_JOINED 이벤트를 수신했을 때 상태를 업데이트합니다.
  /// 이 핸들러를 통해 채팅방을 나갔다 다시 들어오지 않아도 실시간으로
  /// 상대방의 나감/참여 상태가 UI에 반영됩니다.
  void _onOtherUserLeftStatusChanged(
    OtherUserLeftStatusChanged event,
    Emitter<ChatRoomState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatRoomBloc] ========== _onOtherUserLeftStatusChanged ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] isOtherUserLeft: ${event.isOtherUserLeft}');
    // ignore: avoid_print
    print('[ChatRoomBloc] relatedUserId: ${event.relatedUserId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] relatedUserNickname: ${event.relatedUserNickname}');
    // ignore: avoid_print
    print('[ChatRoomBloc] ==================================================');

    emit(state.copyWith(
      isOtherUserLeft: event.isOtherUserLeft,
      otherUserId: event.relatedUserId,
      otherUserNickname: event.relatedUserNickname,
    ));

    // ignore: avoid_print
    print('[ChatRoomBloc] ✅ State updated: isOtherUserLeft=${event.isOtherUserLeft}, otherUserId=${event.relatedUserId}');
  }

  /// 파일/이미지 첨부를 처리합니다.
  /// 1. 파일을 서버에 업로드
  /// 2. 업로드 완료 후 파일 메시지 전송
  Future<void> _onFileAttachmentRequested(
    FileAttachmentRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null) return;

    // ignore: avoid_print
    print('[ChatRoomBloc] ========== _onFileAttachmentRequested ==========');
    // ignore: avoid_print
    print('[ChatRoomBloc] filePath: ${event.filePath}');
    // ignore: avoid_print
    print('[ChatRoomBloc] roomId: ${state.roomId}');
    // ignore: avoid_print
    print('[ChatRoomBloc] ================================================');

    emit(state.copyWith(isUploadingFile: true, uploadProgress: 0.0));

    try {
      final file = File(event.filePath);

      // 1. 파일 업로드
      // ignore: avoid_print
      print('[ChatRoomBloc] Uploading file...');
      final uploadResult = await _chatRepository.uploadFile(file);
      // ignore: avoid_print
      print('[ChatRoomBloc] File uploaded: ${uploadResult.fileUrl}');

      emit(state.copyWith(uploadProgress: 0.5));

      // 2. 파일 메시지 전송 (senderId는 서버에서 JWT로 추출)
      // ignore: avoid_print
      print('[ChatRoomBloc] Sending file message...');
      await _chatRepository.sendFileMessage(
        roomId: state.roomId!,
        fileUrl: uploadResult.fileUrl,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        contentType: uploadResult.contentType,
        thumbnailUrl: uploadResult.isImage ? uploadResult.fileUrl : null,
      );
      // ignore: avoid_print
      print('[ChatRoomBloc] ✅ File message sent successfully');

      emit(state.copyWith(
        isUploadingFile: false,
        uploadProgress: 1.0,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[ChatRoomBloc] ❌ File attachment failed: $e');
      emit(state.copyWith(
        isUploadingFile: false,
        uploadProgress: 0.0,
        errorMessage: '파일 전송에 실패했습니다: ${e.toString()}',
      ));
    }
  }
}
