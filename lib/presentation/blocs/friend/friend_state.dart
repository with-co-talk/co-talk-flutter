import 'package:equatable/equatable.dart';
import '../../../domain/entities/friend.dart';
import '../../../domain/entities/user.dart';

enum FriendStatus { initial, loading, success, failure }

class FriendState extends Equatable {
  final FriendStatus status;
  final List<Friend> friends;
  final List<FriendRequest> receivedRequests;
  final List<FriendRequest> sentRequests;
  final List<User> searchResults;
  final bool isSearching;
  final String? errorMessage;
  final bool hasSearched;
  final String? searchQuery;

  const FriendState({
    this.status = FriendStatus.initial,
    this.friends = const [],
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.errorMessage,
    this.hasSearched = false,
    this.searchQuery,
  });

  FriendState copyWith({
    FriendStatus? status,
    List<Friend>? friends,
    List<FriendRequest>? receivedRequests,
    List<FriendRequest>? sentRequests,
    List<User>? searchResults,
    bool? isSearching,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? hasSearched,
    String? searchQuery,
    bool clearSearchQuery = false,
  }) {
    return FriendState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      hasSearched: hasSearched ?? this.hasSearched,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [
        status,
        friends,
        receivedRequests,
        sentRequests,
        searchResults,
        isSearching,
        errorMessage,
        hasSearched,
        searchQuery,
      ];
}
