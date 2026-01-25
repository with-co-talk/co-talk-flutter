import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/base_remote_datasource.dart';

// Concrete implementation for testing
class TestRemoteDataSource extends BaseRemoteDataSource {
  Exception testHandleDioError(DioException e) {
    return handleDioError(e);
  }

  List<dynamic> testExtractListFromResponse(dynamic responseData, String key) {
    return extractListFromResponse(responseData, key);
  }
}

void main() {
  late TestRemoteDataSource dataSource;

  setUp(() {
    dataSource = TestRemoteDataSource();
  });

  group('BaseRemoteDataSource', () {
    group('handleDioError', () {
      group('HTTP error responses', () {
        test('returns ValidationException for 400 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {'message': 'Bad request'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ValidationException>());
          expect((result as ValidationException).message, 'Bad request');
        });

        test('returns AuthException for 401 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 401,
              data: {'message': 'Unauthorized'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<AuthException>());
          expect((result as AuthException).message, 'Unauthorized');
          expect(result.type, AuthErrorType.unauthorized);
        });

        test('returns AuthException for 403 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 403,
              data: {'message': 'Forbidden'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<AuthException>());
          expect((result as AuthException).message, 'Forbidden');
        });

        test('returns ServerException for 404 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 404,
              data: {'message': 'Not found'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ServerException>());
          expect((result as ServerException).message, 'Not found');
          expect(result.statusCode, 404);
        });

        test('returns ValidationException for 422 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 422,
              data: {'message': 'Validation failed'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ValidationException>());
          expect((result as ValidationException).message, 'Validation failed');
        });

        test('returns ServerException for 500 status', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'message': 'Internal server error'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ServerException>());
          expect((result as ServerException).message, 'Internal server error');
          expect(result.statusCode, 500);
        });

        test('extracts message from "error" field if "message" is not available', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'error': 'Error message'},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ServerException>());
          expect((result as ServerException).message, 'Error message');
        });

        test('uses "Unknown error" when no message is available', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {},
            ),
            type: DioExceptionType.badResponse,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<ServerException>());
          expect((result as ServerException).message, 'Unknown error');
        });
      });

      group('Network errors', () {
        test('returns NetworkException for connection timeout', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('연결 시간이 초과'));
        });

        test('returns NetworkException for send timeout', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.sendTimeout,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('전송 시간이 초과'));
        });

        test('returns NetworkException for receive timeout', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('수신 시간이 초과'));
        });

        test('returns NetworkException for connection error', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('연결에 실패'));
        });

        test('returns NetworkException for cancel', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('취소'));
        });

        test('returns NetworkException for unknown error type', () {
          final exception = DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.unknown,
          );

          final result = dataSource.testHandleDioError(exception);

          expect(result, isA<NetworkException>());
          expect((result as NetworkException).message, contains('네트워크 오류'));
        });
      });
    });

    group('extractListFromResponse', () {
      test('returns list when response is directly a List', () {
        final responseData = [1, 2, 3];
        final result = dataSource.testExtractListFromResponse(responseData, 'items');

        expect(result, [1, 2, 3]);
      });

      test('returns list from Map with specified key', () {
        final responseData = {
          'items': [1, 2, 3],
          'other': 'data',
        };
        final result = dataSource.testExtractListFromResponse(responseData, 'items');

        expect(result, [1, 2, 3]);
      });

      test('returns empty list when response is null', () {
        final result = dataSource.testExtractListFromResponse(null, 'items');

        expect(result, isEmpty);
      });

      test('returns empty list when key does not exist in Map', () {
        final responseData = {
          'other': 'data',
        };
        final result = dataSource.testExtractListFromResponse(responseData, 'items');

        expect(result, isEmpty);
      });

      test('returns empty list when value at key is not a List', () {
        final responseData = {
          'items': 'not a list',
        };
        final result = dataSource.testExtractListFromResponse(responseData, 'items');

        expect(result, isEmpty);
      });

      test('returns empty list when response is neither List nor Map', () {
        final result = dataSource.testExtractListFromResponse('invalid', 'items');

        expect(result, isEmpty);
      });

      test('handles nested JSON structure', () {
        final responseData = {
          'data': {
            'items': [1, 2, 3],
          },
        };
        // extractListFromResponse는 한 단계만 검사하므로 'items'를 찾지 못함
        final result = dataSource.testExtractListFromResponse(responseData, 'items');

        expect(result, isEmpty);
      });

      test('works with real-world friend response format', () {
        final responseData = {
          'friends': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
          ],
        };
        final result = dataSource.testExtractListFromResponse(responseData, 'friends');

        expect(result.length, 2);
        expect(result[0]['name'], 'Alice');
      });

      test('works with root array format', () {
        final responseData = [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ];
        final result = dataSource.testExtractListFromResponse(responseData, 'users');

        expect(result.length, 2);
        expect(result[0]['name'], 'Alice');
      });
    });
  });
}
