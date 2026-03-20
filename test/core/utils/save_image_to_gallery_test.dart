import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/src/gal_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/utils/save_image_to_gallery.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

/// A fake GalPlatform that replaces the real implementation in tests.
/// GalPlatform is a base class so FakeGalPlatform must also be base.
base class FakeGalPlatform extends GalPlatform {
  bool hasAccessResult = true;
  bool requestAccessResult = true;
  bool putImageBytesCalled = false;
  Uint8List? lastBytes;

  @override
  Future<bool> hasAccess({bool toAlbum = false}) async => hasAccessResult;

  @override
  Future<bool> requestAccess({bool toAlbum = false}) async =>
      requestAccessResult;

  @override
  Future<void> putImageBytes(Uint8List bytes,
      {String? album, required String name}) async {
    putImageBytesCalled = true;
    lastBytes = bytes;
  }
}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late FakeGalPlatform fakeGal;
  final getIt = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    fakeGal = FakeGalPlatform();

    when(() => mockDioClient.dio).thenReturn(mockDio);

    if (getIt.isRegistered<DioClient>()) {
      getIt.unregister<DioClient>();
    }
    getIt.registerLazySingleton<DioClient>(() => mockDioClient);

    // Replace the real Gal platform with our fake.
    GalPlatform.instance = fakeGal;
  });

  tearDown(() {
    if (getIt.isRegistered<DioClient>()) {
      getIt.unregister<DioClient>();
    }
  });

  group('saveImageFromUrlToGallery', () {
    test('saves image successfully when access is already granted', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      fakeGal.hasAccessResult = true;

      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        ),
      );

      await saveImageFromUrlToGallery('https://example.com/img.jpg');

      expect(fakeGal.putImageBytesCalled, isTrue);
      expect(fakeGal.lastBytes, equals(imageBytes));
    });

    test('resolves relative URL by prepending base URL', () async {
      final imageBytes = Uint8List.fromList([10, 20, 30]);
      fakeGal.hasAccessResult = true;

      String? capturedUrl;
      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedUrl = invocation.positionalArguments[0] as String;
        return Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: capturedUrl ?? ''),
        );
      });

      await saveImageFromUrlToGallery('/api/v1/files/test.jpg');

      // The resolved URL must start with http (base URL prepended)
      expect(capturedUrl, isNotNull);
      expect(capturedUrl!.startsWith('http'), isTrue);
      expect(capturedUrl!.endsWith('/api/v1/files/test.jpg'), isTrue);
    });

    test('keeps absolute URL unchanged', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3]);
      fakeGal.hasAccessResult = true;
      const absoluteUrl = 'https://cdn.example.com/photo.png';

      String? capturedUrl;
      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedUrl = invocation.positionalArguments[0] as String;
        return Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: capturedUrl ?? ''),
        );
      });

      await saveImageFromUrlToGallery(absoluteUrl);

      expect(capturedUrl, equals(absoluteUrl));
    });

    test('requests access when hasAccess returns false, then saves', () async {
      final imageBytes = Uint8List.fromList([7, 8, 9]);
      fakeGal.hasAccessResult = false;
      fakeGal.requestAccessResult = true;

      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        ),
      );

      await saveImageFromUrlToGallery('https://example.com/img.jpg');

      expect(fakeGal.putImageBytesCalled, isTrue);
    });

    test('throws Exception when access is denied', () async {
      final imageBytes = Uint8List.fromList([7, 8, 9]);
      fakeGal.hasAccessResult = false;
      fakeGal.requestAccessResult = false;

      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        ),
      );

      expect(
        () => saveImageFromUrlToGallery('https://example.com/img.jpg'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('권한'),
        )),
      );
    });

    test('throws Exception when response data is null', () async {
      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<List<int>>(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        ),
      );

      expect(
        () => saveImageFromUrlToGallery('https://example.com/img.jpg'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('이미지 데이터'),
        )),
      );
    });

    test('throws Exception when response data is empty', () async {
      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<List<int>>(
          data: <int>[],
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        ),
      );

      expect(
        () => saveImageFromUrlToGallery('https://example.com/img.jpg'),
        throwsA(isA<Exception>()),
      );
    });

    test('uses bytes responseType option for download', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3]);
      fakeGal.hasAccessResult = true;

      Options? capturedOptions;
      when(() => mockDio.get<List<int>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedOptions =
            invocation.namedArguments[const Symbol('options')] as Options?;
        return Response<List<int>>(
          data: imageBytes.toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://example.com/img.jpg'),
        );
      });

      await saveImageFromUrlToGallery('https://example.com/img.jpg');

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.responseType, equals(ResponseType.bytes));
    });
  });
}
