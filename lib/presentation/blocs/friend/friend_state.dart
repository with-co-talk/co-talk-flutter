import 'package:equatable/equatable.dart';
import '../../../domain/entities/friend.dart';
import '../../../domain/entities/user.dart';

enum FriendStatus { initial, loading, success, failure }

/// 친구 관련 성공 알림 종류. 표시 문자열은 위젯 레이어에서 [AppLocalizations]로 해석한다.
enum FriendSuccess { deleted }

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
  final FriendSuccess? successType;

  /// 처리 중인 친구요청 ID 집합. 수락/거절이 in-flight 인 동안 해당 ID 가 들어
  /// 있어, 같은 요청에 대한 더블탭 중복 호출(→ 409/400 거짓 에러)을 막고
  /// UI 가 버튼을 비활성/스피너 처리할 수 있게 한다.
  final Set<int> processingRequestIds;

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
    this.successType,
    this.processingRequestIds = const {},
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
    FriendSuccess? successType,
    bool clearSuccessType = false,
    Set<int>? processingRequestIds,
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
      successType: clearSuccessType ? null : (successType ?? this.successType),
      processingRequestIds: processingRequestIds ?? this.processingRequestIds,
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
        successType,
        processingRequestIds,
      ];
}
