import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
      label: '배경화면',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
                label: const Text('배경 변경'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onViewHistory,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('배경 이력'),
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
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.textPrimaryColor,
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
