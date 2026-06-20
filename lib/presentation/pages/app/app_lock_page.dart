import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/app/app_lock_cubit.dart';
import '../../blocs/app/app_lock_state.dart';

/// 앱 잠금 화면
///
/// 생체 인증이 필요할 때 표시되는 오버레이 화면입니다.
class AppLockPage extends StatelessWidget {
  const AppLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        if (state.status == AppLockStatus.unlocked) {
          return const SizedBox.shrink();
        }

        final isAuthenticating = state.status == AppLockStatus.authenticating;

        return Material(
          color: context.backgroundColor,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 브랜드 로고 (그라데이션 스퀴클) + 잠금 배지 ──
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.brandGradient,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.surfaceColor,
                                border: Border.all(
                                  color: context.backgroundColor,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 17,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Co-Talk',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: context.textPrimaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '잠금을 해제하려면 인증해주세요',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondaryColor,
                                  letterSpacing: -0.2,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 44),
                      if (isAuthenticating)
                        Container(
                          height: 54,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        _UnlockButton(
                          onPressed: () {
                            context.read<AppLockCubit>().authenticate();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 생체 인증 트리거 버튼 — 그라데이션 외곽선 + 지문 아이콘.
class _UnlockButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _UnlockButton({required this.onPressed});

  @override
  State<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends State<_UnlockButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: AppColors.brandGradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                '인증하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
