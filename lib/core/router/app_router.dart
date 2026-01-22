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
import '../../presentation/blocs/friend/friend_bloc.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/chat/chat_list_page.dart';
import '../../presentation/pages/chat/chat_room_page.dart';
import '../../presentation/pages/friends/friend_list_page.dart';
import '../../presentation/pages/main/main_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/error/error_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String main = '/main';
  static const String chatList = '/chat';
  static const String chatRoom = '/chat/:roomId';
  static const String friends = '/friends';
  static const String profile = '/profile';
  static const String settings = '/settings';
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
      final isMainRoute = state.matchedLocation == AppRoutes.main ||
          state.matchedLocation == AppRoutes.chatList ||
          state.matchedLocation == AppRoutes.friends ||
          state.matchedLocation == AppRoutes.profile ||
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
        return AppRoutes.main;
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
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.main,
            redirect: (context, state) => AppRoutes.chatList,
          ),
          GoRoute(
            path: AppRoutes.chatList,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ChatListBloc>(),
              child: const ChatListPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<FriendBloc>(),
              child: const FriendListPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        builder: (context, state) {
          final roomIdStr = state.pathParameters['roomId'];
          if (roomIdStr == null) {
            return const ErrorPage(message: '채팅방 ID가 없습니다');
          }

          final roomId = int.tryParse(roomIdStr);
          if (roomId == null) {
            return const ErrorPage(message: '유효하지 않은 채팅방 ID입니다');
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<ChatRoomBloc>(),
              ),
              // ChatRoomPage에서 ChatListBloc에 접근할 수 있도록 제공
              BlocProvider(
                create: (_) => getIt<ChatListBloc>(),
              ),
            ],
            child: ChatRoomPage(roomId: roomId),
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
