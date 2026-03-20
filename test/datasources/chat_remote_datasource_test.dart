import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/errors/exceptions.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/data/models/media_gallery_model.dart';

class MockDioClient extends Mock implements DioClient {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockDioClient mockDioClient;
  late MockAuthLocalDataSource mockAuthLocalDataSource;
  late ChatRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    mockAuthLocalDataSource = MockAuthLocalDataSource();
    dataSource = ChatRemoteDataSourceImpl(mockDioClient, mockAuthLocalDataSource);

    // Default stub for getUserId
    when(() => mockAuthLocalDataSource.getUserId()).thenAnswer((_) async => 1);
  });

  group('ChatRemoteDataSource', () {
    group('getChatRooms', () {
      test('returns list of ChatRoomModel when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
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

        final result = await dataSource.getChatRooms();

        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.name, 'Test Room');
      });

      test('throws ServerException when fails', () async {
        when(() => mockDioClient.get(
              any(),
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
          () => dataSource.getChatRooms(),
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

        final result = await dataSource.createDirectChatRoom(2);

        expect(result.id, 1);
        expect(result.type, 'DIRECT');
      });

      test('includes only userId2 in request when creating chat room', () async {
        // Given: userId1 (current user) is extracted from JWT, only userId2 is sent
        Map<String, dynamic>? capturedData;
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>?;
          return Response(
            requestOptions: RequestOptions(path: ''),
            data: {
              'roomId': 1,
              'message': '채팅방이 생성되었습니다.',
            },
            statusCode: 201,
          );
        });

        // When: 채팅방 생성 요청
        await dataSource.createDirectChatRoom(2);

        // Then: 요청 데이터에 userId2만 포함되어야 함 (userId1은 JWT에서 추출)
        expect(capturedData, isNotNull, reason: 'Request data should be captured');
        expect(capturedData!['userId2'], equals(2), reason: 'userId2 should be 2');
        expect(capturedData!.containsKey('userId1'), isFalse, reason: 'userId1 should not be in request (extracted from JWT)');
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

        final result = await dataSource.createGroupChatRoom('Group Chat', [2, 3]);

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
          dataSource.leaveChatRoom(1),
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
          dataSource.markAsRead(1),
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

        final result = await dataSource.getMessages(1);

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

        final result = await dataSource.getMessages(1, size: 20, beforeMessageId: 100);

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
          const SendMessageRequest(chatRoomId: 1, content: 'Hello'),
        );

        expect(result.id, 1);
        expect(result.content, 'Hello');
      });

      test('handles server response with array date format', () async {
        // 실제 서버가 반환하는 형식: messageId, type, createdAt as array
        // senderId는 JWT에서 추출되어 서버 응답에 포함됨
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 123,
                'content': 'Test Message',
                'type': 'TEXT',
                'senderId': 1,
                'createdAt': [2026, 1, 22, 3, 4, 10, 946596000],
                'isDeleted': false,
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 1, content: 'Test Message'),
        );

        expect(result.id, 123);
        expect(result.content, 'Test Message');
        expect(result.chatRoomId, 1);
        expect(result.senderId, 1); // from server response (JWT extracted)
        expect(result.createdAt, isA<DateTime>());
        expect(result.createdAt.year, 2026);
        expect(result.createdAt.month, 1);
        expect(result.createdAt.day, 22);
      });

      test('handles server response with minimal roomId format', () async {
        // senderId는 JWT에서 추출되어 서버 응답에 포함됨
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 456,
                'content': 'Another Message',
                'type': 'TEXT',
                'senderId': 3,
                'createdAt': [2026, 1, 22, 10, 30, 45, 0],
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 2, content: 'Another Message'),
        );

        expect(result.id, 456);
        expect(result.chatRoomId, 2); // from request
        expect(result.senderId, 3); // from server response (JWT extracted)
      });
    });

    group('updateMessage', () {
      test('returns updated MessageModel when succeeds', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              // Backend returns UpdateMessageResponse(messageId, content, updatedAt)
              data: {
                'messageId': 1,
                'content': 'Updated',
                'updatedAt': '2024-01-01T01:00:00.000Z',
              },
              statusCode: 200,
            ));

        final result = await dataSource.updateMessage(1, 'Updated');

        expect(result.id, 1);
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
          dataSource.deleteMessage(1),
          completes,
        );
      });
    });

    group('getChatRoom', () {
      test('returns ChatRoomModel when response has data key', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'data': {
                  'id': 5,
                  'type': 'DIRECT',
                  'name': 'Room 5',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                }
              },
              statusCode: 200,
            ));

        final result = await dataSource.getChatRoom(5);

        expect(result.id, 5);
        expect(result.type, 'DIRECT');
      });

      test('returns ChatRoomModel when response has room key', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'room': {
                  'id': 6,
                  'type': 'GROUP',
                  'name': 'Room 6',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                }
              },
              statusCode: 200,
            ));

        final result = await dataSource.getChatRoom(6);

        expect(result.id, 6);
        expect(result.type, 'GROUP');
      });

      test('returns ChatRoomModel when response is flat', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 7,
                'type': 'DIRECT',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 200,
            ));

        final result = await dataSource.getChatRoom(7);

        expect(result.id, 7);
      });

      test('throws ServerException when response format is invalid', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'invalid',
              statusCode: 200,
            ));

        expect(
          () => dataSource.getChatRoom(1),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException on 404', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
            data: {'error': 'Not found'},
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dataSource.getChatRoom(999),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getChatRoom(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getChatRooms with fallback key', () {
      test('returns list when response uses chatRooms fallback key', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'chatRooms': [
                  {
                    'id': 10,
                    'type': 'DIRECT',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  }
                ]
              },
              statusCode: 200,
            ));

        final result = await dataSource.getChatRooms();

        expect(result.length, 1);
        expect(result.first.id, 10);
      });

      test('returns empty list when rooms key is empty', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'rooms': []},
              statusCode: 200,
            ));

        final result = await dataSource.getChatRooms();

        expect(result, isEmpty);
      });
    });

    group('createDirectChatRoom with full model response', () {
      test('returns ChatRoomModel from full response format', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 3,
                'type': 'DIRECT',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createDirectChatRoom(5);

        expect(result.id, 3);
        expect(result.type, 'DIRECT');
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'bad',
              statusCode: 201,
            ));

        expect(
          () => dataSource.createDirectChatRoom(2),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createGroupChatRoom', () {
      test('returns ChatRoomModel from full response format', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'id': 4,
                'name': 'Full Group',
                'type': 'GROUP',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createGroupChatRoom('Full Group', [2, 3]);

        expect(result.id, 4);
        expect(result.type, 'GROUP');
      });

      test('handles null name in response', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'roomId': 5,
                'message': 'created',
              },
              statusCode: 201,
            ));

        final result = await dataSource.createGroupChatRoom(null, [2, 3]);

        expect(result.id, 5);
        expect(result.name, isNull);
        expect(result.type, 'GROUP');
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 42,
              statusCode: 201,
            ));

        expect(
          () => dataSource.createGroupChatRoom('Group', [2]),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('reinviteUser', () {
      test('completes successfully', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.reinviteUser(1, 2),
          completes,
        );
      });

      test('throws AuthException on unauthorized', () async {
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
          () => dataSource.reinviteUser(1, 2),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on timeout', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.sendTimeout,
        ));

        expect(
          () => dataSource.reinviteUser(1, 2),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('sendFileMessage', () {
      test('returns MessageModel when succeeds with messageId format', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 10,
                'type': 'IMAGE',
                'fileUrl': 'https://example.com/image.jpg',
                'fileName': 'image.jpg',
                'fileSize': 1024,
                'senderId': 1,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final request = SendFileMessageRequest(
          chatRoomId: 1,
          fileUrl: 'https://example.com/image.jpg',
          fileName: 'image.jpg',
          fileSize: 1024,
          contentType: 'image/jpeg',
        );

        final result = await dataSource.sendFileMessage(request);

        expect(result.id, 10);
        expect(result.chatRoomId, 1);
        expect(result.fileUrl, 'https://example.com/image.jpg');
      });

      test('uses request fields as fallback when response lacks them', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 11,
                'type': 'FILE',
                'createdAt': [2026, 1, 22, 3, 4, 10, 0],
              },
              statusCode: 201,
            ));

        final request = SendFileMessageRequest(
          chatRoomId: 2,
          fileUrl: 'https://example.com/doc.pdf',
          fileName: 'doc.pdf',
          fileSize: 2048,
          contentType: 'application/pdf',
          thumbnailUrl: 'https://example.com/thumb.jpg',
        );

        final result = await dataSource.sendFileMessage(request);

        expect(result.id, 11);
        expect(result.chatRoomId, 2);
        expect(result.fileUrl, 'https://example.com/doc.pdf');
        expect(result.fileName, 'doc.pdf');
        expect(result.fileSize, 2048);
        expect(result.thumbnailUrl, 'https://example.com/thumb.jpg');
      });

      test('uses getUserId fallback for senderId', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 12,
                'type': 'FILE',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final request = SendFileMessageRequest(
          chatRoomId: 3,
          fileUrl: 'https://example.com/file.zip',
          fileName: 'file.zip',
          fileSize: 4096,
          contentType: 'application/zip',
        );

        final result = await dataSource.sendFileMessage(request);

        expect(result.senderId, 1);
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'invalid',
              statusCode: 201,
            ));

        final request = SendFileMessageRequest(
          chatRoomId: 1,
          fileUrl: 'https://example.com/file.zip',
          fileName: 'file.zip',
          fileSize: 512,
          contentType: 'application/zip',
        );

        expect(
          () => dataSource.sendFileMessage(request),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ValidationException on 400', () async {
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

        final request = SendFileMessageRequest(
          chatRoomId: 1,
          fileUrl: '',
          fileName: '',
          fileSize: 0,
          contentType: '',
        );

        expect(
          () => dataSource.sendFileMessage(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('getMediaGallery', () {
      test('returns MediaGalleryResponse when succeeds', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'items': [
                  {
                    'messageId': 1,
                    'type': 'IMAGE',
                    'fileUrl': 'https://example.com/img.jpg',
                    'createdAt': 1700000000000,
                    'senderId': 1,
                  }
                ],
                'hasMore': false,
                'nextCursor': null,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getMediaGallery(1, MediaType.photo);

        expect(result.items.length, 1);
        expect(result.hasMore, false);
        expect(result.items.first.type, 'IMAGE');
      });

      test('returns empty MediaGalleryResponse for file type', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'items': [],
                'hasMore': false,
                'nextCursor': null,
              },
              statusCode: 200,
            ));

        final result = await dataSource.getMediaGallery(
          1,
          MediaType.file,
          page: 1,
          size: 20,
        );

        expect(result.items, isEmpty);
        expect(result.hasMore, false);
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'not a map',
              statusCode: 200,
            ));

        expect(
          () => dataSource.getMediaGallery(1, MediaType.photo),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws AuthException on 403', () async {
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
          () => dataSource.getMediaGallery(1, MediaType.link),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on connection timeout', () async {
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dataSource.getMediaGallery(1, MediaType.photo),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('replyToMessage', () {
      test('returns MessageModel when succeeds with messageId format', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 20,
                'chatRoomId': 1,
                'senderId': 1,
                'content': 'Reply content',
                'type': 'TEXT',
                'replyToMessageId': 5,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.replyToMessage(5, 'Reply content');

        expect(result.id, 20);
        expect(result.content, 'Reply content');
        expect(result.replyToMessageId, 5);
      });

      test('uses messageId as replyToMessageId when missing from response', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 21,
                'senderId': 1,
                'content': 'Reply',
                'type': 'TEXT',
                'createdAt': [2026, 1, 22, 3, 4, 10, 0],
              },
              statusCode: 201,
            ));

        final result = await dataSource.replyToMessage(10, 'Reply');

        expect(result.replyToMessageId, 10);
      });

      test('uses getUserId fallback for senderId', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 22,
                'content': 'Reply with fallback',
                'type': 'TEXT',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.replyToMessage(3, 'Reply with fallback');

        expect(result.senderId, 1);
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'invalid',
              statusCode: 201,
            ));

        expect(
          () => dataSource.replyToMessage(1, 'content'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException on 500', () async {
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
          () => dataSource.replyToMessage(1, 'content'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('forwardMessage', () {
      test('returns MessageModel when succeeds', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 30,
                'chatRoomId': 2,
                'senderId': 1,
                'content': 'Forwarded text',
                'type': 'TEXT',
                'forwardedFromMessageId': 7,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.forwardMessage(7, 2);

        expect(result.id, 30);
        expect(result.chatRoomId, 2);
        expect(result.forwardedFromMessageId, 7);
      });

      test('uses targetChatRoomId as fallback for chatRoomId', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 31,
                'senderId': 1,
                'content': '',
                'type': 'TEXT',
                'createdAt': [2026, 1, 22, 3, 4, 10, 0],
              },
              statusCode: 201,
            ));

        final result = await dataSource.forwardMessage(8, 5);

        expect(result.chatRoomId, 5);
        expect(result.forwardedFromMessageId, 8);
      });

      test('uses getUserId fallback for senderId', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 32,
                'content': '',
                'type': 'TEXT',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.forwardMessage(9, 3);

        expect(result.senderId, 1);
      });

      test('throws ServerException when response format invalid', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'bad',
              statusCode: 201,
            ));

        expect(
          () => dataSource.forwardMessage(1, 2),
          throwsA(isA<ServerException>()),
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
          () => dataSource.forwardMessage(1, 2),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on receive timeout', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dataSource.forwardMessage(1, 2),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('updateChatRoomImage', () {
      test('completes successfully', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await expectLater(
          dataSource.updateChatRoomImage(1, 'https://example.com/img.jpg'),
          completes,
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
          () => dataSource.updateChatRoomImage(1, 'https://example.com/img.jpg'),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.updateChatRoomImage(1, 'https://example.com/img.jpg'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('updateMessage', () {
      test('handles array date format in updatedAt', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 1,
                'content': 'Updated content',
                'updatedAt': [2026, 1, 22, 3, 4, 10, 0],
              },
              statusCode: 200,
            ));

        final result = await dataSource.updateMessage(1, 'Updated content');

        expect(result.id, 1);
        expect(result.content, 'Updated content');
        expect(result.updatedAt, isA<DateTime>());
      });

      test('handles null updatedAt', () async {
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 2,
                'content': 'No date',
                'updatedAt': null,
              },
              statusCode: 200,
            ));

        final result = await dataSource.updateMessage(2, 'No date');

        expect(result.id, 2);
        expect(result.updatedAt, isA<DateTime>());
      });

      test('throws AuthException on 401', () async {
        when(() => mockDioClient.put(
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
          () => dataSource.updateMessage(1, 'content'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendMessage', () {
      test('throws ServerException when response is not a Map', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'not a map',
              statusCode: 201,
            ));

        expect(
          () => dataSource.sendMessage(
            const SendMessageRequest(chatRoomId: 1, content: 'Hi'),
          ),
          throwsA(isA<ServerException>()),
        );
      });

      test('uses getUserId fallback for senderId when server omits it', () async {
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {
                'messageId': 99,
                'content': 'Fallback test',
                'type': 'TEXT',
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
              statusCode: 201,
            ));

        final result = await dataSource.sendMessage(
          const SendMessageRequest(chatRoomId: 1, content: 'Fallback test'),
        );

        expect(result.senderId, 1);
      });
    });

    // Error handling tests
    group('error handling', () {
      test('getChatRooms throws NetworkException on network error', () async {
        when(() => mockDioClient.get(
              any(),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => dataSource.getChatRooms(),
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
          () => dataSource.createDirectChatRoom(2),
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
          () => dataSource.createGroupChatRoom('Group', [2]),
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
          () => dataSource.leaveChatRoom(1),
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
          () => dataSource.markAsRead(1),
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
          () => dataSource.getMessages(1),
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
            const SendMessageRequest(chatRoomId: 1, content: 'Hi'),
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
          () => dataSource.updateMessage(1, 'Updated'),
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
          () => dataSource.deleteMessage(1),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
