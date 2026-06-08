import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';

/// 라우터 공통 화면 전환.
///
/// 기본 플랫폼 전환(안드로이드의 갑작스러운 우측 슬라이드 등) 대신
/// 페이드 + 미세 상향 슬라이드(fade-through)로 부드럽게 전환한다.
/// GoRoute의 `pageBuilder`에서 사용한다.
CustomTransitionPage<T> buildPageWithFadeThrough<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
