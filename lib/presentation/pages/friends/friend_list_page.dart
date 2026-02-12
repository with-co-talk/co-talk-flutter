import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/friend.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  Timer? _debounceTimer;
  late FriendBloc _friendBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _friendBloc = context.read<FriendBloc>();
  }

  @override
  void initState() {
    super.initState();
    // 친구 목록 로드
    context.read<FriendBloc>().add(const FriendListLoadRequested());
    // WebSocket 온라인 상태 구독 시작
    context.read<FriendBloc>().add(const FriendListSubscriptionStarted());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // WebSocket 구독 해제
    _friendBloc.add(const FriendListSubscriptionStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FriendBloc, FriendState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage && current.errorMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ErrorMessageMapper.toUserFriendlyMessage(state.errorMessage!)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<FriendBloc, FriendState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage &&
              current.successMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '친구',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: '친구 추가',
              onPressed: () => _showAddFriendDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: '친구 관리',
              onPressed: () async {
                // Navigate to friend settings and refresh list on return
                await context.push(AppRoutes.friendSettings);
                // After returning, refresh friend list to show any changes
                if (context.mounted) {
                  context.read<FriendBloc>().add(const FriendListLoadRequested());
                }
              },
            ),
          ],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
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
                      style: TextStyle(color: context.textSecondaryColor),
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

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendBloc>().add(const FriendListLoadRequested());
              },
              child: CustomScrollView(
                slivers: [
                  // My Profile Section
                  SliverToBoxAdapter(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final user = authState.user;
                        if (user == null) return const SizedBox.shrink();

                        return _MyProfileCard(user: user);
                      },
                    ),
                  ),

                  // Divider
                  SliverToBoxAdapter(
                    child: Container(
                      height: 8,
                      color: context.isDarkMode
                          ? AppColors.backgroundDark
                          : const Color(0xFFF5F5F5),
                    ),
                  ),

                  // Friend List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '친구 ${state.friends.length}명',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),

                  // Friend List
                  if (state.friends.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: context.textSecondaryColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '친구가 없습니다',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: context.textSecondaryColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '친구를 추가하고 대화를 시작해보세요',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondaryColor.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showAddFriendDialog(context),
                              icon: const Icon(Icons.person_add),
                              label: const Text('친구 추가'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _FriendTile(friend: state.friends[index]),
                        childCount: state.friends.length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<FriendBloc>(),
          child: _AddFriendBottomSheet(
            debounceTimer: _debounceTimer,
            onDebounceTimerChanged: (timer) => _debounceTimer = timer,
          ),
        );
      },
    ).whenComplete(() {
      _debounceTimer?.cancel();
    });
  }
}

class _MyProfileCard extends StatelessWidget {
  final dynamic user;

  const _MyProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.profileViewPath(user.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.nickname.isNotEmpty
                          ? user.nickname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  if (user.statusMessage != null && user.statusMessage!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.statusMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;

  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(friend.user.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.6,
        children: [
          SlidableAction(
            onPressed: (_) => _showHideDialog(context),
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            icon: Icons.visibility_off,
            label: '숨김',
          ),
          SlidableAction(
            onPressed: (_) => _showBlockDialog(context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.block,
            label: '차단',
          ),
          SlidableAction(
            onPressed: (_) => _showDeleteDialog(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProfile(context, friend.user.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Online status indicator
                  if (friend.user.onlineStatus.toString() == 'OnlineStatus.online')
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.surfaceColor, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.user.nickname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (friend.user.statusMessage != null &&
                        friend.user.statusMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        friend.user.statusMessage!,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, int userId) {
    context.push(AppRoutes.profileViewPath(userId));
  }

  void _showHideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구 숨김'),
        content: Text('${friend.user.nickname}님을 숨기시겠습니까?\n친구 관리에서 다시 볼 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(HideFriendRequested(friend.user.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('친구를 숨김 처리했습니다'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('숨김'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구 차단'),
        content: Text('${friend.user.nickname}님을 차단하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(BlockUserRequested(friend.user.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('친구를 차단했습니다'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
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

class _AddFriendBottomSheet extends StatefulWidget {
  final Timer? debounceTimer;
  final void Function(Timer?) onDebounceTimerChanged;

  const _AddFriendBottomSheet({
    required this.debounceTimer,
    required this.onDebounceTimerChanged,
  });

  @override
  State<_AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<_AddFriendBottomSheet> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _debounceTimer = widget.debounceTimer;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  enableInteractiveSelection: true,
                  decoration: InputDecoration(
                    hintText: '닉네임으로 검색',
                    hintStyle: TextStyle(
                      color: context.textSecondaryColor.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.textSecondaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: context.textSecondaryColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<FriendBloc>()
                                  .add(const UserSearchRequested(''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: context.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (query) {
                    _debounceTimer?.cancel();
                    setState(() {});
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        context
                            .read<FriendBloc>()
                            .add(UserSearchRequested(query));
                      }
                    });
                    widget.onDebounceTimerChanged(_debounceTimer);
                  },
                  onSubmitted: (query) {
                    _debounceTimer?.cancel();
                    widget.onDebounceTimerChanged(null);
                    context
                        .read<FriendBloc>()
                        .add(UserSearchRequested(query));
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<FriendBloc, FriendState>(
                  builder: (context, state) {
                    if (state.errorMessage != null && state.hasSearched) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 중 오류가 발생했습니다',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (state.searchQuery != null) {
                                  context
                                      .read<FriendBloc>()
                                      .add(UserSearchRequested(state.searchQuery!));
                                }
                              },
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state.isSearching) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!state.hasSearched) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '닉네임을 입력하여 검색하세요',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state.searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                            if (state.searchQuery != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${state.searchQuery}"에 대한 결과가 없습니다',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.nickname.isNotEmpty
                                            ? user.nickname[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nickname,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: context.textSecondaryColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context
                                      .read<FriendBloc>()
                                      .add(FriendRequestSent(user.id));
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('친구 요청을 보냈습니다'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('추가'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
