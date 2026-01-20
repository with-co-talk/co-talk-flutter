import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/friend.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  @override
  void initState() {
    super.initState();
    context.read<FriendBloc>().add(const FriendListLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<FriendBloc, FriendState>(
        builder: (context, state) {
          if (state.status == FriendStatus.loading && state.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == FriendStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '친구 목록을 불러오는데 실패했습니다',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<FriendBloc>()
                          .add(const FriendListLoadRequested());
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (state.friends.isEmpty) {
            return const Center(
              child: Text('친구가 없습니다\n친구를 추가해보세요'),
            );
          }

          return ListView.separated(
            itemCount: state.friends.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final friend = state.friends[index];
              return _FriendTile(friend: friend);
            },
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<FriendBloc>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: '닉네임으로 검색',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (query) {
                          context
                              .read<FriendBloc>()
                              .add(UserSearchRequested(query));
                        },
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<FriendBloc, FriendState>(
                        builder: (context, state) {
                          if (state.isSearching) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state.searchResults.isEmpty) {
                            return const Center(
                              child: Text('검색 결과가 없습니다'),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: state.searchResults.length,
                            itemBuilder: (context, index) {
                              final user = state.searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    user.nickname.isNotEmpty
                                        ? user.nickname[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(user.nickname),
                                subtitle: Text(user.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_add),
                                  onPressed: () {
                                    context
                                        .read<FriendBloc>()
                                        .add(FriendRequestSent(user.id));
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('친구 요청을 보냈습니다'),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;

  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            backgroundImage: friend.user.avatarUrl != null
                ? NetworkImage(friend.user.avatarUrl!)
                : null,
            child: friend.user.avatarUrl == null
                ? Text(
                    friend.user.nickname.isNotEmpty
                        ? friend.user.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getOnlineStatusColor(friend.user.onlineStatus),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        friend.user.nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _getOnlineStatusText(friend.user.onlineStatus),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'chat',
            child: Row(
              children: [
                Icon(Icons.chat),
                SizedBox(width: 8),
                Text('대화하기'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, color: Colors.red),
                SizedBox(width: 8),
                Text('친구 삭제', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'chat') {
            // TODO: Navigate to chat
          } else if (value == 'remove') {
            _showRemoveFriendDialog(context);
          }
        },
      ),
    );
  }

  Color _getOnlineStatusColor(onlineStatus) {
    switch (onlineStatus.toString()) {
      case 'OnlineStatus.online':
        return AppColors.online;
      case 'OnlineStatus.away':
        return AppColors.away;
      default:
        return AppColors.offline;
    }
  }

  String _getOnlineStatusText(onlineStatus) {
    switch (onlineStatus.toString()) {
      case 'OnlineStatus.online':
        return '온라인';
      case 'OnlineStatus.away':
        return '자리 비움';
      default:
        return '오프라인';
    }
  }

  void _showRemoveFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.user.nickname}님을 친구에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(FriendRemoved(friend.user.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
