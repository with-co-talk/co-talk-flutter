import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/profile_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = ProfileRemoteDataSourceImpl(mockDioClient);
  });

  group('ProfileRemoteDataSource', () {
    group('getProfileHistory', () {
      test('returns list when successful', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'histories': [
                  {
                    'id': 1,
                    'userId': 100,
                    'type': 'AVATAR',
                    'url': 'https://example.com/avatar.jpg',
                    'isPrivate': false,
                    'isCurrent': true,
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  },
                  {
                    'id': 2,
                    'userId': 100,
                    'type': 'STATUS_MESSAGE',
                    'content': 'Hello',
                    'isPrivate': false,
                    'isCurrent': true,
                    'createdAt': '2024-01-02T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getProfileHistory(100);

        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].type, 'AVATAR');
        expect(result[1].id, 2);
        expect(result[1].type, 'STATUS_MESSAGE');
      });

      test('returns empty list when no histories', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'histories': []},
              statusCode: 200,
            ));

        final result = await dataSource.getProfileHistory(100);

        expect(result, isEmpty);
      });

      test('returns empty list when response has empty histories', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'histories': [],
                'total': 0,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getProfileHistory(100);

        expect(result, isEmpty);
      });

      test('filters by type when type provided', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: {'type': 'AVATAR'},
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'histories': [
                  {
                    'id': 1,
                    'userId': 100,
                    'type': 'AVATAR',
                    'url': 'https://example.com/avatar.jpg',
                    'isPrivate': false,
                    'isCurrent': true,
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getProfileHistory(100, type: 'AVATAR');

        expect(result.length, 1);
        expect(result[0].type, 'AVATAR');
        verify(() => mockDioClient.get(
              any(),
              queryParameters: {'type': 'AVATAR'},
            )).called(1);
      });

      test('throws ServerException on 500 error', () async {
        when(() => mockDioClient.get(
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
          () => dataSource.getProfileHistory(100),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on timeout', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.getProfileHistory(100),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('createProfileHistory', () {
      test('returns created history when successful', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'userId': 100,
                'type': 'AVATAR',
                'url': 'https://example.com/avatar.jpg',
                'isPrivate': false,
                'isCurrent': true,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createProfileHistory(
          userId: 100,
          type: 'AVATAR',
          url: 'https://example.com/avatar.jpg',
        );

        expect(result.id, 1);
        expect(result.type, 'AVATAR');
        expect(result.url, 'https://example.com/avatar.jpg');
        expect(result.isCurrent, true);
      });

      test('sends correct data with all parameters', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'userId': 100,
                'type': 'STATUS_MESSAGE',
                'content': 'Hello world',
                'isPrivate': true,
                'isCurrent': false,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        await dataSource.createProfileHistory(
          userId: 100,
          type: 'STATUS_MESSAGE',
          content: 'Hello world',
          isPrivate: true,
          setCurrent: false,
        );

        verify(() => mockDioClient.post(
              any(),
              data: {
                'type': 'STATUS_MESSAGE',
                'content': 'Hello world',
                'isPrivate': true,
                'setCurrent': false,
              },
            )).called(1);
      });

      test('throws ValidationException on 400 error', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'error': 'Invalid data'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.createProfileHistory(
            userId: 100,
            type: 'AVATAR',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ServerException on 500 error', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
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
          () => dataSource.createProfileHistory(
            userId: 100,
            type: 'AVATAR',
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('updateProfileHistory', () {
      test('completes successfully', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.updateProfileHistory(100, 1, isPrivate: true),
          completes,
        );

        verify(() => mockDioClient.put(
              any(),
              data: {'isPrivate': true},
            )).called(1);
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'History not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.updateProfileHistory(100, 999, isPrivate: true),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 403', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
            data: {'error': 'Forbidden'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.updateProfileHistory(100, 1, isPrivate: true),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('deleteProfileHistory', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 204,
            ));

        await expectLater(
          dataSource.deleteProfileHistory(100, 1),
          completes,
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'History not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.deleteProfileHistory(100, 999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 403', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
            data: {'error': 'Forbidden'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.deleteProfileHistory(100, 1),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('setCurrentProfile', () {
      test('completes successfully', () async {
        when(() => mockDioClient.put(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.setCurrentProfile(100, 1),
          completes,
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.put(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'History not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.setCurrentProfile(100, 999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 403', () async {
        when(() => mockDioClient.put(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
            data: {'error': 'Forbidden'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.setCurrentProfile(100, 1),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
