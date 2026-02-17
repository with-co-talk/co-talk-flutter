import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/websocket_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/settings/chat_settings_cubit.dart';
import 'presentation/blocs/settings/chat_settings_state.dart';
import 'presentation/blocs/app/app_lock_cubit.dart';
import 'presentation/blocs/app/app_lock_state.dart';
import 'presentation/pages/app/app_lock_page.dart';

class CoTalkApp extends StatelessWidget {
  const CoTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final authBloc = getIt<AuthBloc>();
            final authInterceptor = getIt<AuthInterceptor>();
            final webSocketService = getIt<WebSocketService>();

            // AuthInterceptor에 AuthBloc과 WebSocketService 설정
            // (토큰 갱신 실패 시 로그아웃 처리용)
            authInterceptor.setAuthBloc(authBloc);
            authInterceptor.setWebSocketService(webSocketService);

            return authBloc;
          },
        ),
        BlocProvider(
          create: (_) => getIt<ThemeCubit>()..loadTheme(),
        ),
        BlocProvider(
          create: (_) => getIt<ChatSettingsCubit>()..loadSettings(),
        ),
        BlocProvider(
          create: (_) => getIt<AppLockCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<ChatSettingsCubit, ChatSettingsState>(
            buildWhen: (previous, current) =>
                previous.settings.fontSize != current.settings.fontSize,
            builder: (context, chatSettingsState) {
              final appRouter = getIt<AppRouter>();

              return MaterialApp.router(
                title: 'Co-Talk',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: appRouter.router,
                builder: (context, child) {
                  // Apply global text scaling from chat settings
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(chatSettingsState.settings.fontSize),
                    ),
                    child: _AppLifecycleHandler(
                      child: Stack(
                        children: [
                          child ?? const SizedBox.shrink(),
                          BlocBuilder<AppLockCubit, AppLockState>(
                            builder: (context, lockState) {
                              if (lockState.status == AppLockStatus.unlocked) {
                                return const SizedBox.shrink();
                              }
                              return const AppLockPage();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  const _AppLifecycleHandler({required this.child});

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱 최초 실행 시 생체 인증 체크
    context.read<AppLockCubit>().checkLockOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppLockCubit>().checkLockOnResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
