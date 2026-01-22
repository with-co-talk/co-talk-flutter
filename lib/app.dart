import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/websocket_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

class CoTalkApp extends StatelessWidget {
  const CoTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
      child: Builder(
        builder: (context) {
          final appRouter = getIt<AppRouter>();

          return MaterialApp.router(
            title: 'Co-Talk',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
