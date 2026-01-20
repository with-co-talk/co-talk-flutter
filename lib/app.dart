import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

class CoTalkApp extends StatelessWidget {
  const CoTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
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
