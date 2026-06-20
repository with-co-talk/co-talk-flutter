import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_upload_path_resolver.dart';

class ImageCropperHandler {
  /// 카톡 스타일 공통 크로퍼 UI 설정 (브랜드 색 + 비율 고정 + 비율선택 숨김)
  List<PlatformUiSettings> _uiSettings({
    required String title,
    required CropStyle cropStyle,
    required CropAspectRatioPreset initRatio,
  }) {
    return [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        backgroundColor: Colors.black,
        activeControlsWidgetColor: AppColors.primary,
        cropFrameColor: Colors.white,
        cropGridColor: Colors.white24,
        dimmedLayerColor: Colors.black.withValues(alpha: 0.75),
        cropStyle: cropStyle,
        lockAspectRatio: true,
        hideBottomControls: true,
        showCropGrid: false,
        initAspectRatio: initRatio,
        aspectRatioPresets: [initRatio],
      ),
      IOSUiSettings(
        title: title,
        cropStyle: cropStyle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        rotateButtonsHidden: false,
        doneButtonTitle: '완료',
        cancelButtonTitle: '취소',
        aspectRatioPresets: [initRatio],
      ),
    ];
  }

  /// Crop image for avatar (정사각 고정 + 원형 오버레이 — 카톡 프로필 스타일)
  Future<File?> cropImageForAvatar(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        return null;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: _uiSettings(
          title: '프로필 사진 편집',
          cropStyle: CropStyle.circle,
          initRatio: CropAspectRatioPreset.square,
        ),
      );

      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Crop image for background (16:9 와이드 고정 — 커버 스타일)
  Future<File?> cropImageForBackground(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        return null;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: _uiSettings(
          title: '배경 사진 편집',
          cropStyle: CropStyle.rectangle,
          initRatio: CropAspectRatioPreset.ratio16x9,
        ),
      );

      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Resolve the final path to upload (with crop fallback handling)
  String? resolveUploadPath({
    required String pickedPath,
    String? croppedPath,
    required bool cropSupported,
  }) {
    return ImageUploadPathResolver.resolveUploadPath(
      pickedPath: pickedPath,
      croppedPath: croppedPath,
      cropSupported: cropSupported,
    );
  }
}
