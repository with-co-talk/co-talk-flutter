import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

@lazySingleton
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> with DebugLogger {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;

  StreamSubscription<WebSocketChatRoomUpdateEvent>? _chatRoomUpdateSubscription;
  StreamSubscription<WebSocketReadEvent>? _readReceiptSubscription;
  StreamSubscription<WebSocketOnlineStatusEvent>? _onlineStatusSubscription;
  int? _currentUserId;
  int? _currentlyOpenRoomId;
  Timer? _refreshDebounceTimer;
  bool _isRefreshing = false;

  ChatListBloc(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
  ) : super(const ChatListState()) {
    on<ChatListLoadRequested>(_onLoadRequested);
    on<ChatListRefreshRequested>(_onRefreshRequested);
    on<ChatRoomCreated>(_onChatRoomCreated);
    on<GroupChatRoomCreated>(_onGroupChatRoomCreated);
    on<ChatRoomUpdated>(_onChatRoomUpdated);
    on<ChatListSubscriptionStarted>(_onSubscriptionStarted);
    on<ChatListSubscriptionStopped>(_onSubscriptionStopped);
    on<ChatRoomReadCompleted>(_onChatRoomReadCompleted);
    on<ChatRoomEntered>(_onChatRoomEntered);
    on<ChatRoomExited>(_onChatRoomExited);
    on<ChatListResetRequested>(_onResetRequested);
    on<UserOnlineStatusChanged>(_onUserOnlineStatusChanged);
  }

  /// 채팅방 목록 조회: 현재는 커서 기반 페이징 없이 한 번에 전체 로드
  Future<void> _onLoadRequested(
    ChatListLoadRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));

    try {
      final chatRooms = await _chatRepository.getChatRooms();
      // 마지막 메시지 시간 기준 내림차순 정렬 (최신이 위)
      final sortedChatRooms = _sortChatRoomsByActivity(chatRooms);
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: sortedChatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    ChatListRefreshRequested event,
    Emitter<ChatListState> emit,
  ) async {
    if (_isRefreshing) {
      log('Already refreshing, skipping duplicate request');
      return;
    }

    _isRefreshing = true;
    try {
      final chatRooms = await _chatRepository.getChatRooms();
      // 마지막 메시지 시간 기준 내림차순 정렬 (최신이 위)
      final sortedChatRooms = _sortChatRoomsByActivity(chatRooms);
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: sortedChatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    } finally {
      _isRefreshing = false;
    }
  }

  /// 채팅방을 마지막 메시지 시간 기준으로 정렬 (최신이 위)
  List<ChatRoom> _sortChatRoomsByActivity(List<ChatRoom> chatRooms) {
    final sorted = List<ChatRoom>.from(chatRooms);
    sorted.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  void _scheduleRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isRefreshing) {
        add(const ChatListRefreshRequested());
      }
    });
  }

  Future<void> _onChatRoomCreated(
    ChatRoomCreated event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      await _chatRepository.createDirectChatRoom(event.otherUserId);
      add(const ChatListRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onGroupChatRoomCreated(
    GroupChatRoomCreated event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      await _chatRepository.createGroupChatRoom(event.name, event.memberIds);
      add(const ChatListRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onChatRoomUpdated(
    ChatRoomUpdated event,
    Emitter<ChatListState> emit,
  ) async {
    log('_onChatRoomUpdated: roomId=${event.chatRoomId}, unreadCount=${event.unreadCount}');

    _currentUserId ??= await _authLocalDataSource.getUserId();

    final existingRoomIndex = state.chatRooms.indexWhere((room) => room.id == event.chatRoomId);

    if (existingRoomIndex < 0) {
      log('New chat room detected (roomId=${event.chatRoomId}), scheduling refresh...');
      _scheduleRefresh();
      return;
    }

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        // Override unreadCount to 0 if user is currently in this room
        final newUnreadCount = (_currentlyOpenRoomId == event.chatRoomId)
            ? 0
            : (event.unreadCount ?? room.unreadCount);
        log('Updating room ${event.chatRoomId}: unreadCount ${room.unreadCount} -> $newUnreadCount');

        return room.copyWith(
          lastMessage: event.lastMessage ?? room.lastMessage,
          lastMessageType: event.lastMessageType ?? room.lastMessageType,
          lastMessageAt: event.lastMessageAt ?? room.lastMessageAt,
          unreadCount: newUnreadCount,
        );
      }
      return room;
    }).toList();

    updatedChatRooms.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    emit(state.copyWith(chatRooms: updatedChatRooms));
  }

  Future<void> _onSubscriptionStarted(
    ChatListSubscriptionStarted event,
    Emitter<ChatListState> emit,
  ) async {
    log('_onSubscriptionStarted: userId=${event.userId}');

    _currentUserId = event.userId;
    _chatRoomUpdateSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _onlineStatusSubscription?.cancel();

    if (!_webSocketService.isConnected) {
      log('WebSocket not connected, attempting to connect...');
      try {
        await _webSocketService.connect();
        await _waitForWebSocketConnection(timeout: const Duration(seconds: 5));
        emit(state.copyWith(isWebSocketDegraded: false));
      } catch (e) {
        log('Failed to connect WebSocket: $e');
        emit(state.copyWith(isWebSocketDegraded: true));
      }
    } else {
      emit(state.copyWith(isWebSocketDegraded: false));
    }

    _webSocketService.subscribeToUserChannel(event.userId);
    log('Subscribed to user channel: ${event.userId}');

    _chatRoomUpdateSubscription = _webSocketService.chatRoomUpdates.listen(
      (update) {
        log('Received chatRoomUpdate: roomId=${update.chatRoomId}, unreadCount=${update.unreadCount}');
        add(ChatRoomUpdated(
          chatRoomId: update.chatRoomId,
          eventType: update.eventType,
          lastMessage: update.lastMessage,
          lastMessageType: update.lastMessageType,
          lastMessageAt: update.lastMessageAt,
          unreadCount: update.unreadCount,
          senderId: update.senderId,
        ));
      },
      onError: (error) {
        log('Error in chatRoomUpdates stream: $error');
      },
      cancelOnError: false,
    );

    _readReceiptSubscription = _webSocketService.readEvents.listen(
      (readEvent) {
        log('Received readEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
      },
      onError: (error) {
        log('Error in readEvents stream: $error');
      },
      cancelOnError: false,
    );

    _onlineStatusSubscription = _webSocketService.onlineStatusEvents.listen(
      (event) {
        log('Received onlineStatusEvent: userId=${event.userId}, isOnline=${event.isOnline}');
        add(UserOnlineStatusChanged(
          userId: event.userId,
          isOnline: event.isOnline,
          lastActiveAt: event.lastActiveAt,
        ));
      },
      onError: (error) {
        log('Error in onlineStatusEvents stream: $error');
      },
      cancelOnError: false,
    );
  }

  void _onSubscriptionStopped(
    ChatListSubscriptionStopped event,
    Emitter<ChatListState> emit,
  ) {
    log('_onSubscriptionStopped');
    _chatRoomUpdateSubscription?.cancel();
    _chatRoomUpdateSubscription = null;
    _readReceiptSubscription?.cancel();
    _readReceiptSubscription = null;
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = null;
  }

  void _onResetRequested(
    ChatListResetRequested event,
    Emitter<ChatListState> emit,
  ) {
    log('_onResetRequested: clearing all state');
    _chatRoomUpdateSubscription?.cancel();
    _chatRoomUpdateSubscription = null;
    _readReceiptSubscription?.cancel();
    _readReceiptSubscription = null;
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = null;
    _refreshDebounceTimer?.cancel();
    _currentUserId = null;
    _currentlyOpenRoomId = null;
    _isRefreshing = false;
    emit(const ChatListState());
  }

  void _onChatRoomReadCompleted(
    ChatRoomReadCompleted event,
    Emitter<ChatListState> emit,
  ) {
    log('_onChatRoomReadCompleted: roomId=${event.chatRoomId}');

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        log('Optimistically updating unreadCount: ${room.unreadCount} -> 0');
        return room.copyWith(unreadCount: 0);
      }
      return room;
    }).toList();

    emit(state.copyWith(chatRooms: updatedChatRooms));
  }

  void _onChatRoomEntered(
    ChatRoomEntered event,
    Emitter<ChatListState> emit,
  ) {
    log('_onChatRoomEntered: roomId=${event.chatRoomId}');
    _currentlyOpenRoomId = event.chatRoomId;
  }

  void _onChatRoomExited(
    ChatRoomExited event,
    Emitter<ChatListState> emit,
  ) {
    log('_onChatRoomExited: clearing currentlyOpenRoomId (was: $_currentlyOpenRoomId)');
    _currentlyOpenRoomId = null;
  }

  void _onUserOnlineStatusChanged(
    UserOnlineStatusChanged event,
    Emitter<ChatListState> emit,
  ) {
    log('_onUserOnlineStatusChanged: userId=${event.userId}, isOnline=${event.isOnline}');

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.otherUserId == event.userId) {
        return room.copyWith(
          isOtherUserOnline: event.isOnline,
          otherUserLastActiveAt: event.lastActiveAt,
        );
      }
      return room;
    }).toList();

    emit(state.copyWith(chatRooms: updatedChatRooms));
  }

  @override
  Future<void> close() {
    _chatRoomUpdateSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _refreshDebounceTimer?.cancel();
    return super.close();
  }

  Future<void> _waitForWebSocketConnection({
    required Duration timeout,
  }) async {
    if (_webSocketService.isConnected ||
        _webSocketService.currentConnectionState == WebSocketConnectionState.connected) {
      return;
    }

    final completer = Completer<void>();
    StreamSubscription<WebSocketConnectionState>? subscription;

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError(
          TimeoutException('WebSocket connection timeout', timeout),
        );
      }
    });

    subscription = _webSocketService.connectionState.listen((state) {
      log('WebSocket connection state changed: $state');
      if (state == WebSocketConnectionState.connected) {
        if (!completer.isCompleted) {
          timer.cancel();
          subscription?.cancel();
          completer.complete();
        }
      }
    });

    try {
      await completer.future;
      log('WebSocket connection established');
    } catch (e) {
      log('WebSocket connection wait failed: $e');
      rethrow;
    }
  }

}
