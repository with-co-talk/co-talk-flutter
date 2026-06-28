import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/friend.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeletons/list_skeleton.dart';

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
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Text(ErrorMessageMapper.toUserFriendlyMessage(state.errorMessage!)),
                  backgroundColor: AppColors.error,
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
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.friendsTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: AppLocalizations.of(context)!.friendsAdd,
              onPressed: () => _showAddFriendDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: AppLocalizations.of(context)!.friendsManage,
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
              // 친구 목록 아바타는 CircleAvatar(radius: 35) → 지름 70px.
              return const ListSkeleton(avatarSize: 70);
            }

            if (state.status == FriendStatus.failure) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: AppLocalizations.of(context)!.friendsListLoadError,
                subtitle: '네트워크 상태를 확인하고 다시 시도해 주세요.',
                action: SizedBox(
                  width: 160,
                  child: GradientButton(
                    height: 48,
                    label: AppLocalizations.of(context)!.commonRetry,
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      context
                          .read<FriendBloc>()
                          .add(const FriendListLoadRequested());
                    },
                  ),
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

                  // Friend List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Text(
                        AppLocalizations.of(context)!
                            .friendsCount(state.friends.length),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),

                  // Friend List
                  if (state.friends.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        icon: Icons.people_outline_rounded,
                        title: AppLocalizations.of(context)!.friendsEmptyTitle,
                        subtitle: AppLocalizations.of(context)!.friendsEmptyDesc,
                        action: SizedBox(
                          width: 180,
                          child: GradientButton(
                            height: 48,
                            label: AppLocalizations.of(context)!.friendsAdd,
                            icon: Icons.person_add_alt_1_rounded,
                            onPressed: () => _showAddFriendDialog(context),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _FriendTile(friend: state.friends[index]),
                          childCount: state.friends.length,
                        ),
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
    final hasStatus =
        user.statusMessage != null && user.statusMessage!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push(AppRoutes.profileViewPath(user.id)),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
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
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
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
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasStatus ? user.statusMessage! : '내 프로필 보기',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
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
            label: AppLocalizations.of(context)!.friendsHide,
          ),
          SlidableAction(
            onPressed: (_) => _showBlockDialog(context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.block,
            label: AppLocalizations.of(context)!.friendsBlock,
          ),
          SlidableAction(
            onPressed: (_) => _showDeleteDialog(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: AppLocalizations.of(context)!.commonDelete,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProfile(context, friend.user.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _FriendAvatar(
                nickname: friend.user.nickname,
                avatarUrl: friend.user.avatarUrl,
                isOnline: friend.user.onlineStatus.toString() ==
                    'OnlineStatus.online',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.user.nickname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (friend.user.statusMessage != null &&
                        friend.user.statusMessage!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        friend.user.statusMessage!,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 13,
                          height: 1.3,
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
        title: Text(AppLocalizations.of(context)!.friendsHideTitle),
        content: Text(
          AppLocalizations.of(context)!.friendsHideConfirm(friend.user.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(HideFriendRequested(friend.user.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.friendsHideSuccess),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text(AppLocalizations.of(context)!.friendsHide),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.friendsBlockTitle),
        content: Text(
          AppLocalizations.of(context)!.friendsBlockConfirm(friend.user.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(BlockUserRequested(friend.user.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.friendsBlockSuccess),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(AppLocalizations.of(context)!.friendsBlock),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.friendsDeleteTitle),
        content: Text(
          AppLocalizations.of(context)!.friendsDeleteConfirm(friend.user.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendBloc>().add(FriendRemoved(friend.user.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }
}

/// 공용 원형 아바타. primaryLight 배경 + 흰 이니셜, 온라인 점은 surface 링과 함께.
class _FriendAvatar extends StatelessWidget {
  final String nickname;
  final String? avatarUrl;
  final bool isOnline;

  const _FriendAvatar({
    required this.nickname,
    required this.avatarUrl,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: avatarUrl != null
              ? CachedNetworkImageProvider(avatarUrl!, maxWidth: 200)
              : null,
          child: avatarUrl == null
              ? Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        if (isOnline)
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: context.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TextField(
                  controller: _searchController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  enableInteractiveSelection: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.friendsSearchHint,
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
                  ],
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
                              AppLocalizations.of(context)!.friendsSearchError,
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
                              child: Text(AppLocalizations.of(context)!.commonRetry),
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
                              AppLocalizations.of(context)!.friendsSearchPrompt,
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
                              AppLocalizations.of(context)!.friendsSearchNoResults,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                            if (state.searchQuery != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .friendsSearchNoResultsFor(state.searchQuery!),
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
                              _FriendAvatar(
                                nickname: user.nickname,
                                avatarUrl: user.avatarUrl,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nickname,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .friendsRequestSent,
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 18),
                                label: Text(
                                    AppLocalizations.of(context)!.friendsAddShort),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
