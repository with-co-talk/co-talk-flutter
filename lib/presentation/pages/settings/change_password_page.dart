import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.settingsChangePassword),
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
                content: Text(AppLocalizations.of(context)!.settingsPasswordChangeSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            if (context.canPop()) {
              context.pop();
            }
          } else if (state.status == ChangePasswordStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppLocalizations.of(context)!.settingsErrorOccurred),
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
                    label: AppLocalizations.of(context)!.settingsCurrentPassword,
                    obscure: _obscureCurrentPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.settingsCurrentPasswordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: AppLocalizations.of(context)!.settingsNewPassword,
                    obscure: _obscureNewPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.settingsNewPasswordRequired;
                      }
                      if (value.length < 8) {
                        return AppLocalizations.of(context)!.settingsPasswordMinLength;
                      }
                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                        return AppLocalizations.of(context)!.settingsPasswordAlphanumeric;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: AppLocalizations.of(context)!.settingsConfirmNewPassword,
                    obscure: _obscureConfirmPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.settingsConfirmPasswordRequired;
                      }
                      if (value != _newPasswordController.text) {
                        return AppLocalizations.of(context)!.settingsPasswordMismatch;
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
                    label: AppLocalizations.of(context)!.settingsChangePassword,
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
            AppLocalizations.of(context)!.settingsPasswordRequirements,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          // 입력값에 따라 실시간으로 충족 여부 표시 (회색 → 보라 체크)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _newPasswordController,
            builder: (context, value, _) {
              final pw = value.text;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequirement(
                    AppLocalizations.of(context)!.settingsPasswordReqMinLength,
                    pw.length >= 8,
                  ),
                  _buildRequirement(
                    AppLocalizations.of(context)!.settingsPasswordReqLetters,
                    RegExp(r'[A-Z]').hasMatch(pw) &&
                        RegExp(r'[a-z]').hasMatch(pw),
                  ),
                  _buildRequirement(
                    AppLocalizations.of(context)!.settingsPasswordReqNumbers,
                    RegExp(r'\d').hasMatch(pw),
                  ),
                  _buildRequirement(
                    AppLocalizations.of(context)!.settingsPasswordReqSpecial,
                    RegExp(r'[^A-Za-z0-9]').hasMatch(pw),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: met
                ? AppColors.primary
                : context.textSecondaryColor.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              color: met ? context.textPrimaryColor : context.textSecondaryColor,
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
