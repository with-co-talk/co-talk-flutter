import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/forgot_password_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRequestCode() {
    if (_emailFormKey.currentState!.validate()) {
      context.read<ForgotPasswordBloc>().add(
            ForgotPasswordCodeRequested(email: _emailController.text.trim()),
          );
    }
  }

  void _onVerifyCode() {
    if (_codeFormKey.currentState!.validate()) {
      context.read<ForgotPasswordBloc>().add(
            ForgotPasswordCodeVerified(
              email: _emailController.text.trim(),
              code: _codeController.text.trim(),
            ),
          );
    }
  }

  void _onResetPassword() {
    if (_passwordFormKey.currentState!.validate()) {
      final state = context.read<ForgotPasswordBloc>().state;
      context.read<ForgotPasswordBloc>().add(
            ForgotPasswordResetRequested(
              email: state.email ?? _emailController.text.trim(),
              code: state.code ?? _codeController.text.trim(),
              newPassword: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state.status == ForgotPasswordStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.step == ForgotPasswordStep.complete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('비밀번호가 성공적으로 변경되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildStepContent(state),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(ForgotPasswordState state) {
    switch (state.step) {
      case ForgotPasswordStep.email:
        return _buildEmailStep(state);
      case ForgotPasswordStep.code:
        return _buildCodeStep(state);
      case ForgotPasswordStep.newPassword:
        return _buildPasswordStep(state);
      case ForgotPasswordStep.complete:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep(ForgotPasswordState state) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            '가입한 이메일 주소를 입력해주세요.\n인증 코드를 발송해드립니다.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _onRequestCode(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.status == ForgotPasswordStatus.loading
                  ? null
                  : _onRequestCode,
              child: state.status == ForgotPasswordStatus.loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('인증 코드 받기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(ForgotPasswordState state) {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.pin_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            '${state.email}으로\n인증 코드를 발송했습니다.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: '인증 코드 (6자리)',
              prefixIcon: Icon(Icons.dialpad_rounded),
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '인증 코드를 입력해주세요';
              }
              if (value.length != 6) {
                return '6자리 코드를 입력해주세요';
              }
              return null;
            },
            onFieldSubmitted: (_) => _onVerifyCode(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.status == ForgotPasswordStatus.loading
                  ? null
                  : _onVerifyCode,
              child: state.status == ForgotPasswordStatus.loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('인증 코드 확인'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.status == ForgotPasswordStatus.loading
                ? null
                : () {
                    context.read<ForgotPasswordBloc>().add(
                          ForgotPasswordCodeRequested(
                            email: state.email ?? _emailController.text.trim(),
                          ),
                        );
                  },
            child: const Text('인증 코드 재발송'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(ForgotPasswordState state) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_open_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            '새로운 비밀번호를 입력해주세요.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '새 비밀번호',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: '새 비밀번호 확인',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) => Validators.confirmPassword(value, _passwordController.text),
            onFieldSubmitted: (_) => _onResetPassword(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.status == ForgotPasswordStatus.loading
                  ? null
                  : _onResetPassword,
              child: state.status == ForgotPasswordStatus.loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('비밀번호 변경'),
            ),
          ),
        ],
      ),
    );
  }
}
