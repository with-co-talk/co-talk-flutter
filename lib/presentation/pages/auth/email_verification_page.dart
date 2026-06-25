import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/email_verification_bloc.dart';
import '../../blocs/auth/email_verification_event.dart';
import '../../blocs/auth/email_verification_state.dart';

/// 이메일 인증 안내 페이지
class EmailVerificationPage extends StatelessWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: Text(AppLocalizations.of(context)!.authEmailVerification),
      ),
      body: BlocConsumer<EmailVerificationBloc, EmailVerificationState>(
        listener: (context, state) {
          if (state.status == EmailVerificationStatus.resent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.authVerificationEmailResent),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == EmailVerificationStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppLocalizations.of(context)!.authErrorOccurred),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)!.authEmailVerificationRequired,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.authVerificationEmailSentTo(email),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.authVerificationLinkGuide,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: state.status ==
                                  EmailVerificationStatus.resending
                              ? null
                              : () {
                                  context.read<EmailVerificationBloc>().add(
                                        EmailVerificationResendRequested(email),
                                      );
                                },
                          child: state.status ==
                                  EmailVerificationStatus.resending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(AppLocalizations.of(context)!.authResendVerificationEmail),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(AppLocalizations.of(context)!.authBackToLogin),
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
