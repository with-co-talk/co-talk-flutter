import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
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
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : avatarUrl != null
                            ? NetworkImage(avatarUrl!) as ImageProvider
                            : null,
                    child: (selectedImage == null && avatarUrl == null)
                        ? Text(
                            nickname.isNotEmpty
                                ? nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.grey : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
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
            label: const Text('사진 변경'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
