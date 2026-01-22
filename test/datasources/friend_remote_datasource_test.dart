import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/friend_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late FriendRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = FriendRemoteDataSourceImpl(mockDioClient);
  });

  group('FriendRemoteDataSource', () {
    group('getFriends', () {
      test('returns list of FriendModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'friends': [
                  {
                    'id': 1,
                    'user': {
                      'id': 2,
                      'email': 'friend@test.com',
                      'nickname': 'Friend',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    },
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getFriends(1);

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.user.nickname, 'Friend');
      });

      test('throws ServerException when fails', () async {
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
          () => dataSource.getFriends(1),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException when network error', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getFriends(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('sendFriendRequest', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 201,
            ));

        await expectLater(
          dataSource.sendFriendRequest(1, 2),
          completes,
        );
      });

      test('throws ConflictException when already friends', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 409,
            data: {'message': 'Already friends'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.sendFriendRequest(1, 2),
          throwsA(isA<ConflictException>()),
        );
      });
    });

    group('acceptFriendRequest', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.acceptFriendRequest(1, 1),
          completes,
        );
      });

      test('throws ServerException when request not found', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Request not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.acceptFriendRequest(999, 1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('rejectFriendRequest', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.rejectFriendRequest(1, 1),
          completes,
        );
      });
    });

    group('removeFriend', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 204,
            ));

        await expectLater(
          dataSource.removeFriend(1, 2),
          completes,
        );
      });

      test('throws ServerException when friend not found', () async {
        when(() => mockDioClient.delete(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Friend not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.removeFriend(1, 999),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('searchUsers', () {
      test('returns list of UserModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'users': [
                  {
                    'id': 1,
                    'email': 'user@test.com',
                    'nickname': 'TestUser',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.searchUsers('test');

        expect(result.length, 1);
        expect(result.first.nickname, 'TestUser');
      });

      test('returns list of UserModel from root array', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: [
                {
                  'id': 1,
                  'email': 'user@test.com',
                  'nickname': 'TestUser',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                }
              ],
              statusCode: 200,
            ));

        final result = await dataSource.searchUsers('test');

        expect(result.length, 1);
      });

      test('returns empty list when no results', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'users': []},
              statusCode: 200,
            ));

        final result = await dataSource.searchUsers('nonexistent');

        expect(result, isEmpty);
      });
    });

    group('getReceivedFriendRequests', () {
      test('returns list of FriendRequestModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'requests': [
                  {
                    'id': 1,
                    'requester': {
                      'id': 2,
                      'email': 'requester@test.com',
                      'nickname': 'Requester',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    },
                    'receiver': {
                      'id': 1,
                      'email': 'receiver@test.com',
                      'nickname': 'Receiver',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    },
                    'status': 'PENDING',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getReceivedFriendRequests(1);

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.requester.nickname, 'Requester');
        expect(result.first.receiver.nickname, 'Receiver');
      });

      test('throws ServerException when fails', () async {
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
          () => dataSource.getReceivedFriendRequests(1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getSentFriendRequests', () {
      test('returns list of FriendRequestModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'requests': [
                  {
                    'id': 1,
                    'requester': {
                      'id': 1,
                      'email': 'requester@test.com',
                      'nickname': 'Requester',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    },
                    'receiver': {
                      'id': 2,
                      'email': 'receiver@test.com',
                      'nickname': 'Receiver',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    },
                    'status': 'PENDING',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getSentFriendRequests(1);

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.requester.nickname, 'Requester');
        expect(result.first.receiver.nickname, 'Receiver');
      });

      test('throws ServerException when fails', () async {
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
          () => dataSource.getSentFriendRequests(1),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
