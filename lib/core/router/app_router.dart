import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../config/app_config.dart';
import '../../di/injection.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/blocs/chat/chat_list_bloc.dart';
import '../../presentation/blocs/chat/chat_room_bloc.dart';
import '../../presentation/blocs/chat/message_search/message_search_bloc.dart';
import '../../presentation/blocs/friend/friend_bloc.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/chat/chat_list_page.dart';
import '../../presentation/pages/chat/chat_room_page.dart';
import '../../presentation/pages/chat/direct_chat_page.dart';
import '../../presentation/pages/friends/friend_list_page.dart';
import '../../presentation/pages/friends/friend_settings_page.dart';
import '../../presentation/pages/friends/received_requests_page.dart';
import '../../presentation/pages/friends/sent_requests_page.dart';
import '../../presentation/pages/friends/hidden_friends_page.dart';
import '../../presentation/pages/friends/blocked_users_page.dart';
import '../../presentation/pages/main/main_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/profile/edit_profile_page.dart';
import '../../presentation/pages/profile/profile_view_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/settings/notification_settings_page.dart';
import '../../presentation/pages/settings/chat_settings_page.dart';
import '../../presentation/pages/settings/change_password_page.dart';
import '../../presentation/pages/settings/account_deletion_page.dart';
import '../../presentation/pages/settings/terms_page.dart';
import '../../presentation/pages/settings/privacy_policy_page.dart';
import '../../presentation/blocs/settings/notification_settings_cubit.dart';
import '../../presentation/blocs/settings/chat_settings_cubit.dart';
import '../../presentation/blocs/settings/account_deletion_bloc.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/error/error_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String chatList = '/chat';
  static const String chatRoom = '/chat/room/:roomId';
  static const String directChat = '/chat/direct/:targetUserId';
  static const String selfChat = '/chat/self/:userId';
  static const String friends = '/friends';
  static const String friendSettings = '/friends/settings';
  static const String receivedRequests = '/friends/settings/received';
  static const String sentRequests = '/friends/settings/sent';
  static const String hiddenFriends = '/friends/settings/hidden';
  static const String blockedUsers = '/friends/settings/blocked';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String profileView = '/profile/view/:userId';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String chatSettings = '/settings/chat';
  static const String changePassword = '/settings/password';
  static const String accountDeletion = '/settings/account/delete';
  static const String terms = '/settings/terms';
  static const String privacyPolicy = '/settings/privacy';

  static String chatRoomPath(int roomId) => '/chat/room/$roomId';
  static String profileViewPath(int userId) => '/profile/view/$userId';
  static String directChatPath(int targetUserId) => '/chat/direct/$targetUserId';
  static String selfChatPath(int userId) => '/chat/self/$userId';
}

@lazySingleton
class AppRouter {
  final AuthBloc _authBloc;

