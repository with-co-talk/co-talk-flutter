import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../domain/entities/chat_room.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_list_state.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final ChatListBloc _chatListBloc;
  int? _subscribedUserId;

  @override
  void initState() {
    super.initState();
    _chatListBloc = context.read<ChatListBloc>();
    _chatListBloc.add(const ChatListLoadRequested());

    // WebSocket 구독 시작 (사용자 채널)
    _syncSubscriptionWithAuthState(context.read<AuthBloc>().state);
  }

  void _syncSubscriptionWithAuthState(AuthState authState) {
    final nextUserId =
        (authState.status == AuthStatus.authenticated) ? authState.user?.id : null;

    if (nextUserId == null) {
      // 로그아웃/미인증 상태로 전환되면 구독 해제
      if (_subscribedUserId != null) {
        _chatListBloc.add(const ChatListSubscriptionStopped());
        _subscribedUserId = null;
      }
      return;
    }

    // 동일 userId면 유지, 변경되면 재구독
    if (_subscribedUserId == nextUserId) return;

    if (_subscribedUserId != null) {
      _chatListBloc.add(const ChatListSubscriptionStopped());
    }
    _chatListBloc.add(ChatListSubscriptionStarted(nextUserId));
    _subscribedUserId = nextUserId;
  }

  @override
  void dispose() {
    // WebSocket 구독 해제
    _chatListBloc.add(const ChatListSubscriptionStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.user?.id != current.user?.id,
          listener: (context, authState) {
            _syncSubscriptionWithAuthState(authState);
          },
        ),
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
        appBar: AppBar(
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
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
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

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ChatListBloc>()
                  .add(const ChatListRefreshRequested());
            },
            child: ListView.separated(
              itemCount: state.chatRooms.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final chatRoom = state.chatRooms[index];
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
                  child: chatRoom.type == ChatRoomType.group
                      ? const Icon(Icons.group, color: Colors.white, size: 28)
                      : Text(
                          chatRoom.displayName.isNotEmpty
                              ? chatRoom.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                // 온라인 상태 표시 (추후 구현 가능)
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
                          chatRoom.lastMessage ?? '',
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
