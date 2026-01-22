import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late ChatRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = ChatRemoteDataSourceImpl(mockDioClient);
  });

  group('ChatRemoteDataSource', () {
    group('getChatRooms', () {
      test('returns list of ChatRoomModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'rooms': [
                  {
                    'id': 1,
                    'name': 'Test Room',
                    'type': 'DIRECT',
                    'unreadCount': 0,
                    'createdAt': '2024-01-01T00:00:00.000Z',
                    'lastMessage': '안녕하세요',
                    'lastMessageAt': '2024-01-01T10:30:00.000Z',
                    'otherUserId': 2,
                    'otherUserNickname': 'User2',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getChatRooms(1);

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.name, 'Test Room');
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
          () => dataSource.getChatRooms(1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createDirectChatRoom', () {
      test('returns ChatRoomModel when succeeds with roomId response', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'roomId': 1,
                'message': '채팅방이 생성되었습니다.',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createDirectChatRoom(1, 2);

        expect(result.id, 1);
        expect(result.type, 'DIRECT');
      });
    });

    group('createGroupChatRoom', () {
      test('returns ChatRoomModel when succeeds with roomId response', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'roomId': 2,
                'message': '그룹 채팅방이 생성되었습니다.',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createGroupChatRoom(1, 'Group Chat', [2, 3]);

        expect(result.id, 2);
        expect(result.name, 'Group Chat');
        expect(result.type, 'GROUP');
      });
    });

    group('leaveChatRoom', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.leaveChatRoom(1, 1),
          completes,
        );
      });
    });

    group('markAsRead', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.markAsRead(1, 1),
          completes,
        );
      });
    });

    group('getMessages', () {
      test('returns MessageHistoryResponse when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messages': [
                  {
                    'id': 1,
                    'chatRoomId': 1,
                    'senderId': 1,
                    'senderNickname': 'User1',
                    'content': 'Hello',
                    'type': 'text',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ],
                'hasMore': false,
                'nextCursor': null,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getMessages(1, 1);

        expect(result.messages.length, 1);
        expect(result.hasMore, false);
      });

      test('supports pagination with cursor', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messages': [],
                'hasMore': false,
                'nextCursor': null,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getMessages(1, 1, size: 20, beforeMessageId: 100);

        expect(result.messages, isEmpty);
      });
    });

    group('sendMessage', () {
      test('returns MessageModel when succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'chatRoomId': 1,
                'senderId': 1,
                'senderNickname': 'User1',
                'content': 'Hello',
                'type': 'text',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 1, senderId: 1, content: 'Hello'),
        );

        expect(result.id, 1);
        expect(result.content, 'Hello');
      });

      test('handles server response with array date format', () async {
        // 실제 서버가 반환하는 형식: messageId, type, createdAt as array
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 123,
                'content': 'Test Message',
                'type': 'TEXT',
                'createdAt': [2026, 1, 22, 3, 4, 10, 946596000],
                'isDeleted': false,
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 1, senderId: 1, content: 'Test Message'),
        );

        expect(result.id, 123);
        expect(result.content, 'Test Message');
        expect(result.chatRoomId, 1);
        expect(result.senderId, 1);
        expect(result.createdAt, isA<DateTime>());
        expect(result.createdAt.year, 2026);
        expect(result.createdAt.month, 1);
        expect(result.createdAt.day, 22);
      });

      test('handles server response with minimal roomId format', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 456,
                'content': 'Another Message',
                'type': 'TEXT',
                'createdAt': [2026, 1, 22, 10, 30, 45, 0],
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 2, senderId: 3, content: 'Another Message'),
        );

        expect(result.id, 456);
        expect(result.chatRoomId, 2); // from request
        expect(result.senderId, 3); // from request
      });
    });

    group('updateMessage', () {
      test('returns updated MessageModel when succeeds', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 1,
                'chatRoomId': 1,
                'senderId': 1,
                'senderNickname': 'User1',
                'content': 'Updated',
                'type': 'text',
                'createdAt': '2024-01-01T00:00:00.000Z',
                'updatedAt': '2024-01-01T01:00:00.000Z',
              },
              statusCode: 200,
            ));

        final result = await dataSource.updateMessage(1, 1, 'Updated');

        expect(result.content, 'Updated');
      });
    });

    group('deleteMessage', () {
      test('completes successfully', () async {
        when(() => mockDioClient.delete(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 204,
            ));

        await expectLater(
          dataSource.deleteMessage(1, 1),
          completes,
        );
      });
    });

    // Error handling tests
    group('error handling', () {
      test('getChatRooms throws NetworkException on network error', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getChatRooms(1),
          throwsA(isA<NetworkException>()),
        );
      });

      test('createDirectChatRoom throws ValidationException on bad request', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'message': 'Bad request'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.createDirectChatRoom(1, 2),
          throwsA(isA<ValidationException>()),
        );
      });

      test('createGroupChatRoom throws ServerException on error', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'error': 'Internal error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.createGroupChatRoom(1, 'Group', [2]),
          throwsA(isA<ServerException>()),
        );
      });

      test('leaveChatRoom throws NetworkException on network error', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.leaveChatRoom(1, 1),
          throwsA(isA<NetworkException>()),
        );
      });

      test('markAsRead throws NetworkException on network error', () async {
        when(() => mockDioClient.post(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.markAsRead(1, 1),
          throwsA(isA<NetworkException>()),
        );
      });

      test('getMessages throws AuthException on forbidden', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
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
          () => dataSource.getMessages(1, 1),
          throwsA(isA<AuthException>()),
        );
      });

      test('sendMessage throws ValidationException on validation error', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 422,
            data: {'error': 'Validation error'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.sendMessage(
            const SendMessageRequest(chatRoomId: 1, senderId: 1, content: 'Hi'),
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('updateMessage throws ServerException on error', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
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
          () => dataSource.updateMessage(1, 1, 'Updated'),
          throwsA(isA<ServerException>()),
        );
      });

      test('deleteMessage throws NetworkException on network error', () async {
        when(() => mockDioClient.delete(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.sendTimeout,
        ));

        expect(
          () => dataSource.deleteMessage(1, 1),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
