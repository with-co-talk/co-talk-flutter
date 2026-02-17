import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/data/datasources/remote/link_preview_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/link_preview_model.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late LinkPreviewRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = LinkPreviewRemoteDataSourceImpl(mockDioClient);
  });

  group('LinkPreviewRemoteDataSource', () {
    group('getLinkPreview', () {
      const testUrl = 'https://example.com/article';

      test('returns LinkPreviewModel when request succeeds with full data', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'url': testUrl,
                'title': 'Example Article',
                'description': 'This is an example article description',
                'imageUrl': 'https://example.com/image.jpg',
                'domain': 'example.com',
                'siteName': 'Example Site',
                'favicon': 'https://example.com/favicon.ico',
              },
              statusCode: 200,
            ));

        final result = await dataSource.getLinkPreview(testUrl);

        expect(result, isA<LinkPreviewModel>());
        expect(result.url, testUrl);
        expect(result.title, 'Example Article');
        expect(result.description, 'This is an example article description');
        expect(result.imageUrl, 'https://example.com/image.jpg');
        expect(result.domain, 'example.com');
        expect(result.siteName, 'Example Site');
        expect(result.favicon, 'https://example.com/favicon.ico');

        verify(() => mockDio.get(
              '/api/v1/link-preview',
              queryParameters: {'url': testUrl},
            )).called(1);
      });

      test('returns LinkPreviewModel with minimal data when optional fields are null', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'url': testUrl,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getLinkPreview(testUrl);

        expect(result, isA<LinkPreviewModel>());
        expect(result.url, testUrl);
        expect(result.title, isNull);
        expect(result.description, isNull);
        expect(result.imageUrl, isNull);
        expect(result.domain, isNull);
        expect(result.siteName, isNull);
        expect(result.favicon, isNull);
      });

      test('throws Exception with specific message when request fails with 400', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'error': 'Invalid URL'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getLinkPreview(testUrl),
          throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('유효하지 않은 URL입니다.')
          )),
        );
      });

      test('throws Exception with generic message when request fails with 404', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getLinkPreview(testUrl),
          throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('링크 미리보기를 불러올 수 없습니다.')
          )),
        );
      });

      test('throws Exception with generic message when request fails with 500', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getLinkPreview(testUrl),
          throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('링크 미리보기를 불러올 수 없습니다.')
          )),
        );
      });

      test('throws Exception when connection timeout occurs', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.getLinkPreview(testUrl),
          throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('링크 미리보기를 불러올 수 없습니다.')
          )),
        );
      });

      test('throws Exception when network error occurs', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getLinkPreview(testUrl),
          throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('링크 미리보기를 불러올 수 없습니다.')
          )),
        );
      });

      test('verifies correct query parameters are passed', () async {
        const anotherUrl = 'https://another-example.com';

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'url': anotherUrl},
              statusCode: 200,
            ));

        await dataSource.getLinkPreview(anotherUrl);

        verify(() => mockDio.get(
              '/api/v1/link-preview',
              queryParameters: {'url': anotherUrl},
            )).called(1);
      });
    });
  });
}
