import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/chat_room.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_list_state.dart';

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

  /// 검색어로 채팅방 필터링
  List<ChatRoom> _filterChatRooms(List<ChatRoom> chatRooms) {
    if (_searchQuery.isEmpty) return chatRooms;

    return chatRooms.where((room) {
      // 채팅방 이름 또는 상대방 닉네임으로 검색
      final displayName = room.displayName.toLowerCase();
      return displayName.contains(_searchQuery);
    }).toList();
  }

  /// 일반 AppBar
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text(
        '채팅',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// 검색 모드 AppBar
  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _toggleSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '채팅방 검색',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 16,
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
        backgroundColor: AppColors.background,
        appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
        body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          if (state.status == ChatListStatus.loading &&
              state.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ChatListStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '채팅방을 불러오는데 실패했습니다',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ChatListBloc>()
                          .add(const ChatListLoadRequested());
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (state.chatRooms.isEmpty) {
            return const Center(
              child: Text('채팅방이 없습니다\n친구를 추가하고 대화를 시작해보세요'),
            );
          }

          // 검색 필터 적용
          final filteredChatRooms = _filterChatRooms(state.chatRooms);

          // 검색 결과 없음
          if (_isSearching && filteredChatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"$_searchQuery" 검색 결과가 없습니다',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ChatListBloc>()
                  .add(const ChatListRefreshRequested());
            },
            child: ListView.separated(
              itemCount: filteredChatRooms.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final chatRoom = filteredChatRooms[index];
                return _ChatRoomTile(chatRoom: chatRoom);
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

  const _ChatRoomTile({required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/chat/${chatRoom.id}'),
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
                  backgroundImage: chatRoom.type == ChatRoomType.direct &&
                          chatRoom.otherUserAvatarUrl != null
                      ? NetworkImage(chatRoom.otherUserAvatarUrl!)
                      : null,
                  child: chatRoom.type == ChatRoomType.group
                      ? const Icon(Icons.group, color: Colors.white, size: 28)
                      : (chatRoom.otherUserAvatarUrl == null
                          ? Text(
                              chatRoom.displayName.isNotEmpty
                                  ? chatRoom.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null),
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // 메시지 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: chatRoom.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (chatRoom.lastMessageAt != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            AppDateUtils.formatChatListTime(chatRoom.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: chatRoom.unreadCount > 0
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
                            color: chatRoom.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: chatRoom.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chatRoom.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatRoom.unreadCount > 99
                                ? '99+'
                                : '${chatRoom.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
