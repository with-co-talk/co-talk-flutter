import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/repositories/friend_repository.dart';
import 'friend_event.dart';
import 'friend_state.dart';

@injectable
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepository _friendRepository;

  FriendBloc(this._friendRepository) : super(const FriendState()) {
    on<FriendListLoadRequested>(_onLoadRequested);
    on<FriendRequestSent>(_onRequestSent);
    on<FriendRequestAccepted>(_onRequestAccepted);
    on<FriendRequestRejected>(_onRequestRejected);
    on<FriendRemoved>(_onRemoved);
    on<UserSearchRequested>(_onSearchRequested);
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
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRequestSent(
    FriendRequestSent event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await _friendRepository.sendFriendRequest(event.receiverId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onRequestAccepted(
    FriendRequestAccepted event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await _friendRepository.acceptFriendRequest(event.requestId);
      add(const FriendListLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onRequestRejected(
    FriendRequestRejected event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await _friendRepository.rejectFriendRequest(event.requestId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSearchRequested(
    UserSearchRequested event,
    Emitter<FriendState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));

    try {
      final users = await _friendRepository.searchUsers(event.query);
      emit(state.copyWith(
        searchResults: users,
        isSearching: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
