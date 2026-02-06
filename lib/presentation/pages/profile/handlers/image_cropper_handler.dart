import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/utils/image_upload_path_resolver.dart';

class ImageCropperHandler {
  /// Crop image for avatar (square crop)
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
      );

      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Crop image for background
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
