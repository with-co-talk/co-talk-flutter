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
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
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

        final result = await dataSource.getFriends();

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.user.nickname, 'Friend');
      });

      test('throws ServerException when fails', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getFriends(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException when network error', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getFriends(),
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
          dataSource.sendFriendRequest(2),
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
          () => dataSource.sendFriendRequest(2),
          throwsA(isA<ConflictException>()),
        );
      });
    });

    group('acceptFriendRequest', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.acceptFriendRequest(1),
          completes,
        );
      });

      test('throws ServerException when request not found', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Request not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.acceptFriendRequest(999),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('rejectFriendRequest', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.rejectFriendRequest(1),
          completes,
        );
      });
    });

    group('removeFriend', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 204,
            ));

        await expectLater(
          dataSource.removeFriend(2),
          completes,
        );
      });

      test('throws ServerException when friend not found', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Friend not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.removeFriend(999),
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
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
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

        final result = await dataSource.getReceivedFriendRequests();

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.requester.nickname, 'Requester');
        expect(result.first.receiver.nickname, 'Receiver');
      });

      test('throws ServerException when fails', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getReceivedFriendRequests(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getSentFriendRequests', () {
      test('returns list of FriendRequestModel when succeeds', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
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

        final result = await dataSource.getSentFriendRequests();

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.requester.nickname, 'Requester');
        expect(result.first.receiver.nickname, 'Receiver');
      });

      test('throws ServerException when fails', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getSentFriendRequests(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getSentFriendRequests(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getFriends with flat structure', () {
      test('parses flat friend response with nickname field', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'friends': [
                  {
                    'id': 5,
                    'nickname': 'FlatFriend',
                    'email': 'flat@test.com',
                    'avatarUrl': 'https://example.com/avatar.jpg',
                    'onlineStatus': 'ONLINE',
                    'lastActiveAt': '2024-01-01T00:00:00.000Z',
                    'isHidden': false,
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getFriends();

        expect(result.length, 1);
        expect(result.first.user.nickname, 'FlatFriend');
        expect(result.first.isHidden, false);
      });

      test('returns empty list when friends key is empty', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'friends': []},
              statusCode: 200,
            ));

        final result = await dataSource.getFriends();

        expect(result, isEmpty);
      });
    });

    group('rejectFriendRequest', () {
      test('throws ServerException on 404', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Request not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.rejectFriendRequest(999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on connection timeout', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.rejectFriendRequest(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('hideFriend', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.hideFriend(2),
          completes,
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Friend not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.hideFriend(999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on send timeout', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.sendTimeout,
        ));

        expect(
          () => dataSource.hideFriend(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('unhideFriend', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.unhideFriend(2),
          completes,
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Friend not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.unhideFriend(999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.unhideFriend(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getHiddenFriends', () {
      test('returns list from HiddenFriendDto with friendId structure', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'friends': [
                  {
                    'id': 10,
                    'friendId': 20,
                    'nickname': 'HiddenUser',
                    'profileImageUrl': 'https://example.com/hidden.jpg',
                    'hiddenAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getHiddenFriends();

        expect(result.length, 1);
        expect(result.first.user.nickname, 'HiddenUser');
        expect(result.first.isHidden, true);
        expect(result.first.user.avatarUrl, 'https://example.com/hidden.jpg');
      });

      test('returns list from flat structure with nickname field', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'friends': [
                  {
                    'id': 15,
                    'nickname': 'FlatHidden',
                    'email': 'flathidden@test.com',
                    'avatarUrl': 'https://example.com/img.jpg',
                    'onlineStatus': 'OFFLINE',
                    'lastActiveAt': '2024-01-01T00:00:00.000Z',
                    'isHidden': true,
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getHiddenFriends();

        expect(result.length, 1);
        expect(result.first.user.nickname, 'FlatHidden');
        expect(result.first.isHidden, true);
      });

      test('returns list from nested structure', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'friends': [
                  {
                    'id': 30,
                    'user': {
                      'id': 31,
                      'email': 'nested@test.com',
                      'nickname': 'NestedHidden',
                    },
                    'createdAt': '2024-01-01T00:00:00.000Z',
                    'isHidden': true,
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getHiddenFriends();

        expect(result.length, 1);
        expect(result.first.user.nickname, 'NestedHidden');
      });

      test('returns empty list when no hidden friends', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'friends': []},
              statusCode: 200,
            ));

        final result = await dataSource.getHiddenFriends();

        expect(result, isEmpty);
      });

      test('throws ServerException on 500', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getHiddenFriends(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on receive timeout', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.getHiddenFriends(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('blockUser', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 201,
            ));

        await expectLater(
          dataSource.blockUser(5),
          completes,
        );
      });

      test('throws ConflictException when already blocked', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 409,
            data: {'message': 'Already blocked'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.blockUser(5),
          throwsA(isA<ConflictException>()),
        );
      });

      test('throws AuthException on 401', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.blockUser(5),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.blockUser(5),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('unblockUser', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.unblockUser(5),
          completes,
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Block not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.unblockUser(999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on send timeout', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.sendTimeout,
        ));

        expect(
          () => dataSource.unblockUser(5),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getBlockedUsers', () {
      test('returns list of UserModel when succeeds', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'blockedUsers': [
                  {
                    'id': 10,
                    'nickname': 'BlockedUser',
                    'avatarUrl': 'https://example.com/avatar.jpg',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getBlockedUsers();

        expect(result.length, 1);
        expect(result.first.id, 10);
        expect(result.first.nickname, 'BlockedUser');
        expect(result.first.email, '');
      });

      test('returns empty list when no blocked users', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'blockedUsers': []},
              statusCode: 200,
            ));

        final result = await dataSource.getBlockedUsers();

        expect(result, isEmpty);
      });

      test('handles missing avatarUrl gracefully', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'blockedUsers': [
                  {
                    'id': 11,
                    'nickname': 'NoAvatar',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getBlockedUsers();

        expect(result.length, 1);
        expect(result.first.avatarUrl, isNull);
        expect(result.first.nickname, 'NoAvatar');
      });

      test('throws ServerException on 500', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Server error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getBlockedUsers(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 401', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getBlockedUsers(),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on connection timeout', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.getBlockedUsers(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('searchUsers', () {
      test('throws AuthException on 401', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.searchUsers('test'),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on receive timeout', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.searchUsers('test'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getReceivedFriendRequests', () {
      test('returns empty list when no requests', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'requests': []},
              statusCode: 200,
            ));

        final result = await dataSource.getReceivedFriendRequests();

        expect(result, isEmpty);
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getReceivedFriendRequests(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('acceptFriendRequest', () {
      test('throws NetworkException on connection timeout', () async {
        when(() => mockDioClient.post(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.acceptFriendRequest(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('removeFriend', () {
      test('throws NetworkException on receive timeout', () async {
        when(() => mockDioClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.removeFriend(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
