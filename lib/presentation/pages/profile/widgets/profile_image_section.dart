import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileImageSection extends StatelessWidget {
  final String? avatarUrl;
  final String nickname;
  final File? selectedImage;
  final bool isLoading;
  final VoidCallback onTap;

  const ProfileImageSection({
    super.key,
    required this.avatarUrl,
    required this.nickname,
    this.selectedImage,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            AppColors.primaryLight.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile image with edit button
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Stack(
              children: [
                // Profile avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.surfaceColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : avatarUrl != null
                            ? CachedNetworkImageProvider(
                                avatarUrl!,
                                maxWidth: 400,
                              ) as ImageProvider
                            : null,
                    child: (selectedImage == null && avatarUrl == null)
                        ? Text(
                            nickname.isNotEmpty
                                ? nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
                // Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                // Edit icon
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : const LinearGradient(
                              colors: AppColors.brandGradient,
                            ),
                      color: isLoading
                          ? context.textSecondaryColor
                          : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Change photo button
          TextButton.icon(
            onPressed: isLoading ? null : onTap,
            icon: const Icon(Icons.edit, size: 16),
            label: Text(AppLocalizations.of(context)!.profileChangePhoto),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
