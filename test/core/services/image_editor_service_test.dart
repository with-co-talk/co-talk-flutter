import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/services/image_editor_service.dart';

void main() {
  group('ImageEditorService', () {
    late ImageEditorService service;

    setUp(() {
      service = ImageEditorService();
    });

    group('editImage', () {
      testWidgets('returns null (stub implementation)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return const SizedBox();
              },
            ),
          ),
        );

        final context = tester.element(find.byType(SizedBox));
        final file = File('/tmp/test_image.jpg');

        final result = await service.editImage(
          context: context,
          imageFile: file,
        );

        expect(result, isNull);
      });

      testWidgets('returns null regardless of the input file', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));

        // Different file paths all return null
        for (final path in [
          '/tmp/photo.jpg',
          '/tmp/image.png',
          '/tmp/avatar.heic',
        ]) {
          final result = await service.editImage(
            context: context,
            imageFile: File(path),
          );
          expect(result, isNull, reason: 'Expected null for path: $path');
        }
      });

      testWidgets('can be called multiple times without side effects', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final file = File('/tmp/test.jpg');

        final result1 = await service.editImage(context: context, imageFile: file);
        final result2 = await service.editImage(context: context, imageFile: file);

        expect(result1, isNull);
        expect(result2, isNull);
      });
    });

    group('service instantiation', () {
      test('can be instantiated directly', () {
        expect(() => ImageEditorService(), returnsNormally);
      });

      test('is not a singleton by construction - two instances are separate objects', () {
        final s1 = ImageEditorService();
        final s2 = ImageEditorService();
        // Both are valid separate instances; they are not identical references
        expect(identical(s1, s2), isFalse);
      });
    });
  });
}
