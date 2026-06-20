import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
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
          bottomNavigationBar: _AuroraBottomNav(
            selectedIndex: _selectedIndex,
            totalUnread: totalUnread,
            onDestinationSelected: _onDestinationSelected,
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

/// Aurora Violet 하단 네비게이션 셸.
/// 활성 탭은 브랜드 보라 알약(pill) 배경으로 강조, 비활성은 textSecondary.
class _AuroraBottomNav extends StatelessWidget {
  final int selectedIndex;
  final int totalUnread;
  final ValueChanged<int> onDestinationSelected;

  const _AuroraBottomNav({
    required this.selectedIndex,
    required this.totalUnread,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.dividerColor, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: context.isDarkMode ? 0.0 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: '친구',
                  isActive: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.chat_outlined,
                  activeIcon: Icons.chat,
                  label: '채팅',
                  isActive: selectedIndex == 1,
                  badgeCount: totalUnread,
                  onTap: () => onDestinationSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 단일 네비 항목. 활성 시 보라 알약 배경 + 흰 콘텐츠, 비활성 시 secondary 톤.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = context.textSecondaryColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: AppColors.brandGradient,
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadged(
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? Colors.white : inactiveColor,
                ),
                isActive,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadged(Widget child, bool isActive) {
    if (badgeCount <= 0) return child;
    return Badge(
      backgroundColor: isActive ? Colors.white : AppColors.error,
      textColor: isActive ? AppColors.primary : Colors.white,
      label: Text(
        badgeCount > 99 ? '99+' : badgeCount.toString(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      child: child,
    );
  }
}
