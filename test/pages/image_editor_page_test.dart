import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/image_editor/image_editor_page.dart';

void main() {
  group('ImageEditorPage', () {
    test('ImageEditorPage를 생성할 수 있다', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_image.png');

      final page = ImageEditorPage(imageFile: tempFile);

      expect(page.imageFile, tempFile);
      expect(page.onSend, isNull);
    });

    test('onSend 콜백을 지정하여 생성할 수 있다', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_image.png');
      void onSend(File f) {}

      final page = ImageEditorPage(imageFile: tempFile, onSend: onSend);

      expect(page.imageFile, tempFile);
      expect(page.onSend, isNotNull);
    });
  });
}
