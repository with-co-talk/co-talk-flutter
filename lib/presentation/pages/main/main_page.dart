import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_list_bloc.dart';
import '../../blocs/chat/chat_list_event.dart';
import '../../blocs/chat/chat_list_state.dart';

class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int? _subscribedUserId;
  bool _isInitialized = false;

  /// 친구 탭 먼저, 채팅 탭 나중 (인덱스 0: 친구, 1: 채팅)
  static const _destinations = [
    AppRoutes.friends,
    AppRoutes.chatList,
  ];

  @override
  void initState() {
    super.initState();
    // ChatListBloc 초기화는 didChangeDependencies에서 수행
    // (context.read는 initState에서 안전하지 않음)
  }

  void _initializeChatListBloc() {
    if (_isInitialized) return;
    _isInitialized = true;

    final chatListBloc = context.read<ChatListBloc>();
    final authState = context.read<AuthBloc>().state;

    // 채팅 목록 로드
    chatListBloc.add(const ChatListLoadRequested());

    // WebSocket 구독 시작
    _syncSubscriptionWithAuthState(authState);
  }

  void _syncSubscriptionWithAuthState(AuthState authState) {
    final chatListBloc = context.read<ChatListBloc>();
    final nextUserId =
        (authState.status == AuthStatus.authenticated) ? authState.user?.id : null;

    if (nextUserId == null) {
      // 로그아웃/미인증 상태로 전환되면 구독 해제
      if (_subscribedUserId != null) {
        chatListBloc.add(const ChatListSubscriptionStopped());
        _subscribedUserId = null;
      }
      return;
    }

    // 동일 userId면 유지, 변경되면 재구독
    if (_subscribedUserId == nextUserId) return;

    if (_subscribedUserId != null) {
      chatListBloc.add(const ChatListSubscriptionStopped());
    }
    chatListBloc.add(ChatListSubscriptionStarted(nextUserId));
    _subscribedUserId = nextUserId;
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      context.go(_destinations[index]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 최초 1회 ChatListBloc 초기화
    _initializeChatListBloc();

    final location = GoRouterState.of(context).matchedLocation;
    final index = _destinations.indexOf(location);
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.user?.id != current.user?.id,
      listener: (context, authState) {
        // 로그인/로그아웃 또는 사용자 변경 시 구독 업데이트
        _syncSubscriptionWithAuthState(authState);
      },
      child: BlocBuilder<ChatListBloc, ChatListState>(
        buildWhen: (previous, current) =>
            previous.totalUnreadCount != current.totalUnreadCount,
        builder: (context, chatListState) {
          final totalUnread = chatListState.totalUnreadCount;

          if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.people_outlined),
                      selectedIcon: Icon(Icons.people),
                      label: Text('친구'),
                    ),
                    NavigationRailDestination(
                      icon: _buildBadgeIcon(
                        icon: const Icon(Icons.chat_outlined),
                        count: totalUnread,
                      ),
                      selectedIcon: _buildBadgeIcon(
                        icon: const Icon(Icons.chat),
                        count: totalUnread,
                      ),
                      label: const Text('채팅'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        return Scaffold(
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: '친구',
              ),
              NavigationDestination(
                icon: _buildBadgeIcon(
                  icon: const Icon(Icons.chat_outlined),
                  count: totalUnread,
                ),
                selectedIcon: _buildBadgeIcon(
                  icon: const Icon(Icons.chat),
                  count: totalUnread,
                ),
                label: '채팅',
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  /// 배지가 있는 아이콘 위젯을 생성합니다.
  Widget _buildBadgeIcon({required Widget icon, required int count}) {
    if (count <= 0) {
      return icon;
    }

    return Badge(
      label: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: icon,
    );
  }
}
