import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class BackgroundImageSection extends StatelessWidget {
  final String? backgroundUrl;
  final File? selectedBackgroundImage;
  final bool isLoading;
  final VoidCallback onChangeBackground;
  final VoidCallback onViewHistory;

  const BackgroundImageSection({
    super.key,
    required this.backgroundUrl,
    this.selectedBackgroundImage,
    required this.isLoading,
    required this.onChangeBackground,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return _buildEditCard(
      context: context,
      icon: Icons.wallpaper,
      label: AppLocalizations.of(context)!.profileBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildBackgroundImage(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: isLoading ? null : onChangeBackground,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(AppLocalizations.of(context)!.profileBackgroundChangeShort),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onViewHistory,
                icon: const Icon(Icons.history, size: 16),
                label: Text(AppLocalizations.of(context)!.profileBackgroundHistoryShort),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    if (selectedBackgroundImage != null) {
      return Image.file(
        selectedBackgroundImage!,
        fit: BoxFit.cover,
      );
    }

    if (backgroundUrl != null && backgroundUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: backgroundUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.primaryLight,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.primaryLight,
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.wallpaper, size: 48, color: Colors.white54),
      ),
    );
  }

  Widget _buildEditCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
