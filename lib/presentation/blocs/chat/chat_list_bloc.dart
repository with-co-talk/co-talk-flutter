import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/websocket_service.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

@lazySingleton
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
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
    on<UserOnlineStatusChanged>(_onUserOnlineStatusChanged);
  }

  /// 디버그 모드에서만 로그 출력
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ChatListBloc] $message');
    }
  }

  Future<void> _onLoadRequested(
    ChatListLoadRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));

    try {
      final chatRooms = await _chatRepository.getChatRooms();
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: chatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    ChatListRefreshRequested event,
    Emitter<ChatListState> emit,
  ) async {
    if (_isRefreshing) {
      _log('Already refreshing, skipping duplicate request');
      return;
    }

    _isRefreshing = true;
    try {
      final chatRooms = await _chatRepository.getChatRooms();
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: chatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    } finally {
      _isRefreshing = false;
    }
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
        errorMessage: _extractErrorMessage(e),
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
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  void _onChatRoomUpdated(
    ChatRoomUpdated event,
    Emitter<ChatListState> emit,
  ) async {
    _log('_onChatRoomUpdated: roomId=${event.chatRoomId}, unreadCount=${event.unreadCount}');

    _currentUserId ??= await _authLocalDataSource.getUserId();

    final existingRoomIndex = state.chatRooms.indexWhere((room) => room.id == event.chatRoomId);

    if (existingRoomIndex < 0) {
      _log('New chat room detected (roomId=${event.chatRoomId}), scheduling refresh...');
      _scheduleRefresh();
      return;
    }

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        final newUnreadCount = event.unreadCount ?? room.unreadCount;
        _log('Updating room ${event.chatRoomId}: unreadCount ${room.unreadCount} -> $newUnreadCount');

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

  void _onSubscriptionStarted(
    ChatListSubscriptionStarted event,
    Emitter<ChatListState> emit,
  ) async {
    _log('_onSubscriptionStarted: userId=${event.userId}');

    _currentUserId = event.userId;
    _chatRoomUpdateSubscription?.cancel();

    if (!_webSocketService.isConnected) {
      _log('WebSocket not connected, attempting to connect...');
      try {
        await _webSocketService.connect();
        await _waitForWebSocketConnection(timeout: const Duration(seconds: 5));
      } catch (e) {
        _log('Failed to connect WebSocket: $e');
      }
    }

    _webSocketService.subscribeToUserChannel(event.userId);
    _log('Subscribed to user channel: ${event.userId}');

    _chatRoomUpdateSubscription = _webSocketService.chatRoomUpdates.listen(
      (update) {
        _log('Received chatRoomUpdate: roomId=${update.chatRoomId}, unreadCount=${update.unreadCount}');
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
        _log('Error in chatRoomUpdates stream: $error');
        emit(state.copyWith(
          errorMessage: '채팅방 업데이트 수신 중 오류가 발생했습니다: ${error.toString()}',
        ));
      },
      cancelOnError: false,
    );

    _readReceiptSubscription = _webSocketService.readEvents.listen(
      (readEvent) {
        _log('Received readEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
      },
      onError: (error) {
        _log('Error in readEvents stream: $error');
      },
      cancelOnError: false,
    );

    _onlineStatusSubscription = _webSocketService.onlineStatusEvents.listen(
      (event) {
        _log('Received onlineStatusEvent: userId=${event.userId}, isOnline=${event.isOnline}');
        add(UserOnlineStatusChanged(
          userId: event.userId,
          isOnline: event.isOnline,
          lastActiveAt: event.lastActiveAt,
        ));
      },
      onError: (error) {
        _log('Error in onlineStatusEvents stream: $error');
      },
      cancelOnError: false,
    );
  }

  void _onSubscriptionStopped(
    ChatListSubscriptionStopped event,
    Emitter<ChatListState> emit,
  ) {
    _log('_onSubscriptionStopped');
    _chatRoomUpdateSubscription?.cancel();
    _chatRoomUpdateSubscription = null;
    _readReceiptSubscription?.cancel();
    _readReceiptSubscription = null;
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = null;
  }

  void _onChatRoomReadCompleted(
    ChatRoomReadCompleted event,
    Emitter<ChatListState> emit,
  ) {
    _log('_onChatRoomReadCompleted: roomId=${event.chatRoomId}');

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        _log('Optimistically updating unreadCount: ${room.unreadCount} -> 0');
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
    _log('_onChatRoomEntered: roomId=${event.chatRoomId}');
    _currentlyOpenRoomId = event.chatRoomId;
  }

  void _onChatRoomExited(
    ChatRoomExited event,
    Emitter<ChatListState> emit,
  ) {
    _log('_onChatRoomExited: previous roomId=$_currentlyOpenRoomId');
    _currentlyOpenRoomId = null;
  }

  void _onUserOnlineStatusChanged(
    UserOnlineStatusChanged event,
    Emitter<ChatListState> emit,
  ) {
    _log('_onUserOnlineStatusChanged: userId=${event.userId}, isOnline=${event.isOnline}');

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
      _log('WebSocket connection state changed: $state');
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
      _log('WebSocket connection established');
    } catch (e) {
      _log('WebSocket connection wait failed: $e');
      rethrow;
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is ServerException) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is ValidationException) {
      return error.message;
    }
    if (error is CacheException) {
      return error.message;
    }
    return error.toString();
  }
}
