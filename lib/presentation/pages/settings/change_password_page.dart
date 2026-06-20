import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/settings/change_password_bloc.dart';
import '../../blocs/settings/change_password_event.dart';
import '../../blocs/settings/change_password_state.dart';
import '../../widgets/gradient_button.dart';

/// 비밀번호 변경 페이지
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        title: const Text('비밀번호 변경'),
      ),
      backgroundColor: context.backgroundColor,
      body: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          if (state.status == ChangePasswordStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Text('비밀번호가 성공적으로 변경되었습니다.'),
                backgroundColor: AppColors.success,
              ),
            );
            if (context.canPop()) {
              context.pop();
            }
          } else if (state.status == ChangePasswordStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? '오류가 발생했습니다'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ChangePasswordStatus.loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: '현재 비밀번호',
                    obscure: _obscureCurrentPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '현재 비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: '새 비밀번호',
                    obscure: _obscureNewPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 입력해주세요';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다';
                      }
                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                        return '영문과 숫자를 포함해야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: '새 비밀번호 확인',
                    obscure: _obscureConfirmPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 다시 입력해주세요';
                      }
                      if (value != _newPasswordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordRequirements(),
                  const SizedBox(height: 32),
                  GradientButton(
                    onPressed: isLoading ? null : _handleChangePassword,
                    isLoading: isLoading,
                    label: '비밀번호 변경',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '비밀번호 요구 사항',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildRequirement('최소 8자 이상'),
          _buildRequirement('영문 대/소문자 포함'),
          _buildRequirement('숫자 포함'),
          _buildRequirement('특수문자 포함'),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ChangePasswordBloc>().add(
          ChangePasswordSubmitted(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          ),
        );
  }
}
