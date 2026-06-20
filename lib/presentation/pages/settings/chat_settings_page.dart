import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../blocs/settings/chat_settings_cubit.dart';
import '../../blocs/settings/chat_settings_state.dart';

/// 채팅 설정 페이지
class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key});

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  /// 모바일 플랫폼 여부
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    context.read<ChatSettingsCubit>().loadSettings();
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
        title: const Text('채팅 설정'),
      ),
      backgroundColor: context.backgroundColor,
      body: BlocConsumer<ChatSettingsCubit, ChatSettingsState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            (current.status == ChatSettingsStatus.clearing ||
                (previous.status == ChatSettingsStatus.clearing &&
                    (current.status == ChatSettingsStatus.loaded ||
                        current.status == ChatSettingsStatus.error))),
        listener: (context, state) {
          if (state.status == ChatSettingsStatus.clearing) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Text('캐시를 삭제하는 중...'),
              ),
            );
          } else if (state.status == ChatSettingsStatus.loaded) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: const Text('캐시가 삭제되었습니다'),
                  backgroundColor: AppColors.success,
                ),
              );
          } else if (state.status == ChatSettingsStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Text(state.errorMessage ?? '오류가 발생했습니다'),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state.status == ChatSettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8),
            children: [
              _buildSection(
                title: '글꼴 크기',
                children: [
                  _buildFontSizeSlider(state),
                  _buildFontSizePreview(state),
                ],
              ),
              _buildSection(
                title: '미디어 자동 다운로드',
                children: _isMobile
                    ? [
                        // 모바일: Wi-Fi/모바일 데이터 구분
                        _buildSubsectionTitle('이미지'),
                        _buildSwitchTile(
                          icon: Icons.wifi,
                          title: 'Wi-Fi 연결 시',
                          value: state.settings.autoDownloadImagesOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.signal_cellular_alt,
                          title: '모바일 데이터 사용 시',
                          value: state.settings.autoDownloadImagesOnMobile,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnMobile(value);
                          },
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        _buildSubsectionTitle('동영상'),
                        _buildSwitchTile(
                          icon: Icons.wifi,
                          title: 'Wi-Fi 연결 시',
                          value: state.settings.autoDownloadVideosOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadVideosOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.signal_cellular_alt,
                          title: '모바일 데이터 사용 시',
                          value: state.settings.autoDownloadVideosOnMobile,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadVideosOnMobile(value);
                          },
                        ),
                      ]
                    : [
                        // 데스크톱: 단순 on/off (Wi-Fi 설정을 네트워크 설정으로 사용)
                        _buildSwitchTile(
                          icon: Icons.image_outlined,
                          title: '이미지 자동 다운로드',
                          value: state.settings.autoDownloadImagesOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.videocam_outlined,
                          title: '동영상 자동 다운로드',
                          value: state.settings.autoDownloadVideosOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadVideosOnWifi(value);
                          },
                        ),
                      ],
              ),
              _buildSection(
                title: '저장 공간',
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: _leadingChip(Icons.cleaning_services_outlined),
                    title: Text(
                      '캐시 삭제',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '임시 저장된 데이터를 삭제합니다',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                    trailing: state.status == ChatSettingsStatus.clearing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: context.textSecondaryColor
                                .withValues(alpha: 0.6),
                          ),
                    onTap: state.status == ChatSettingsStatus.clearing
                        ? null
                        : () => _showClearCacheDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          child: Text(
            title,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _leadingChip(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      secondary: _leadingChip(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: context.textPrimaryColor,
        ),
      ),
      value: value,
      onChanged: (v) {
        AppHaptics.selection();
        onChanged(v);
      },
    );
  }

  Widget _buildFontSizeSlider(ChatSettingsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '작게',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
              Text(
                '크게',
                style: TextStyle(
                  fontSize: 17,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              inactiveTrackColor:
                  AppColors.primary.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: state.settings.fontSize,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: _getFontSizeLabel(state.settings.fontSize),
              onChanged: (value) {
                context.read<ChatSettingsCubit>().setFontSize(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizePreview(ChatSettingsState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미리보기',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '안녕하세요! 글꼴 크기를 조절해보세요.',
            style: TextStyle(
              fontSize: 16 * state.settings.fontSize,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hello! Try adjusting the font size.',
            style: TextStyle(
              fontSize: 14 * state.settings.fontSize,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getFontSizeLabel(double fontSize) {
    if (fontSize <= 0.85) return '아주 작게';
    if (fontSize <= 0.95) return '작게';
    if (fontSize <= 1.05) return '보통';
    if (fontSize <= 1.15) return '크게';
    if (fontSize <= 1.25) return '아주 크게';
    return '매우 크게';
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('임시 저장된 데이터를 삭제하시겠습니까?\n다운로드한 이미지와 동영상 캐시가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ChatSettingsCubit>().clearCache();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
