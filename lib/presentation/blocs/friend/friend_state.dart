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
  final List<Friend> hiddenFriends;
  final List<User> blockedUsers;
  final bool isHiddenFriendsLoading;
  final bool isBlockedUsersLoading;
  final String? successMessage;

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
    this.hiddenFriends = const [],
    this.blockedUsers = const [],
    this.isHiddenFriendsLoading = false,
    this.isBlockedUsersLoading = false,
    this.successMessage,
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
    List<Friend>? hiddenFriends,
    List<User>? blockedUsers,
    bool? isHiddenFriendsLoading,
    bool? isBlockedUsersLoading,
    String? successMessage,
    bool clearSuccessMessage = false,
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
      hiddenFriends: hiddenFriends ?? this.hiddenFriends,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isHiddenFriendsLoading: isHiddenFriendsLoading ?? this.isHiddenFriendsLoading,
      isBlockedUsersLoading: isBlockedUsersLoading ?? this.isBlockedUsersLoading,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
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
        hiddenFriends,
        blockedUsers,
        isHiddenFriendsLoading,
        isBlockedUsersLoading,
        successMessage,
      ];
}
