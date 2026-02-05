import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile == null) return null;
      final path = pickedFile.path;
      if (path.isEmpty) return null;
      return File(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery({
    double maxWidth = 512,
    double maxHeight = 512,
    int imageQuality = 80,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      if (pickedFile == null) return null;
      final path = pickedFile.path;
      if (path.isEmpty) return null;
      return File(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from file (for desktop platforms)
  Future<File?> pickFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      File? imageFile;

      if (file.path != null && file.path!.isNotEmpty) {
        imageFile = File(file.path!);
      } else if (file.bytes != null && file.bytes!.isNotEmpty) {
        final tempDir = await Directory.systemTemp.createTemp('cotalk_image');
        final tempFile = File(
          '${tempDir.path}/picked_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(file.bytes!);
        imageFile = tempFile;
      }

      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image for background
  Future<File?> pickBackgroundFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;
      final path = pickedFile.path;
      if (path.isEmpty) return null;
      return File(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Pick background image from file (for desktop platforms)
  Future<File?> pickBackgroundFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      File? imageFile;
      if (file.path != null && file.path!.isNotEmpty) {
        imageFile = File(file.path!);
      } else if (file.bytes != null && file.bytes!.isNotEmpty) {
        final tempDir = await Directory.systemTemp.createTemp('cotalk_bg');
        final tempFile = File(
          '${tempDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(file.bytes!);
        imageFile = tempFile;
      }
      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if running on desktop platform
  bool get isDesktop => _isDesktop;

  /// Check if image cropper is supported
  bool get isImageCropperSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
