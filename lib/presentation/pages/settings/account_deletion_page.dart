import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/settings/account_deletion_bloc.dart';
import '../../blocs/settings/account_deletion_event.dart';
import '../../blocs/settings/account_deletion_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

/// 회원 탈퇴 페이지
///
/// 강력한 확인 UX:
/// 1. 경고 메시지
/// 2. 비밀번호 입력
/// 3. "삭제합니다" 텍스트 입력
/// 4. 5초 카운트다운 후 버튼 활성화
/// 5. 최종 확인 다이얼로그
class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _countdownComplete = false;

  @override
  void initState() {
    super.initState();
    context.read<AccountDeletionBloc>().add(const AccountDeletionReset());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_countdownTimer != null) return;

    setState(() {
      _countdown = 5;
      _countdownComplete = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownComplete = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.settings);
            }
          },
        ),
        title: const Text('회원 탈퇴'),
      ),
      body: BlocConsumer<AccountDeletionBloc, AccountDeletionState>(
        listener: (context, state) {
          if (state.status == AccountDeletionStatus.deleted) {
            // 탈퇴 성공 - 로그아웃 처리 후 로그인 화면으로 이동
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Text('회원 탈퇴가 완료되었습니다'),
              ),
            );
            context.go(AppRoutes.login);
          } else if (state.status == AccountDeletionStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Text(state.errorMessage ?? '오류가 발생했습니다'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.canDelete &&
              !_countdownComplete &&
              _countdownTimer == null) {
            _startCountdown();
          }
        },
        builder: (context, state) {
          if (state.status == AccountDeletionStatus.deleting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '탈퇴 처리 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningCard(),
                const SizedBox(height: 20),
                _buildPasswordSection(state),
                const SizedBox(height: 16),
                _buildConfirmationSection(state),
                const SizedBox(height: 28),
                _buildDeleteButton(state),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '주의',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '회원 탈퇴 시 다음 데이터가 영구적으로 삭제됩니다',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildWarningItem('모든 채팅 내역'),
          _buildWarningItem('친구 목록'),
          _buildWarningItem('프로필 정보'),
          _buildWarningItem('알림 설정'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.do_not_disturb_on_outlined,
                  size: 17,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 작업은 되돌릴 수 없습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(AccountDeletionState state) {
    return _StepCard(
      step: '1',
      title: '비밀번호 확인',
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: '현재 비밀번호',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        onChanged: (value) {
          context.read<AccountDeletionBloc>().add(
                AccountDeletionPasswordEntered(value),
              );
        },
      ),
    );
  }

  Widget _buildConfirmationSection(AccountDeletionState state) {
    final isEnabled = state.password != null && state.password!.isNotEmpty;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: _StepCard(
        step: '2',
        title: '탈퇴 확인',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
                children: [
                  const TextSpan(text: '탈퇴를 확인하려면 아래에 '),
                  TextSpan(
                    text: '"삭제합니다"',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const TextSpan(text: '를 입력하세요.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationController,
              enabled: isEnabled,
              decoration: const InputDecoration(
                labelText: '삭제합니다',
                prefixIcon: Icon(Icons.edit_outlined),
                hintText: '삭제합니다',
              ),
              onChanged: (value) {
                context.read<AccountDeletionBloc>().add(
                      AccountDeletionConfirmationEntered(value),
                    );
              },
            ),
            if (state.confirmationText != null &&
                state.confirmationText!.isNotEmpty &&
                state.confirmationText != '삭제합니다') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '"삭제합니다"를 정확히 입력해주세요',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(AccountDeletionState state) {
    final canPressButton = state.canDelete && _countdownComplete;

    return Column(
      children: [
        if (state.canDelete && !_countdownComplete) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 17,
                  color: context.isDarkMode
                      ? AppColors.warning
                      : const Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_countdown초 후 탈퇴 버튼이 활성화됩니다',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.isDarkMode
                        ? AppColors.warning
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canPressButton ? () => _showFinalConfirmDialog() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            child: Text(
              canPressButton
                  ? '회원 탈퇴'
                  : '회원 탈퇴 (${_countdownComplete ? "입력 완료 필요" : "$_countdown초"})',
            ),
          ),
        ),
      ],
    );
  }

  void _showFinalConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('최종 확인'),
          ],
        ),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n\n모든 데이터가 영구적으로 삭제되며, 이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AccountDeletionBloc>().add(
                    const AccountDeletionRequested(),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}

/// 단계별 입력 카드 — 브랜드 번호 배지 + 제목 + 콘텐츠.
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.20 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradient,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
