import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/websocket_service.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

@injectable
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;

  StreamSubscription<WebSocketChatRoomUpdateEvent>? _chatRoomUpdateSubscription;
  StreamSubscription<WebSocketReadEvent>? _readReceiptSubscription;
  int? _currentUserId;
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
    // 이미 리프레시 중이면 무시
    if (_isRefreshing) {
      // ignore: avoid_print
      print('[ChatListBloc] Already refreshing, skipping duplicate request');
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

  /// debounce를 적용하여 채팅방 목록 리프레시를 예약합니다.
  void _scheduleRefresh() {
    // 기존 타이머 취소
    _refreshDebounceTimer?.cancel();

    // 300ms 후에 리프레시 실행 (짧은 시간 내 여러 요청이 오면 마지막 것만 실행)
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
    // ignore: avoid_print
    print('[ChatListBloc] _onChatRoomUpdated: roomId=${event.chatRoomId}, lastMessage=${event.lastMessage}, unreadCount=${event.unreadCount}, senderId=${event.senderId}');

    // 현재 사용자 ID 확인 (없으면 가져오기)
    _currentUserId ??= await _authLocalDataSource.getUserId();

    // 기존 채팅방 찾기
    final existingRoomIndex = state.chatRooms.indexWhere((room) => room.id == event.chatRoomId);
    
    if (existingRoomIndex < 0) {
      // 새 채팅방인 경우 (서버에서 새 메시지가 왔지만 목록에 없는 경우)
      // debounce를 적용하여 중복 리프레시 방지
      // ignore: avoid_print
      print('[ChatListBloc] New chat room detected (roomId=${event.chatRoomId}), scheduling refresh...');
      _scheduleRefresh();
      return;
    }

    // 기존 채팅방 업데이트
    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        // 내가 보낸 메시지면 unreadCount는 0으로 설정
        int? unreadCount = event.unreadCount;
        if (event.senderId != null && _currentUserId != null && event.senderId == _currentUserId) {
          // ignore: avoid_print
          print('[ChatListBloc] Last message is from current user, setting unreadCount to 0');
          unreadCount = 0;
        }

        return room.copyWith(
          lastMessage: event.lastMessage ?? room.lastMessage,
          lastMessageAt: event.lastMessageAt ?? room.lastMessageAt,
          unreadCount: unreadCount ?? room.unreadCount,
        );
      }
      return room;
    }).toList();

    // 마지막 메시지 시간 기준으로 정렬 (최신순)
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
    // ignore: avoid_print
    print('[ChatListBloc] _onSubscriptionStarted: userId=${event.userId}');
    // ignore: avoid_print
    print('[ChatListBloc] WebSocket connected: ${_webSocketService.isConnected}');
    // ignore: avoid_print
    print('[ChatListBloc] WebSocket connection state: ${_webSocketService.currentConnectionState}');

    // 현재 사용자 ID 저장
    _currentUserId = event.userId;

    // 기존 구독 해제
    _chatRoomUpdateSubscription?.cancel();

    // WebSocket 연결 확인 및 연결 시도
    if (!_webSocketService.isConnected) {
      // ignore: avoid_print
      print('[ChatListBloc] WebSocket not connected, attempting to connect...');
      try {
        await _webSocketService.connect();
        // ignore: avoid_print
        print('[ChatListBloc] WebSocket connection initiated');

        // 실제 연결 완료를 대기 (최대 5초)
        await _waitForWebSocketConnection(timeout: const Duration(seconds: 5));
      } catch (e) {
        // ignore: avoid_print
        print('[ChatListBloc] Failed to connect WebSocket: $e');
        // 연결 실패해도 계속 진행 (나중에 재연결 시도)
      }
    }

    // 사용자 채널 구독
    _webSocketService.subscribeToUserChannel(event.userId);
    // ignore: avoid_print
    print('[ChatListBloc] Subscribed to user channel: $event.userId');

    // 채팅방 업데이트 리스너
    _chatRoomUpdateSubscription = _webSocketService.chatRoomUpdates.listen(
      (update) {
        // ignore: avoid_print
        print('[ChatListBloc] Received chatRoomUpdate: roomId=${update.chatRoomId}, lastMessage=${update.lastMessage}, unreadCount=${update.unreadCount}, senderId=${update.senderId}');
        add(ChatRoomUpdated(
          chatRoomId: update.chatRoomId,
          lastMessage: update.lastMessage,
          lastMessageAt: update.lastMessageAt,
          unreadCount: update.unreadCount,
          senderId: update.senderId,
        ));
      },
      onError: (error) {
        // ignore: avoid_print
        print('[ChatListBloc] Error in chatRoomUpdates stream: $error');
        emit(state.copyWith(
          errorMessage: '채팅방 업데이트 수신 중 오류가 발생했습니다: ${error.toString()}',
        ));
      },
      cancelOnError: false, // 에러 발생해도 스트림 유지
    );

    // 읽음 영수증 리스너 (내가 읽은 경우 unreadCount를 0으로)
    _readReceiptSubscription = _webSocketService.readEvents.listen(
      (readEvent) {
        // ignore: avoid_print
        print('[ChatListBloc] Received readEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
        // 내가 읽은 경우에만 처리
        if (readEvent.userId == _currentUserId) {
          add(ChatRoomReadCompleted(readEvent.chatRoomId));
        }
      },
      onError: (error) {
        // ignore: avoid_print
        print('[ChatListBloc] Error in readEvents stream: $error');
      },
      cancelOnError: false,
    );
  }

  void _onSubscriptionStopped(
    ChatListSubscriptionStopped event,
    Emitter<ChatListState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatListBloc] _onSubscriptionStopped');
    _chatRoomUpdateSubscription?.cancel();
    _chatRoomUpdateSubscription = null;
    _readReceiptSubscription?.cancel();
    _readReceiptSubscription = null;
    _webSocketService.unsubscribeFromUserChannel();
  }

  void _onChatRoomReadCompleted(
    ChatRoomReadCompleted event,
    Emitter<ChatListState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatListBloc] _onChatRoomReadCompleted: roomId=${event.chatRoomId}');

    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        return room.copyWith(unreadCount: 0);
      }
      return room;
    }).toList();

    emit(state.copyWith(chatRooms: updatedChatRooms));
  }

  @override
  Future<void> close() {
    _chatRoomUpdateSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _refreshDebounceTimer?.cancel();
    return super.close();
  }

  /// WebSocket 연결 완료를 대기합니다.
  Future<void> _waitForWebSocketConnection({
    required Duration timeout,
  }) async {
    if (_webSocketService.isConnected) return;

    final completer = Completer<void>();
    StreamSubscription<WebSocketConnectionState>? subscription;

    // 타임아웃 타이머
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError(
          TimeoutException('WebSocket connection timeout', timeout),
        );
      }
    });

    // 연결 상태 스트림 구독
    subscription = _webSocketService.connectionState.listen((state) {
      // ignore: avoid_print
      print('[ChatListBloc] WebSocket connection state changed: $state');
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
      // ignore: avoid_print
      print('[ChatListBloc] WebSocket connection established');
    } catch (e) {
      // ignore: avoid_print
      print('[ChatListBloc] WebSocket connection wait failed: $e');
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
    // 알 수 없는 에러의 경우
    return error.toString();
  }
}
