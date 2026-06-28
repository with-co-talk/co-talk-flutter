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
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.profileAvatar,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.textPrimaryColor,
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
                Divider(
                  height: 1,
                  color: context.dividerColor.withValues(alpha: 0.6),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profileResetToDefault,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
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
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
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
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.profileBackground,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.textPrimaryColor,
                ),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: AppColors.primary),
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
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(AppLocalizations.of(context)!.profileAvatarDeleteTitle),
        content: Text(AppLocalizations.of(context)!.profileAvatarDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }
}

/// 바텀시트 상단 드래그 핸들.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(2),
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
