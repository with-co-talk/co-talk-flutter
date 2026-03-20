import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/friend_repository.dart';
import 'friend_event.dart';
import 'friend_state.dart';

@injectable
class FriendBloc extends Bloc<FriendEvent, FriendState> with DebugLogger {
  final FriendRepository _friendRepository;
  final WebSocketService _webSocketService;

  StreamSubscription<WebSocketOnlineStatusEvent>? _onlineStatusSubscription;
  StreamSubscription<WebSocketProfileUpdateEvent>? _profileUpdateSubscription;

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
    on<FriendProfileUpdated>(_onFriendProfileUpdated);
    on<FriendListSubscriptionStarted>(_onSubscriptionStarted);
    on<FriendListSubscriptionStopped>(_onSubscriptionStopped);
    on<HideFriendRequested>(_onHideFriendRequested);
    on<UnhideFriendRequested>(_onUnhideFriendRequested);
    on<HiddenFriendsLoadRequested>(_onHiddenFriendsLoadRequested);
    on<BlockUserRequested>(_onBlockUserRequested);
    on<UnblockUserRequested>(_onUnblockUserRequested);
    on<BlockedUsersLoadRequested>(_onBlockedUsersLoadRequested);
  }

  void _onSubscriptionStarted(
    FriendListSubscriptionStarted event,
    Emitter<FriendState> emit,
  ) {
    log('Subscription started');
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = _webSocketService.onlineStatusEvents.listen((wsEvent) {
      log('Received online status: userId=${wsEvent.userId}, isOnline=${wsEvent.isOnline}');
      add(FriendOnlineStatusChanged(
        userId: wsEvent.userId,
        isOnline: wsEvent.isOnline,
        lastActiveAt: wsEvent.lastActiveAt,
      ));
    });

    _profileUpdateSubscription?.cancel();
    _profileUpdateSubscription = _webSocketService.profileUpdateEvents.listen((wsEvent) {
      log('Received profile update: userId=${wsEvent.userId}, avatarUrl=${wsEvent.avatarUrl}');
      add(FriendProfileUpdated(
        userId: wsEvent.userId,
        avatarUrl: wsEvent.avatarUrl,
        backgroundUrl: wsEvent.backgroundUrl,
        statusMessage: wsEvent.statusMessage,
      ));
    });
  }

  void _onSubscriptionStopped(
    FriendListSubscriptionStopped event,
    Emitter<FriendState> emit,
  ) {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = null;
    _profileUpdateSubscription?.cancel();
    _profileUpdateSubscription = null;
  }

  void _onFriendOnlineStatusChanged(
    FriendOnlineStatusChanged event,
    Emitter<FriendState> emit,
  ) {
    log('Online status changed: userId=${event.userId}, isOnline=${event.isOnline}');

    final updatedFriends = state.friends.map((friend) {
      if (friend.user.id == event.userId) {
        log('Updating friend: ${friend.user.nickname}');
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
  }

  void _onFriendProfileUpdated(
    FriendProfileUpdated event,
    Emitter<FriendState> emit,
  ) {
    log('Profile updated: userId=${event.userId}, avatarUrl=${event.avatarUrl}');

    final updatedFriends = state.friends.map((friend) {
      if (friend.user.id == event.userId) {
        log('Updating friend profile: ${friend.user.nickname}');
        return friend.copyWith(
          user: friend.user.copyWith(
            avatarUrl: event.avatarUrl,
            backgroundUrl: event.backgroundUrl,
            statusMessage: event.statusMessage,
          ),
        );
      }
      return friend;
    }).toList();

    emit(state.copyWith(friends: updatedFriends));
  }

  @override
  Future<void> close() {
    _onlineStatusSubscription?.cancel();
    _profileUpdateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    FriendListLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(status: FriendStatus.loading));

    try {
      final friends = await _friendRepository.getFriends();
      // 숨긴 친구는 목록에서 제외
      final visibleFriends = friends.where((f) => !f.isHidden).toList();
      emit(state.copyWith(
        status: FriendStatus.success,
        friends: visibleFriends,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FriendStatus.failure,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
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
      final sentRequests = await _friendRepository.getSentFriendRequests();
      emit(state.copyWith(
        sentRequests: sentRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onRequestAccepted(
    FriendRequestAccepted event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.acceptFriendRequest(event.requestId);
      final friends = await _friendRepository.getFriends();
      // 숨긴 친구는 목록에서 제외
      final visibleFriends = friends.where((f) => !f.isHidden).toList();
      final receivedRequests = await _friendRepository.getReceivedFriendRequests();
      emit(state.copyWith(
        status: FriendStatus.success,
        friends: visibleFriends,
        receivedRequests: receivedRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onRequestRejected(
    FriendRequestRejected event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.rejectFriendRequest(event.requestId);
      final receivedRequests = await _friendRepository.getReceivedFriendRequests();
      emit(state.copyWith(
        receivedRequests: receivedRequests,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
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
      emit(state.copyWith(
        friends: updatedFriends,
        successMessage: '친구를 삭제했습니다',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
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
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
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
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
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
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onHideFriendRequested(
    HideFriendRequested event,
    Emitter<FriendState> emit,
  ) async {
    // 낙관적 UI: 즉시 목록에서 제거
    final previousFriends = state.friends;
    final optimisticFriends = state.friends
        .where((f) => f.user.id != event.friendId)
        .toList();
    emit(state.copyWith(friends: optimisticFriends, clearErrorMessage: true));

    try {
      await _friendRepository.hideFriend(event.friendId);
    } catch (e) {
      // 실패 시 이전 목록 복원
      emit(state.copyWith(
        friends: previousFriends,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onUnhideFriendRequested(
    UnhideFriendRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.unhideFriend(event.friendId);
      final hiddenFriends = await _friendRepository.getHiddenFriends();
      emit(state.copyWith(
        hiddenFriends: hiddenFriends,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onHiddenFriendsLoadRequested(
    HiddenFriendsLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(
      isHiddenFriendsLoading: true,
      clearErrorMessage: true,
    ));
    try {
      final hiddenFriends = await _friendRepository.getHiddenFriends();
      emit(state.copyWith(
        hiddenFriends: hiddenFriends,
        isHiddenFriendsLoading: false,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isHiddenFriendsLoading: false,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onBlockUserRequested(
    BlockUserRequested event,
    Emitter<FriendState> emit,
  ) async {
    // 낙관적 UI: 즉시 목록에서 제거
    final previousFriends = state.friends;
    final optimisticFriends = state.friends
        .where((f) => f.user.id != event.userId)
        .toList();
    emit(state.copyWith(friends: optimisticFriends, clearErrorMessage: true));

    try {
      await _friendRepository.blockUser(event.userId);
    } catch (e) {
      // 실패 시 이전 목록 복원
      emit(state.copyWith(
        friends: previousFriends,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onUnblockUserRequested(
    UnblockUserRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true));
    try {
      await _friendRepository.unblockUser(event.userId);
      final blockedUsers = await _friendRepository.getBlockedUsers();
      emit(state.copyWith(
        blockedUsers: blockedUsers,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onBlockedUsersLoadRequested(
    BlockedUsersLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(
      isBlockedUsersLoading: true,
      clearErrorMessage: true,
    ));
    try {
      final blockedUsers = await _friendRepository.getBlockedUsers();
      emit(state.copyWith(
        blockedUsers: blockedUsers,
        isBlockedUsersLoading: false,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isBlockedUsersLoading: false,
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

}
