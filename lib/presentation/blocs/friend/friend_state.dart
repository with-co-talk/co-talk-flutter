import 'package:equatable/equatable.dart';
import '../../../domain/entities/friend.dart';
import '../../../domain/entities/user.dart';

enum FriendStatus { initial, loading, success, failure }

class FriendState extends Equatable {
  final FriendStatus status;
  final List<Friend> friends;
  final List<User> searchResults;
  final bool isSearching;
  final String? errorMessage;

  const FriendState({
    this.status = FriendStatus.initial,
    this.friends = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.errorMessage,
  });

  FriendState copyWith({
    FriendStatus? status,
    List<Friend>? friends,
    List<User>? searchResults,
    bool? isSearching,
    String? errorMessage,
  }) {
    return FriendState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        friends,
        searchResults,
        isSearching,
        errorMessage,
      ];
}
