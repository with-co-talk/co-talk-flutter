import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/chat_room.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_list_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/skeletons/list_skeleton.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // 검색 관련 상태
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // ChatListBloc은 MainPage에서 초기화되므로 여기서는 새로고침만 수행
    // (이미 데이터가 있으면 캐시된 데이터 사용, 없으면 로드)
    final chatListBloc = context.read<ChatListBloc>();
    if (chatListBloc.state.chatRooms.isEmpty &&
        chatListBloc.state.status != ChatListStatus.loading) {
      chatListBloc.add(const ChatListLoadRequested());
    }

    // 검색어 변경 리스너
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    // ChatListBloc은 singleton이므로 구독 해제하지 않음
    // (MainPage에서 관리)
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// 나와의 채팅 표시명: 내 닉네임 또는 '나'
  String _selfChatDisplayName(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final nickname = (user?.nickname ?? '').trim();
    return nickname.isNotEmpty ? nickname : AppLocalizations.of(context)!.chatSelfName;
  }

  /// 채팅방 목록 표시명 (나와의 채팅은 내 이름/나)
  String _roomDisplayName(BuildContext context, ChatRoom room) {
    if (room.type == ChatRoomType.self) return _selfChatDisplayName(context);
    return room.displayName;
  }

  /// 검색어로 채팅방 필터링
  List<ChatRoom> _filterChatRooms(BuildContext context, List<ChatRoom> chatRooms) {
    if (_searchQuery.isEmpty) return chatRooms;

    return chatRooms.where((room) {
      final displayName = _roomDisplayName(context, room).toLowerCase();
      return displayName.contains(_searchQuery);
    }).toList();
  }

  /// 일반 AppBar
  AppBar _buildNormalAppBar() {
    return AppBar(
      backgroundColor: context.surfaceColor,
      title: Text(
        AppLocalizations.of(context)!.chatTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// 검색 모드 AppBar
  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: context.surfaceColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: _toggleSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.chatSearchHint,
          hintStyle: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 16,
          color: context.textPrimaryColor,
        ),
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
      ],
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // AuthBloc 구독 로직은 MainPage로 이동됨
        BlocListener<ChatListBloc, ChatListState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ErrorMessageMapper.toUserFriendlyMessage(
                    state.errorMessage!,
                  )),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
        body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          if (state.status == ChatListStatus.loading &&
              state.chatRooms.isEmpty) {
            return const ListSkeleton();
          }

          if (state.status == ChatListStatus.failure) {
            return EmptyStateView(
              icon: Icons.cloud_off_rounded,
              title: AppLocalizations.of(context)!.chatListLoadFailed,
              subtitle: '잠시 후 다시 시도해주세요',
              action: ElevatedButton(
                onPressed: () {
                  context
                      .read<ChatListBloc>()
                      .add(const ChatListLoadRequested());
                },
                child: Text(AppLocalizations.of(context)!.commonRetry),
              ),
            );
          }

          if (state.chatRooms.isEmpty) {
            return EmptyStateView(
              icon: Icons.forum_outlined,
              title: AppLocalizations.of(context)!.chatListEmpty,
              subtitle: '친구와 첫 대화를 시작해보세요',
            );
          }

          // 검색 필터 적용
          final filteredChatRooms = _filterChatRooms(context, state.chatRooms);

          // 검색 결과 없음
          if (_isSearching && filteredChatRooms.isEmpty) {
            return EmptyStateView(
              icon: Icons.search_off_rounded,
              title: '검색 결과가 없어요',
              subtitle: AppLocalizations.of(context)!.chatSearchNoResults(_searchQuery),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ChatListBloc>()
                  .add(const ChatListRefreshRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: filteredChatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = filteredChatRooms[index];
                final displayName = _roomDisplayName(context, chatRoom);
                return _ChatRoomTile(chatRoom: chatRoom, displayName: displayName);
              },
            ),
          );
        },
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String displayName;

  const _ChatRoomTile({required this.chatRoom, required this.displayName});

  /// 아바타는 작은 원형으로만 표시되므로 디스크 캐시 + 다운샘플(maxWidth)을
  /// 적용해 raw NetworkImage 의 풀해상도 디코딩/재다운로드를 막는다.
  static const int _avatarCacheWidth = 200;

  ImageProvider? _getAvatarImage(ChatRoom chatRoom) {
    // 1:1 채팅 - 상대방 아바타
    if (chatRoom.type == ChatRoomType.direct && chatRoom.otherUserAvatarUrl != null) {
      return CachedNetworkImageProvider(
        chatRoom.otherUserAvatarUrl!,
        maxWidth: _avatarCacheWidth,
      );
    }
    // 그룹 채팅 - 그룹 이미지
    if (chatRoom.type == ChatRoomType.group && chatRoom.imageUrl != null) {
      return CachedNetworkImageProvider(
        chatRoom.imageUrl!,
        maxWidth: _avatarCacheWidth,
      );
    }
    return null;
  }

  Widget? _getAvatarChild(ChatRoom chatRoom, String displayName) {
    // 1:1 채팅 - 아바타 없으면 이니셜
    if (chatRoom.type == ChatRoomType.direct && chatRoom.otherUserAvatarUrl == null) {
      return Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // 그룹 채팅 - 이미지 없으면 그룹 아이콘
    if (chatRoom.type == ChatRoomType.group && chatRoom.imageUrl == null) {
      return const Icon(Icons.group, color: Colors.white, size: 28);
    }
    // 아바타/이미지가 있으면 child 불필요
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = chatRoom.unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/chat/room/${chatRoom.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                // 아바타
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _getAvatarImage(chatRoom),
                      child: _getAvatarChild(chatRoom, displayName),
                    ),
                    // 온라인 상태 표시 (1:1 채팅방만)
                    if (chatRoom.type == ChatRoomType.direct && chatRoom.isOtherUserOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.surfaceColor,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // 메시지 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                          if (chatRoom.lastMessageAt != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                AppDateUtils.formatChatListTime(chatRoom.lastMessageAt!),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: hasUnread
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: hasUnread
                                    ? context.textPrimaryColor
                                    : context.textSecondaryColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                chatRoom.unreadCount > 99
                                    ? '99+'
                                    : '${chatRoom.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