  AppRouter(this._authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: AppConfig.isDebugMode,
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isInitialOrLoading = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signUp;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isMainRoute = state.matchedLocation == AppRoutes.chatList ||
          state.matchedLocation == AppRoutes.friends ||
          state.matchedLocation == AppRoutes.settings;

      // 초기/로딩 상태에서 메인 라우트로 가려고 하면 허용 (BlocListener가 이미 authenticated로 판단)
      if (isInitialOrLoading && isMainRoute) {
        return null;
      }

      if (isSplash) {
        return null; // Let splash handle navigation
      }

      if (!isLoggedIn && !isAuthRoute && !isInitialOrLoading) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.friends;
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => BlocProvider.value(
          value: getIt<ChatListBloc>(),
          child: MainPage(child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.chatList,
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<FriendBloc>(),
              child: const FriendListPage(),
            ),
          ),
        ],
      ),
      // 친구 설정 (ShellRoute 밖 - push로 열리는 전체화면)
      GoRoute(
        path: AppRoutes.friendSettings,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FriendSettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.receivedRequests,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ReceivedRequestsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sentRequests,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SentRequestsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hiddenFriends,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HiddenFriendsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BlockedUsersPage(),
        ),
      ),
      // 설정 (ShellRoute 밖 - push로 열리는 전체화면)
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsPage(),
        ),
      ),
      // 알림 설정
      GoRoute(
        path: AppRoutes.notificationSettings,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<NotificationSettingsCubit>(),
            child: const NotificationSettingsPage(),
          ),
        ),
      ),
      // 채팅 설정
      GoRoute(
        path: AppRoutes.chatSettings,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<ChatSettingsCubit>(),
            child: const ChatSettingsPage(),
          ),
        ),
      ),
      // 비밀번호 변경
      GoRoute(
        path: AppRoutes.changePassword,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
        ),
      ),
      // 회원 탈퇴
      GoRoute(
        path: AppRoutes.accountDeletion,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<AccountDeletionBloc>(),
            child: const AccountDeletionPage(),
          ),
        ),
      ),
      // 이용약관
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TermsPage(),
        ),
      ),
      // 개인정보 처리방침
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PrivacyPolicyPage(),
        ),
      ),
      // 프로필 (ShellRoute 밖 - push로 열리는 전체화면)
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfilePage(),
        ),
      ),
      // 프로필 편집 (ShellRoute 밖 - push로 열리는 전체화면)
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfilePage(),
        ),
      ),
      // 프로필 전체보기 (ShellRoute 밖 - push로 열리는 전체화면)
      GoRoute(
        path: AppRoutes.profileView,
        pageBuilder: (context, state) {
          final userIdStr = state.pathParameters['userId'];
          if (userIdStr == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '사용자 ID가 없습니다'),
            );
          }
          final userId = int.tryParse(userIdStr);
          if (userId == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '유효하지 않은 사용자 ID입니다'),
            );
          }
          final authState = context.read<AuthBloc>().state;
          final isMyProfile = authState.user?.id == userId;
          return MaterialPage(
            key: ValueKey('profile-view-$userId'),
            child: ProfileViewPage(
              userId: userId,
              isMyProfile: isMyProfile,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        pageBuilder: (context, state) {
          final roomIdStr = state.pathParameters['roomId'];
          if (roomIdStr == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '채팅방 ID가 없습니다'),
            );
          }

          final roomId = int.tryParse(roomIdStr);
          if (roomId == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '유효하지 않은 채팅방 ID입니다'),
            );
          }

          return MaterialPage(
            key: ValueKey('chat-room-$roomId'),
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => getIt<ChatRoomBloc>(),
                ),
                // ChatRoomPage에서 ChatListBloc에 접근할 수 있도록 제공 (singleton)
                BlocProvider.value(
                  value: getIt<ChatListBloc>(),
                ),
                // 메시지 검색을 위한 BLoC
                BlocProvider(
                  create: (_) => getIt<MessageSearchBloc>(),
                ),
              ],
              child: ChatRoomPage(roomId: roomId),
            ),
          );
        },
      ),
      // 1:1 채팅 시작 (채팅방 생성/조회 후 이동)
      GoRoute(
        path: AppRoutes.directChat,
        pageBuilder: (context, state) {
          final targetUserIdStr = state.pathParameters['targetUserId'];
          if (targetUserIdStr == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '대상 사용자 ID가 없습니다'),
            );
          }

          final targetUserId = int.tryParse(targetUserIdStr);
          if (targetUserId == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '유효하지 않은 사용자 ID입니다'),
            );
          }

          return MaterialPage(
            key: ValueKey('direct-chat-$targetUserId'),
            child: DirectChatPage(targetUserId: targetUserId),
          );
        },
      ),
      // 나와의 채팅 (자기 자신과 1:1 채팅)
      GoRoute(
        path: AppRoutes.selfChat,
        pageBuilder: (context, state) {
          final userIdStr = state.pathParameters['userId'];
          if (userIdStr == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '사용자 ID가 없습니다'),
            );
          }

          final userId = int.tryParse(userIdStr);
          if (userId == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: '유효하지 않은 사용자 ID입니다'),
            );
          }

          return MaterialPage(
            key: ValueKey('self-chat-$userId'),
            child: DirectChatPage(
              targetUserId: userId,
              isSelfChat: true,
            ),
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;
  AuthStatus? _lastStatus;

  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((state) {
      if (_lastStatus != state.status) {
        _lastStatus = state.status;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
