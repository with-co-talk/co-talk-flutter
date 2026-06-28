import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
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

  /// 슬라이더 드래그 중 로컬 값 (드래그 중 Cubit rebuild 방지)
  double? _draggingFontSize;

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
        title: Text(AppLocalizations.of(context)!.settingsChatSettings),
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
                content: Text(AppLocalizations.of(context)!.settingsClearingCache),
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
                  content: Text(AppLocalizations.of(context)!.settingsCacheCleared),
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
                  content: Text(state.errorMessage ?? AppLocalizations.of(context)!.settingsErrorOccurred),
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
                title: AppLocalizations.of(context)!.settingsFontSize,
                children: [
                  _buildFontSizeSlider(state),
                  _buildFontSizePreview(state),
                ],
              ),
              _buildSection(
                title: AppLocalizations.of(context)!.settingsMediaAutoDownload,
                children: _isMobile
                    ? [
                        // 모바일: Wi-Fi/모바일 데이터 구분
                        _buildSubsectionTitle(AppLocalizations.of(context)!.settingsImage),
                        _buildSwitchTile(
                          icon: Icons.wifi,
                          title: AppLocalizations.of(context)!.settingsOnWifi,
                          value: state.settings.autoDownloadImagesOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.signal_cellular_alt,
                          title: AppLocalizations.of(context)!.settingsOnMobileData,
                          value: state.settings.autoDownloadImagesOnMobile,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnMobile(value);
                          },
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        _buildSubsectionTitle(AppLocalizations.of(context)!.settingsVideo),
                        _buildSwitchTile(
                          icon: Icons.wifi,
                          title: AppLocalizations.of(context)!.settingsOnWifi,
                          value: state.settings.autoDownloadVideosOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadVideosOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.signal_cellular_alt,
                          title: AppLocalizations.of(context)!.settingsOnMobileData,
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
                          title: AppLocalizations.of(context)!.settingsImageAutoDownload,
                          value: state.settings.autoDownloadImagesOnWifi,
                          onChanged: (value) {
                            context
                                .read<ChatSettingsCubit>()
                                .setAutoDownloadImagesOnWifi(value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.videocam_outlined,
                          title: AppLocalizations.of(context)!.settingsVideoAutoDownload,
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
                title: AppLocalizations.of(context)!.settingsTypingDisplay,
                children: [
                  _buildSwitchTile(
                    icon: Icons.keyboard_outlined,
                    title: AppLocalizations.of(context)!.settingsTypingIndicator,
                    value: state.settings.showTypingIndicator,
                    onChanged: (value) {
                      context
                          .read<ChatSettingsCubit>()
                          .setShowTypingIndicator(value);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.settingsTypingIndicatorDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
              _buildSection(
                title: AppLocalizations.of(context)!.settingsStorage,
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: _leadingChip(Icons.cleaning_services_outlined),
                    title: Text(
                      AppLocalizations.of(context)!.settingsClearCache,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        AppLocalizations.of(context)!.settingsClearCacheDesc,
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
                AppLocalizations.of(context)!.settingsFontSizeSmall,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.settingsFontSizeLarge,
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
              value: _draggingFontSize ?? state.settings.fontSize,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: _getFontSizeLabel(
                  context, _draggingFontSize ?? state.settings.fontSize),
              onChanged: (value) {
                setState(() {
                  _draggingFontSize = value;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _draggingFontSize = null;
                });
                context.read<ChatSettingsCubit>().setFontSize(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizePreview(ChatSettingsState state) {
    final fontSize = _draggingFontSize ?? state.settings.fontSize;
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
            AppLocalizations.of(context)!.settingsPreview,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.settingsFontPreviewKorean,
            style: TextStyle(
              fontSize: 16 * fontSize,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.settingsFontPreviewEnglish,
            style: TextStyle(
              fontSize: 14 * fontSize,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getFontSizeLabel(BuildContext context, double fontSize) {
    final l10n = AppLocalizations.of(context)!;
    if (fontSize <= 0.85) return l10n.settingsFontSizeVerySmall;
    if (fontSize <= 0.95) return l10n.settingsFontSizeSmall;
    if (fontSize <= 1.05) return l10n.settingsFontSizeNormal;
    if (fontSize <= 1.15) return l10n.settingsFontSizeLarge;
    if (fontSize <= 1.25) return l10n.settingsFontSizeVeryLarge;
    return l10n.settingsFontSizeExtraLarge;
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingsClearCache),
        content: Text(AppLocalizations.of(context)!.settingsClearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ChatSettingsCubit>().clearCache();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }
}
