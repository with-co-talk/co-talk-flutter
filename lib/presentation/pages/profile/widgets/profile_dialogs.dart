import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileDialogs {
  /// Show image source picker for avatar
  static Future<ImageSourceChoice?> showAvatarSourcePicker(
    BuildContext context, {
    required bool hasAvatar,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onHistory,
    required VoidCallback onDelete,
  }) async {
    return showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.profileAvatar,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileTakePhoto),
                subtitle: Text(AppLocalizations.of(context)!.profileTakePhotoSubtitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromAlbum),
                subtitle: Text(AppLocalizations.of(context)!.profileSelectFromAlbumSubtitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromExisting),
                subtitle: Text(AppLocalizations.of(context)!.profileSelectFromExistingSubtitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onHistory();
                },
              ),
              if (hasAvatar) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profileResetToDefault,
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.profileResetToDefaultSubtitle),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    onDelete();
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show file picker for desktop (avatar)
  static Future<ImageSourceChoice?> showDesktopFilePicker(
    BuildContext context, {
    required VoidCallback onFilePick,
  }) async {
    return showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.folder_open, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromFile),
                subtitle: Text(AppLocalizations.of(context)!.profileSelectFromFileSubtitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onFilePick();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show background image source picker
  static Future<ImageSourceChoice?> showBackgroundSourcePicker(
    BuildContext context, {
    required VoidCallback onGallery,
    required VoidCallback onHistory,
  }) async {
    return showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.profileBackground,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromAlbum),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: Colors.grey),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromBackgroundHistory),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onHistory();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show desktop file picker for background
  static Future<ImageSourceChoice?> showDesktopBackgroundFilePicker(
    BuildContext context, {
    required VoidCallback onFilePick,
  }) async {
    return showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.folder_open, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.profileSelectFromFile),
                subtitle: Text(AppLocalizations.of(context)!.profileSelectBackgroundFileSubtitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onFilePick();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show delete avatar confirmation dialog
  static Future<bool?> showDeleteAvatarConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profileAvatarDeleteTitle),
        content: Text(AppLocalizations.of(context)!.profileAvatarDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }
}

enum ImageSourceChoice {
  camera,
  gallery,
  file,
  history,
  delete,
}
