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
              const SnackBar(
                content: Text('회원 탈퇴가 완료되었습니다'),
              ),
            );
            context.go(AppRoutes.login);
          } else if (state.status == AccountDeletionStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? '오류가 발생했습니다'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.canDelete && !_countdownComplete && _countdownTimer == null) {
            _startCountdown();
          }
        },
        builder: (context, state) {
          if (state.status == AccountDeletionStatus.deleting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('탈퇴 처리 중...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningCard(),
                const SizedBox(height: 24),
                _buildPasswordSection(state),
                const SizedBox(height: 24),
                _buildConfirmationSection(state),
                const SizedBox(height: 32),
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
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  '주의',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '회원 탈퇴 시 다음 데이터가 영구적으로 삭제됩니다:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildWarningItem('모든 채팅 내역'),
            _buildWarningItem('친구 목록'),
            _buildWarningItem('프로필 정보'),
            _buildWarningItem('알림 설정'),
            const SizedBox(height: 12),
            Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.remove, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(AccountDeletionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. 비밀번호 확인',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '현재 비밀번호',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
      ],
    );
  }

  Widget _buildConfirmationSection(AccountDeletionState state) {
    final isEnabled = state.password != null && state.password!.isNotEmpty;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. 탈퇴 확인',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '탈퇴를 확인하려면 아래에 "삭제합니다"를 입력하세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmationController,
            enabled: isEnabled,
            decoration: const InputDecoration(
              labelText: '삭제합니다',
              border: OutlineInputBorder(),
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
            const SizedBox(height: 4),
            Text(
              '"삭제합니다"를 정확히 입력해주세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeleteButton(AccountDeletionState state) {
    final canPressButton = state.canDelete && _countdownComplete;

    return Column(
      children: [
        if (state.canDelete && !_countdownComplete) ...[
          Text(
            '$_countdown초 후 탈퇴 버튼이 활성화됩니다',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton(
          onPressed: canPressButton ? () => _showFinalConfirmDialog() : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
          ),
          child: Text(
            canPressButton ? '회원 탈퇴' : '회원 탈퇴 (${_countdownComplete ? "입력 완료 필요" : "$_countdown초"})',
          ),
        ),
      ],
    );
  }

  void _showFinalConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
