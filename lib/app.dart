import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'l10n/app_localizations.dart';
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

            // WebSocket 재연결 시 토큰 갱신을 AuthInterceptor의 single-flight
            // refresh로 위임 (refresh authority 단일화 → rotation race 제거).
            webSocketService.setTokenRefreshDelegate(
              authInterceptor.refreshTokenForReconnect,
            );

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
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
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
                          BlocConsumer<AppLockCubit, AppLockState>(
                            listenWhen: (prev, curr) => prev.status != curr.status,
                            listener: (context, lockState) {
                              // 잠금 화면이 뜰 때, 이전 화면에서 올라와 있던 키보드를 내려
                              // 인증 버튼이 가려지지 않도록 한다.
                              if (lockState.status != AppLockStatus.unlocked) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                            },
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

/// 앱 전역(global) 라이프사이클 옵저버.
///
/// 책임 경계(M2): 이 옵저버는 **앱 전역 보안 잠금(AppLockCubit)** 만 담당한다.
/// 채팅 presence(active/inactive)와 WebSocket 연결 관리는 의도적으로 여기서
/// 다루지 않는다 — presence는 본질적으로 "특정 방을 보고 있는가"라는 per-room
/// 상태이고(presence_manager: sendPresenceActive/Inactive(roomId)), 그 책임은
/// 방이 열려 있는 동안에만 존재하는 chat_room_page의 WidgetsBindingObserver가
/// 가진다(1.5s 디바운스, iOS inactive-vs-paused 구분 포함).
///
/// 따라서 채팅 "목록"(방 밖)에서 백그라운드로 가도 누락되는 presence 의무는
/// 없다: 목록에서는 활성(active)으로 표시된 방이 애초에 없으므로 해제할 상태가
/// 없고, 모든 방의 푸시는 정상 수신된다. 두 옵저버의 역할은 겹치지 않는다.
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
    final cubit = context.read<AppLockCubit>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // 실제 백그라운드 전환 시각 기록(inactive는 생체 인증 프롬프트 등
        // 일시적 인터럽트에서도 발생하므로 제외한다).
        cubit.onBackgrounded();
      case AppLifecycleState.resumed:
        cubit.checkLockOnResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
