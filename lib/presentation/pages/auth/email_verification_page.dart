import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/email_verification_bloc.dart';
import '../../blocs/auth/email_verification_event.dart';
import '../../blocs/auth/email_verification_state.dart';
import '../../widgets/gradient_button.dart';

/// 이메일 인증 안내 페이지
class EmailVerificationPage extends StatelessWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: Text(AppLocalizations.of(context)!.authEmailVerification),
      ),
      body: BlocConsumer<EmailVerificationBloc, EmailVerificationState>(
        listener: (context, state) {
          if (state.status == EmailVerificationStatus.resent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Text(
                    AppLocalizations.of(context)!.authVerificationEmailResent),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.status == EmailVerificationStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Text(state.errorMessage ??
                    AppLocalizations.of(context)!.authErrorOccurred),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isResending =
              state.status == EmailVerificationStatus.resending;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 브랜드 그라데이션 스퀴클 아이콘 ──
                      Center(
                        child: Container(
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
                            Icons.mark_email_unread_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        AppLocalizations.of(context)!.authEmailVerificationRequired,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: context.textPrimaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // ── 발송된 이메일 강조 칩 ──
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: context.isDarkMode
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.isDarkMode
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.authVerificationLinkGuide,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textSecondaryColor,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // ── 재발송 (주요 CTA) ──
                      GradientButton(
                        onPressed: isResending
                            ? null
                            : () {
                                context.read<EmailVerificationBloc>().add(
                                      EmailVerificationResendRequested(email),
                                    );
                              },
                        isLoading: isResending,
                        icon: Icons.refresh_rounded,
                        label: AppLocalizations.of(context)!
                            .authResendVerificationEmail,
                      ),
                      const SizedBox(height: 14),
                      // ── 로그인으로 돌아가기 (보조 액션) ──
                      SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimaryColor,
                            side: BorderSide(color: context.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.authBackToLogin,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
