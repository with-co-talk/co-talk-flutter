import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class ErrorPage extends StatelessWidget {
  final String? message;

  const ErrorPage({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('오류'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 친근한 에러 아이콘 (보라 틴트 원) ──
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.10),
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 44,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '문제가 발생했어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ?? '페이지를 불러올 수 없습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    onPressed: () => context.go(AppRoutes.friends),
                    label: '홈으로 돌아가기',
                    icon: Icons.home_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
