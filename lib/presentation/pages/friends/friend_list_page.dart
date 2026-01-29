import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/friend.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage>
    with SingleTickerProviderStateMixin {
  Timer? _debounceTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 초기에는 친구 목록만 로드
    context.read<FriendBloc>().add(const FriendListLoadRequested());
    // WebSocket 온라인 상태 구독 시작
    context.read<FriendBloc>().add(const FriendListSubscriptionStarted());

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // 탭 변경 완료 시 해당 데이터 로드
        if (_tabController.index == 1) {
          context.read<FriendBloc>().add(const ReceivedFriendRequestsLoadRequested());
        } else if (_tabController.index == 2) {
          context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    // NOTE: FriendBloc.close()에서 자동으로 구독 해제됨
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendBloc, FriendState>(
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
      child: Scaffold(
        backgroundColor: AppColors.background,
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
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: '친구'),
              Tab(text: '받은 요청'),
              Tab(text: '보낸 요청'),
            ],
          ),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFriendList(),
            _buildReceivedRequests(),
            _buildSentRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendList() {
    return BlocBuilder<FriendBloc, FriendState>(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '친구가 없습니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '친구를 추가하고 대화를 시작해보세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
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
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FriendBloc>().add(const FriendListLoadRequested());
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.friends.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final friend = state.friends[index];
              return _FriendTile(friend: friend);
            },
          ),
        );
      },
    );
  }

  Widget _buildReceivedRequests() {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        // 에러가 있고 받은 요청이 비어있으면 에러 표시
        if (state.errorMessage != null && state.receivedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  '받은 친구 요청을 불러오는데 실패했습니다',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<FriendBloc>().add(const ReceivedFriendRequestsLoadRequested());
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (state.receivedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '받은 친구 요청이 없습니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<FriendBloc>()
                .add(const ReceivedFriendRequestsLoadRequested());
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.receivedRequests.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final request = state.receivedRequests[index];
              return _ReceivedRequestTile(request: request);
            },
          ),
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        // 에러가 있고 보낸 요청이 비어있으면 에러 표시
        if (state.errorMessage != null && state.sentRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  '보낸 친구 요청을 불러오는데 실패했습니다',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (state.sentRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '보낸 친구 요청이 없습니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<FriendBloc>()
                .add(const SentFriendRequestsLoadRequested());
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.sentRequests.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final request = state.sentRequests[index];
              return _SentRequestTile(request: request);
            },
          ),
        );
      },
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
                  color: AppColors.surface,
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
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
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
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
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
                    // Debounce: 500ms 후에 검색 실행
                    _debounceTimer?.cancel();
                    setState(() {}); // suffixIcon 업데이트를 위해
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
                    // 에러 메시지 표시
                    if (state.errorMessage != null && state.hasSearched) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 중 오류가 발생했습니다',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
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

                    // 검색 중
                    if (state.isSearching) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // 검색 전 상태
                    if (!state.hasSearched) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '닉네임을 입력하여 검색하세요',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 검색 결과 없음
                    if (state.searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (state.searchQuery != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${state.searchQuery}"에 대한 결과가 없습니다',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // 검색 결과 표시
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
                                child: Text(
                                  user.nickname.isNotEmpty
                                      ? user.nickname[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nickname,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
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

class _FriendTile extends StatelessWidget {
  final Friend friend;

  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToChat(context, friend.user.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아바타
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
                // 온라인 상태 표시
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getOnlineStatusColor(friend.user.onlineStatus),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 친구 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.user.nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getOnlineStatusColor(friend.user.onlineStatus),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getOnlineStatusText(friend.user.onlineStatus),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 메뉴 버튼
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'chat',
                  child: const Row(
                    children: [
                      Icon(Icons.chat, size: 20),
                      SizedBox(width: 12),
                      Text('대화하기'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: const Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('친구 삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'chat') {
                  await _navigateToChat(context, friend.user.id);
                } else if (value == 'remove') {
                  _showRemoveFriendDialog(context);
                }
              },
            ),
          ],
        ),
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

  Future<void> _navigateToChat(BuildContext context, int friendUserId) async {
    BuildContext? dialogContext;
    
    try {
      // 로딩 표시
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialog) {
          dialogContext = dialog;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // 채팅방 생성 또는 기존 채팅방 찾기
      final chatRepository = getIt<ChatRepository>();
      final chatRoom = await chatRepository.createDirectChatRoom(friendUserId);

      // 다이얼로그 닫기
      if (context.mounted && dialogContext != null) {
        Navigator.of(dialogContext!, rootNavigator: false).pop();
      }

      // 채팅방으로 이동 (다음 프레임에 실행하여 네비게이션 스택 문제 방지)
      if (context.mounted) {
        await Future.microtask(() {});
        if (context.mounted) {
          context.go('/chat/${chatRoom.id}');
        }
      }
    } catch (e) {
      // 에러 발생 시 다이얼로그 닫기
      if (context.mounted && dialogContext != null) {
        Navigator.of(dialogContext!, rootNavigator: false).pop();
      }
      
      // 에러 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorMessageMapper.toUserFriendlyMessage(e),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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

class _ReceivedRequestTile extends StatelessWidget {
  final FriendRequest request;

  const _ReceivedRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: request.requester.avatarUrl != null
                ? NetworkImage(request.requester.avatarUrl!)
                : null,
            child: request.requester.avatarUrl == null
                ? Text(
                    request.requester.nickname.isNotEmpty
                        ? request.requester.nickname[0].toUpperCase()
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
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requester.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.requester.email,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 액션 버튼
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  context
                      .read<FriendBloc>()
                      .add(FriendRequestRejected(request.id));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('거절'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<FriendBloc>()
                      .add(FriendRequestAccepted(request.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: const Text('수락'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  final FriendRequest request;

  const _SentRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: request.receiver.avatarUrl != null
                ? NetworkImage(request.receiver.avatarUrl!)
                : null,
            child: request.receiver.avatarUrl == null
                ? Text(
                    request.receiver.nickname.isNotEmpty
                        ? request.receiver.nickname[0].toUpperCase()
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
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.receiver.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.receiver.email,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '대기 중',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
