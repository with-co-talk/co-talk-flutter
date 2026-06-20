import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../blocs/settings/biometric_settings_cubit.dart';
import '../../blocs/settings/biometric_settings_state.dart';

/// 보안 설정 페이지
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('보안')),
      body: BlocBuilder<BiometricSettingsCubit, BiometricSettingsState>(
        builder: (context, state) {
          if (state.status == BiometricSettingsStatus.loading ||
              state.status == BiometricSettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final isDark = context.isDarkMode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!state.isSupported)
                _InfoBanner(
                  icon: Icons.info_outline_rounded,
                  text: '이 기기는 생체 인증을 지원하지 않습니다.',
                  tone: context.textSecondaryColor,
                ),
              if (!state.isSupported) const SizedBox(height: 16),
              // 생체 인증 토글 카드
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  secondary: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    '생체 인증',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      state.isSupported
                          ? '앱 잠금 해제 시 생체 인증을 사용합니다'
                          : '이 기기에서 사용할 수 없습니다',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                  value: state.isEnabled,
                  onChanged: state.isSupported
                      ? (_) {
                          AppHaptics.selection();
                          context.read<BiometricSettingsCubit>().toggle();
                        }
                      : null,
                ),
              ),
              if (state.isEnabled) ...[
                const SizedBox(height: 14),
                _InfoBanner(
                  icon: Icons.lock_clock_outlined,
                  text:
                      '앱을 30초 이상 백그라운드에 둔 후 복귀하면 생체 인증을 요청합니다.',
                  tone: context.textSecondaryColor,
                ),
              ],
              if (state.status == BiometricSettingsStatus.error &&
                  state.errorMessage != null) ...[
                const SizedBox(height: 14),
                _InfoBanner(
                  icon: Icons.error_outline_rounded,
                  text: state.errorMessage!,
                  tone: AppColors.error,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 보안 화면용 정보/경고 배너 — 톤에 맞춘 은은한 틴트 박스.
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tone;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
