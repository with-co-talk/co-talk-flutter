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
  int? _currentlyOpenRoomId; // 현재 열려있는 채팅방 ID (unreadCount 증가 방지용)
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
    // 서버가 WebSocket으로 보내주는 unreadCount를 그대로 사용
    // 서버는 이미 읽은 사람 수를 제외한 값을 보내줌:
    // - 메시지 전송 시: 채팅방 인원 수로 시작
    // - 내가 보냈으면: 나를 제외 (-1)
    // - 상대방이 채팅방에 열려있으면: 상대방도 제외 (-1)
    // - 읽음 처리 완료 후: 서버가 업데이트된 unreadCount를 chatRoomUpdates로 전송
    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == event.chatRoomId) {
        // 서버가 정확한 unreadCount를 계산해서 보내주므로, 클라이언트는 그대로 사용
        // 서버는 이미 다음을 모두 고려해서 계산함:
        // - READ 이벤트: lastReadMessageId 기반으로 정확한 unreadCount 계산
        // - NEW_MESSAGE 이벤트: presence(방이 열려있는지)를 고려하여 unreadCount 계산
        // - 발신자 제외: 내가 보낸 메시지는 서버에서 이미 제외하여 계산
        // 따라서 클라이언트는 서버가 보낸 값을 그대로 사용하면 됨
        final oldUnreadCount = room.unreadCount;
        int newUnreadCount = event.unreadCount ?? room.unreadCount;
        
        if (event.unreadCount != null) {
          newUnreadCount = event.unreadCount!;
          // ignore: avoid_print
          print('[ChatListBloc] Using server unreadCount=${event.unreadCount} (eventType=${event.eventType})');
        } else {
          // 서버가 unreadCount를 보내지 않았으면 기존 값 유지 (안전장치)
          // ignore: avoid_print
          print('[ChatListBloc] WARNING: unreadCount is null, keeping old value=${oldUnreadCount}');
        }
        
        // ignore: avoid_print
        print('[ChatListBloc] ========== Updating room ==========');
        // ignore: avoid_print
        print('[ChatListBloc] roomId: ${event.chatRoomId}');
        // ignore: avoid_print
        print('[ChatListBloc] old unreadCount: $oldUnreadCount');
        // ignore: avoid_print
        print('[ChatListBloc] new unreadCount: $newUnreadCount');
        // ignore: avoid_print
        print('[ChatListBloc] unreadCount from server: ${event.unreadCount}');
        // ignore: avoid_print
        print('[ChatListBloc] senderId: ${event.senderId}');
        // ignore: avoid_print
        print('[ChatListBloc] currentUserId: $_currentUserId');
        // ignore: avoid_print
        print('[ChatListBloc] ===================================');

        return room.copyWith(
          lastMessage: event.lastMessage ?? room.lastMessage,
          lastMessageAt: event.lastMessageAt ?? room.lastMessageAt,
          unreadCount: newUnreadCount,
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
        print('[ChatListBloc] ========== Received chatRoomUpdate ==========');
        // ignore: avoid_print
        print('[ChatListBloc] roomId: ${update.chatRoomId}');
        // ignore: avoid_print
        print('[ChatListBloc] lastMessage: ${update.lastMessage}');
        // ignore: avoid_print
        print('[ChatListBloc] unreadCount: ${update.unreadCount} (from server)');
        // ignore: avoid_print
        print('[ChatListBloc] senderId: ${update.senderId}');
        // ignore: avoid_print
        print('[ChatListBloc] lastMessageAt: ${update.lastMessageAt}');
        // ignore: avoid_print
        print('[ChatListBloc] Current userId: $_currentUserId');
        // ignore: avoid_print
        print('[ChatListBloc] Currently open room: $_currentlyOpenRoomId');
        // ignore: avoid_print
        print('[ChatListBloc] =============================================');
        add(ChatRoomUpdated(
          chatRoomId: update.chatRoomId,
          eventType: update.eventType,
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

    // 읽음 영수증 리스너 (읽음 확인용, unreadCount는 chatRoomUpdates로 처리)
    // 서버가 읽음 처리 완료 후 chatRoomUpdates로 업데이트된 unreadCount를 전송하므로
    // readEvents는 읽음 확인용으로만 사용 (필요시 다른 용도로 활용 가능)
    _readReceiptSubscription = _webSocketService.readEvents.listen(
      (readEvent) {
        // ignore: avoid_print
        print('[ChatListBloc] Received readEvent: roomId=${readEvent.chatRoomId}, userId=${readEvent.userId}');
        // 서버가 chatRoomUpdates로 unreadCount를 업데이트하므로 별도 처리 불필요
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
    // 서버가 markAsRead 후 READ 이벤트로 정확한 unreadCount를 보내주므로
    // 클라이언트에서 별도로 처리할 필요 없음
    // 서버의 READ 이벤트가 도착하면 자동으로 업데이트됨
  }

  void _onChatRoomEntered(
    ChatRoomEntered event,
    Emitter<ChatListState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatListBloc] _onChatRoomEntered: roomId=${event.chatRoomId}');
    // 현재 열려있는 채팅방 ID 저장 (다른 용도로 사용할 수 있으므로 유지)
    _currentlyOpenRoomId = event.chatRoomId;
    
    // 서버가 정확한 unreadCount를 계산해서 보내주므로, 클라이언트는 낙관적 업데이트 불필요
    // 서버의 READ 이벤트가 도착하면 자동으로 업데이트됨
    // (서버가 presence를 고려하여 이미 정확한 값을 계산해서 보냄)
  }

  void _onChatRoomExited(
    ChatRoomExited event,
    Emitter<ChatListState> emit,
  ) {
    // ignore: avoid_print
    print('[ChatListBloc] _onChatRoomExited: previous roomId=$_currentlyOpenRoomId');
    _currentlyOpenRoomId = null;
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
    // 일부 환경(테스트 더블)에서는 connectionState 스트림을 제공하지 않을 수 있으므로,
    // 현재 연결 상태가 connected면 즉시 반환한다.
    if (_webSocketService.isConnected ||
        _webSocketService.currentConnectionState == WebSocketConnectionState.connected) {
      return;
    }

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
