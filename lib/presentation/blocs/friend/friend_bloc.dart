import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/websocket_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/friend_repository.dart';
import 'friend_event.dart';
import 'friend_state.dart';

@injectable
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepository _friendRepository;
  final WebSocketService _webSocketService;

  StreamSubscription<WebSocketOnlineStatusEvent>? _onlineStatusSubscription;

  FriendBloc(this._friendRepository, this._webSocketService) : super(const FriendState()) {
    on<FriendListLoadRequested>(_onLoadRequested);
    on<FriendRequestSent>(_onRequestSent);
    on<FriendRequestAccepted>(_onRequestAccepted);
    on<FriendRequestRejected>(_onRequestRejected);
    on<FriendRemoved>(_onRemoved);
    on<UserSearchRequested>(_onSearchRequested);
    on<ReceivedFriendRequestsLoadRequested>(_onReceivedRequestsLoadRequested);
    on<SentFriendRequestsLoadRequested>(_onSentRequestsLoadRequested);
    on<FriendOnlineStatusChanged>(_onFriendOnlineStatusChanged);
    on<FriendListSubscriptionStarted>(_onSubscriptionStarted);
    on<FriendListSubscriptionStopped>(_onSubscriptionStopped);
  }

  void _onSubscriptionStarted(
    FriendListSubscriptionStarted event,
    Emitter<FriendState> emit,
  ) {
    // ignore: avoid_print
    print('[FriendBloc] ========== Subscription Started ==========');
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = _webSocketService.onlineStatusEvents.listen((wsEvent) {
      // ignore: avoid_print
      print('[FriendBloc] ✅ Received online status event: userId=${wsEvent.userId}, isOnline=${wsEvent.isOnline}');
      add(FriendOnlineStatusChanged(
        userId: wsEvent.userId,
        isOnline: wsEvent.isOnline,
        lastActiveAt: wsEvent.lastActiveAt,
      ));
    });
    // ignore: avoid_print
    print('[FriendBloc] ✅ Subscribed to onlineStatusEvents stream');
  }

  void _onSubscriptionStopped(
    FriendListSubscriptionStopped event,
    Emitter<FriendState> emit,
  ) {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = null;
  }

  void _onFriendOnlineStatusChanged(
    FriendOnlineStatusChanged event,
    Emitter<FriendState> emit,
  ) {
    // ignore: avoid_print
    print('[FriendBloc] ========== Online Status Changed ==========');
    // ignore: avoid_print
    print('[FriendBloc] userId: ${event.userId}, isOnline: ${event.isOnline}');
    // ignore: avoid_print
    print('[FriendBloc] Current friends count: ${state.friends.length}');
    // ignore: avoid_print
    print('[FriendBloc] Friend IDs: ${state.friends.map((f) => f.user.id).toList()}');

    final updatedFriends = state.friends.map((friend) {
      if (friend.user.id == event.userId) {
        // ignore: avoid_print
        print('[FriendBloc] ✅ Found matching friend: ${friend.user.nickname}');
        return friend.copyWith(
          user: friend.user.copyWith(
            onlineStatus: event.isOnline ? OnlineStatus.online : OnlineStatus.offline,
            lastActiveAt: event.lastActiveAt,
          ),
        );
      }
      return friend;
    }).toList();

    emit(state.copyWith(friends: updatedFriends));
    // ignore: avoid_print
    print('[FriendBloc] ✅ Emitted new state with updated friends');
  }

  @override
  Future<void> close() {
    _onlineStatusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    FriendListLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(status: FriendStatus.loading));

    try {
      final friends = await _friendRepository.getFriends();
      emit(state.copyWith(
        status: FriendStatus.success,
        friends: friends,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FriendStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onRequestSent(
    FriendRequestSent event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.sendFriendRequest(event.receiverId);
      // 성공 시 보낸 요청 목록도 업데이트
      final sentRequests = await _friendRepository.getSentFriendRequests();
      emit(state.copyWith(
        sentRequests: sentRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
    }
  }

  Future<void> _onRequestAccepted(
    FriendRequestAccepted event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.acceptFriendRequest(event.requestId);
      // 친구 목록과 받은 요청 목록을 모두 새로고침
      final friends = await _friendRepository.getFriends();
      final receivedRequests = await _friendRepository.getReceivedFriendRequests();
      emit(state.copyWith(
        status: FriendStatus.success,
        friends: friends,
        receivedRequests: receivedRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
    }
  }

  Future<void> _onRequestRejected(
    FriendRequestRejected event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.rejectFriendRequest(event.requestId);
      // 받은 요청 목록 새로고침
      final receivedRequests = await _friendRepository.getReceivedFriendRequests();
      emit(state.copyWith(
        receivedRequests: receivedRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
    }
  }

  Future<void> _onRemoved(
    FriendRemoved event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await _friendRepository.removeFriend(event.friendId);
      final updatedFriends = state.friends
          .where((f) => f.user.id != event.friendId)
          .toList();
      emit(state.copyWith(friends: updatedFriends));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
    }
  }

  Future<void> _onSearchRequested(
    UserSearchRequested event,
    Emitter<FriendState> emit,
  ) async {
    final trimmedQuery = event.query.trim();

    if (trimmedQuery.isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        isSearching: false,
        hasSearched: false,
        clearSearchQuery: true,
        clearErrorMessage: true,
      ));
      return;
    }

    emit(state.copyWith(
      isSearching: true,
      hasSearched: true,
      searchQuery: trimmedQuery,
      clearErrorMessage: true,
    ));

    try {
      final users = await _friendRepository.searchUsers(trimmedQuery);
      emit(state.copyWith(
        searchResults: users,
        isSearching: false,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        searchResults: [],
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onReceivedRequestsLoadRequested(
    ReceivedFriendRequestsLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      final requests = await _friendRepository.getReceivedFriendRequests();
      emit(state.copyWith(
        receivedRequests: requests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
    }
  }

  Future<void> _onSentRequestsLoadRequested(
    SentFriendRequestsLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      final requests = await _friendRepository.getSentFriendRequests();
      emit(state.copyWith(
        sentRequests: requests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: _extractErrorMessage(e)));
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
