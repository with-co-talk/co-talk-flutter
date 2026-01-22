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

  ChatRoomBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
  ) : super(const ChatRoomState()) {
    on<ChatRoomOpened>(_onOpened);
    on<ChatRoomClosed>(_onClosed);
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

      // 4. 상태 업데이트
      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));

      // 5. 채팅방에 포커스가 가면 읽음 처리 (재시도 로직 포함)
      // ignore: avoid_print
      print('[ChatRoomBloc] Marking as read...');
      await _markAsReadWithRetry(event.roomId);
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
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _readEventSubscription?.cancel();
    _readEventSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    emit(const ChatRoomState());
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _readEventSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    if (state.roomId != null) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    return super.close();
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

    // 상대방이 보낸 메시지면 자동으로 읽음 처리 (채팅방이 열려있으므로)
    if (state.currentUserId != null &&
        event.message.senderId != state.currentUserId &&
        state.roomId != null) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Auto marking as read for message from other user');
      // 재시도 로직 포함
      _markAsReadWithRetry(state.roomId!);
    }
  }

  /// 읽음 처리를 재시도 로직과 함께 실행합니다.
  Future<void> _markAsReadWithRetry(
    int roomId, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _chatRepository.markAsRead(roomId);
        // ignore: avoid_print
        print('[ChatRoomBloc] markAsRead succeeded on attempt $attempt');
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
    print('[ChatRoomBloc] _onMessagesReadUpdated: userId=${event.userId}, lastReadMessageId=${event.lastReadMessageId}');

    // 내가 읽은 이벤트인 경우 무시 (상대방이 읽어야 내 메시지의 unreadCount가 감소)
    if (event.userId == state.currentUserId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Ignoring read event from myself');
      return;
    }

    // 내 메시지의 unreadCount만 1씩 감소 (상대방이 읽었으므로)
    // lastReadMessageId가 있으면 해당 메시지까지만, 없으면 모든 메시지
    final updatedMessages = state.messages.map((m) {
      // 내가 보낸 메시지만 처리
      if (m.senderId != state.currentUserId) return m;

      final shouldUpdate = event.lastReadMessageId == null ||
          m.id <= event.lastReadMessageId!;

      if (shouldUpdate && m.unreadCount > 0) {
        return m.copyWith(unreadCount: m.unreadCount - 1);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
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
