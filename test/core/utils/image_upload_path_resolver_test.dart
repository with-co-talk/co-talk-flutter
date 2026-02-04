import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/image_upload_path_resolver.dart';

void main() {
  group('ImageUploadPathResolver', () {
    group('resolveUploadPath', () {
      test('🔴 RED: pickedPath가 null이면 null을 반환한다', () {
        // Given: crop 지원, croppedPath 있음
        const cropSupported = true;
        const croppedPath = '/cropped.png';

        // When: pickedPath가 null
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: null,
          croppedPath: croppedPath,
          cropSupported: cropSupported,
        );

        // Then
        expect(result, isNull);
      });

      test('🔴 RED: pickedPath가 비어있으면 null을 반환한다', () {
        // Given
        const cropSupported = true;
        const croppedPath = '/cropped.png';

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: '',
          croppedPath: croppedPath,
          cropSupported: cropSupported,
        );

        // Then
        expect(result, isNull);
      });

      test('🔴 RED: crop 지원이고 croppedPath가 있으면 croppedPath를 반환한다', () {
        // Given: 크롭 지원, 사용자가 크롭 완료
        const pickedPath = '/original.png';
        const croppedPath = '/cropped.png';
        const cropSupported = true;

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: pickedPath,
          croppedPath: croppedPath,
          cropSupported: cropSupported,
        );

        // Then: 크롭된 경로 사용
        expect(result, croppedPath);
      });

      test('🔴 RED: crop 지원이지만 croppedPath가 null이면 null을 반환한다 (취소 시 업로드 안 함)', () {
        // Given: 크롭 지원, 사용자가 크롭 취소
        const pickedPath = '/original.png';
        const cropSupported = true;

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: pickedPath,
          croppedPath: null,
          cropSupported: cropSupported,
        );

        // Then: null이면 호출자가 업로드하지 않음
        expect(result, isNull);
      });

      test('🔴 RED: crop 지원이지만 croppedPath가 비어있으면 null을 반환한다', () {
        // Given
        const pickedPath = '/original.png';
        const cropSupported = true;

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: pickedPath,
          croppedPath: '',
          cropSupported: cropSupported,
        );

        // Then
        expect(result, isNull);
      });

      test('🔴 RED: crop 미지원이면 croppedPath 무시하고 pickedPath를 반환한다', () {
        // Given: Web/데스크톱 등 크롭 미지원
        const pickedPath = '/original.png';
        const croppedPath = '/cropped.png';
        const cropSupported = false;

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: pickedPath,
          croppedPath: croppedPath,
          cropSupported: cropSupported,
        );

        // Then: 항상 pickedPath
        expect(result, pickedPath);
      });

      test('🔴 RED: crop 미지원이고 pickedPath만 있으면 pickedPath를 반환한다', () {
        // Given
        const pickedPath = '/original.png';
        const cropSupported = false;

        // When
        final result = ImageUploadPathResolver.resolveUploadPath(
          pickedPath: pickedPath,
          croppedPath: null,
          cropSupported: cropSupported,
        );

        // Then
        expect(result, pickedPath);
      });
    });
  });
}
