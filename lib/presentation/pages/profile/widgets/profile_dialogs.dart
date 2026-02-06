import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
              const Text(
                '프로필 사진',
                style: TextStyle(
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
                title: const Text('카메라로 촬영'),
                subtitle: const Text('새 사진 찍기'),
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
                title: const Text('앨범에서 선택'),
                subtitle: const Text('저장된 사진 선택'),
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
                title: const Text('기존 프로필에서 선택'),
                subtitle: const Text('이전에 사용한 사진 선택'),
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
                  title: const Text(
                    '기본 이미지로 변경',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('현재 프로필 사진 삭제'),
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
                title: const Text('파일에서 선택'),
                subtitle: const Text('이미지 파일을 선택합니다'),
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
              const Text(
                '배경화면',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                title: const Text('앨범에서 선택'),
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
                title: const Text('배경 이력에서 선택'),
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
                title: const Text('파일에서 선택'),
                subtitle: const Text('배경 이미지 파일을 선택합니다'),
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
        title: const Text('프로필 사진 삭제'),
        content: const Text('프로필 사진을 삭제하고 기본 이미지로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
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
