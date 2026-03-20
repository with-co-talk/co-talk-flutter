import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/profile/handlers/image_cropper_handler.dart';

void main() {
  late ImageCropperHandler handler;

  setUp(() {
    handler = ImageCropperHandler();
  });

  group('ImageCropperHandler.resolveUploadPath', () {
    test('returns null when pickedPath is empty string', () {
      final result = handler.resolveUploadPath(
        pickedPath: '',
        croppedPath: '/some/cropped.jpg',
        cropSupported: true,
      );

      expect(result, isNull);
    });

    test('returns pickedPath when cropSupported is false', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/original/photo.jpg',
        croppedPath: null,
        cropSupported: false,
      );

      expect(result, equals('/original/photo.jpg'));
    });

    test('returns pickedPath when cropSupported is false even with croppedPath', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/original/photo.jpg',
        croppedPath: '/cropped/photo.jpg',
        cropSupported: false,
      );

      expect(result, equals('/original/photo.jpg'));
    });

    test('returns croppedPath when cropSupported is true and croppedPath is valid', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/original/photo.jpg',
        croppedPath: '/cropped/photo.jpg',
        cropSupported: true,
      );

      expect(result, equals('/cropped/photo.jpg'));
    });

    test('returns null when cropSupported is true and croppedPath is null (user cancelled crop)', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/original/photo.jpg',
        croppedPath: null,
        cropSupported: true,
      );

      expect(result, isNull);
    });

    test('returns null when cropSupported is true and croppedPath is empty (user cancelled crop)', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/original/photo.jpg',
        croppedPath: '',
        cropSupported: true,
      );

      expect(result, isNull);
    });
  });

  group('ImageCropperHandler.cropImageForAvatar - non-existent file', () {
    test('returns null when source file does not exist', () async {
      const nonExistentPath = '/non/existent/path/image.jpg';

      final result = await handler.cropImageForAvatar(nonExistentPath);

      expect(result, isNull);
    });
  });

  group('ImageCropperHandler.cropImageForBackground - non-existent file', () {
    test('returns null when source file does not exist', () async {
      const nonExistentPath = '/non/existent/path/background.jpg';

      final result = await handler.cropImageForBackground(nonExistentPath);

      expect(result, isNull);
    });
  });

  group('ImageCropperHandler - resolveUploadPath edge cases', () {
    test('handles whitespace-only path by treating it as valid (non-empty)', () {
      final result = handler.resolveUploadPath(
        pickedPath: '   ',
        croppedPath: null,
        cropSupported: false,
      );

      // '   ' is not empty so it should be returned as-is when not crop supported
      expect(result, equals('   '));
    });

    test('returns croppedPath even when pickedPath is different', () {
      final result = handler.resolveUploadPath(
        pickedPath: '/tmp/original.png',
        croppedPath: '/tmp/cropped.png',
        cropSupported: true,
      );

      expect(result, equals('/tmp/cropped.png'));
      expect(result, isNot(equals('/tmp/original.png')));
    });

    test('cropSupported false ignores croppedPath completely', () {
      const picked = '/picked/image.jpg';
      const cropped = '/cropped/image.jpg';

      final result = handler.resolveUploadPath(
        pickedPath: picked,
        croppedPath: cropped,
        cropSupported: false,
      );

      expect(result, equals(picked));
    });
  });
}
