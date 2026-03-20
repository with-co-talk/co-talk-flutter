import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/file_mime_resolver.dart';

void main() {
  group('FileMimeResolver', () {
    group('resolveFromBytes - magic byte detection', () {
      test('detects PNG by magic bytes', () {
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        final bytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/png');
      });

      test('detects JPEG by magic bytes', () {
        // JPEG signature: FF D8 FF
        final bytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/jpeg');
      });

      test('detects GIF87a by magic bytes', () {
        // GIF87a: 47 49 46 38 37 61
        final bytes = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61, 0x00, 0x00];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/gif');
      });

      test('detects GIF89a by magic bytes', () {
        // GIF89a: 47 49 46 38 39 61
        final bytes = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/gif');
      });

      test('detects PDF by magic bytes', () {
        // %PDF: 25 50 44 46
        final bytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'application/pdf');
      });

      test('detects WebP by RIFF/WEBP signature', () {
        // RIFF....WEBP: first 4 = RIFF, bytes 8-11 = WEBP
        final bytes = [
          0x52, 0x49, 0x46, 0x46, // RIFF
          0x24, 0x00, 0x00, 0x00, // file size (arbitrary)
          0x57, 0x45, 0x42, 0x50, // WEBP
          0x56, 0x50, 0x38, 0x4C, // VP8L (extra data)
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/webp');
      });

      test('detects HEIC by ftyp brand heic', () {
        final bytes = [
          0x00, 0x00, 0x00, 0x18, // box size
          0x66, 0x74, 0x79, 0x70, // 'ftyp'
          0x68, 0x65, 0x69, 0x63, // 'heic' brand
          0x00, 0x00, 0x00, 0x00,
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/heic');
      });

      test('detects HEIC by ftyp brand heix', () {
        final bytes = [
          0x00, 0x00, 0x00, 0x18,
          0x66, 0x74, 0x79, 0x70, // 'ftyp'
          0x68, 0x65, 0x69, 0x78, // 'heix' brand
          0x00, 0x00, 0x00, 0x00,
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/heic');
      });

      test('detects HEIC by ftyp brand mif1', () {
        final bytes = [
          0x00, 0x00, 0x00, 0x18,
          0x66, 0x74, 0x79, 0x70, // 'ftyp'
          0x6D, 0x69, 0x66, 0x31, // 'mif1' brand
          0x00, 0x00, 0x00, 0x00,
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/heic');
      });

      test('detects HEIC by ftyp brand msf1', () {
        final bytes = [
          0x00, 0x00, 0x00, 0x18,
          0x66, 0x74, 0x79, 0x70, // 'ftyp'
          0x6D, 0x73, 0x66, 0x31, // 'msf1' brand
          0x00, 0x00, 0x00, 0x00,
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'image/heic');
      });

      test('detects MP4 by ftyp with non-HEIC brand', () {
        final bytes = [
          0x00, 0x00, 0x00, 0x18,
          0x66, 0x74, 0x79, 0x70, // 'ftyp'
          0x69, 0x73, 0x6F, 0x6D, // 'isom' brand (MP4)
          0x00, 0x00, 0x00, 0x00,
        ];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'video/mp4');
      });
    });

    group('resolveFromBytes - extension fallback', () {
      test('falls back to extension when magic bytes are unknown', () {
        final bytes = [0x00, 0x01, 0x02, 0x03]; // unrecognized
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.png'), 'image/png');
      });

      test('falls back to jpg extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.jpg'), 'image/jpeg');
      });

      test('falls back to jpeg extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.jpeg'), 'image/jpeg');
      });

      test('falls back to gif extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'animation.gif'), 'image/gif');
      });

      test('falls back to webp extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'image.webp'), 'image/webp');
      });

      test('falls back to bmp extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'image.bmp'), 'image/bmp');
      });

      test('falls back to heic extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.heic'), 'image/heic');
      });

      test('falls back to heif extension (maps to image/heic)', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.heif'), 'image/heic');
      });

      test('falls back to pdf extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'document.pdf'), 'application/pdf');
      });

      test('falls back to mp4 extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'video.mp4'), 'video/mp4');
      });

      test('falls back to mov extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'video.mov'), 'video/quicktime');
      });

      test('extension matching is case-insensitive', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.PNG'), 'image/png');
        expect(FileMimeResolver.resolveFromBytes(bytes, 'photo.JPG'), 'image/jpeg');
      });
    });

    group('resolveFromBytes - unknown file handling', () {
      test('returns application/octet-stream for empty bytes and no path', () {
        expect(FileMimeResolver.resolveFromBytes([]), 'application/octet-stream');
      });

      test('returns application/octet-stream for empty bytes with null path', () {
        expect(FileMimeResolver.resolveFromBytes([], null), 'application/octet-stream');
      });

      test('returns extension mime for empty bytes with known extension', () {
        expect(FileMimeResolver.resolveFromBytes([], 'photo.png'), 'image/png');
      });

      test('returns application/octet-stream for unknown magic bytes and no path', () {
        final bytes = [0x00, 0x01, 0x02, 0x03, 0x04];
        expect(FileMimeResolver.resolveFromBytes(bytes), 'application/octet-stream');
      });

      test('returns application/octet-stream for unknown extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'file.xyz'), 'application/octet-stream');
      });

      test('returns application/octet-stream for path with no extension', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, 'noextension'), 'application/octet-stream');
      });

      test('returns application/octet-stream for empty path', () {
        final bytes = [0x00, 0x01, 0x02, 0x03];
        expect(FileMimeResolver.resolveFromBytes(bytes, ''), 'application/octet-stream');
      });
    });

    group('resolveFromFile', () {
      test('returns application/octet-stream for non-existent file', () async {
        final file = File('/tmp/nonexistent_file_that_does_not_exist_12345.bin');
        final mime = await FileMimeResolver.resolveFromFile(file);
        expect(mime, 'application/octet-stream');
      });

      test('resolves MIME from actual PNG file bytes', () async {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/test_png_${DateTime.now().millisecondsSinceEpoch}.png');
        // Write PNG magic bytes
        await file.writeAsBytes([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        ]);
        try {
          final mime = await FileMimeResolver.resolveFromFile(file);
          expect(mime, 'image/png');
        } finally {
          await file.delete();
        }
      });

      test('resolves MIME from actual JPEG file bytes', () async {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/test_jpg_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
        try {
          final mime = await FileMimeResolver.resolveFromFile(file);
          expect(mime, 'image/jpeg');
        } finally {
          await file.delete();
        }
      });

      test('falls back to extension for file with unrecognized bytes', () async {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/test_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await file.writeAsBytes([0x00, 0x01, 0x02, 0x03]);
        try {
          final mime = await FileMimeResolver.resolveFromFile(file);
          expect(mime, 'video/mp4');
        } finally {
          await file.delete();
        }
      });
    });

    group('magic byte priority over extension', () {
      test('PNG bytes win over .jpg extension', () {
        final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00];
        // Even though path says .jpg, magic bytes say PNG
        expect(FileMimeResolver.resolveFromBytes(pngBytes, 'disguised.jpg'), 'image/png');
      });

      test('JPEG bytes win over .png extension', () {
        final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
        expect(FileMimeResolver.resolveFromBytes(jpegBytes, 'disguised.png'), 'image/jpeg');
      });
    });
  });
}
