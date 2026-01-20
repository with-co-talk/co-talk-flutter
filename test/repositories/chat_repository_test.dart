import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/chat_room_model.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/data/repositories/chat_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = ChatRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  setUpAll(() {
    registerFallbackValue(const SendMessageRequest(
      senderId: 1,
      chatRoomId: 1,
      content: 'test',
    ));
  });

  final testChatRoomModel = ChatRoomModel(
    id: 1,
    name: 'Test Room',
    type: 'DIRECT',
    members: [],
    unreadCount: 0,
    createdAt: DateTime(2024, 1, 1),
  );

  final testMessageModel = MessageModel(
    id: 1,
    chatRoomId: 1,
    senderId: 1,
    senderNickname: 'TestUser',
    content: '안녕하세요!',
    type: 'TEXT',
    isDeleted: false,
    createdAt: DateTime(2024, 1, 1),
  );

  group('ChatRepository', () {
    group('getChatRooms', () {
      test('returns chat rooms when user is logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.getChatRooms(any()))
            .thenAnswer((_) async => [testChatRoomModel]);

        final result = await repository.getChatRooms();

        expect(result, isA<List<ChatRoom>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        verify(() => mockRemoteDataSource.getChatRooms(1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.getChatRooms(),
          throwsException,
        );
      });
    });

    group('createDirectChatRoom', () {
      test('creates and returns chat room', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.createDirectChatRoom(any(), any()))
            .thenAnswer((_) async => testChatRoomModel);

        final result = await repository.createDirectChatRoom(2);

        expect(result, isA<ChatRoom>());
        expect(result.id, 1);
        verify(() => mockRemoteDataSource.createDirectChatRoom(1, 2)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.createDirectChatRoom(2),
          throwsException,
        );
      });
    });

    group('createGroupChatRoom', () {
      test('creates and returns group chat room', () async {
        final groupChatRoomModel = ChatRoomModel(
          id: 2,
          name: '그룹 채팅방',
          type: 'GROUP',
          members: [],
          unreadCount: 0,
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockRemoteDataSource.createGroupChatRoom(any(), any()))
            .thenAnswer((_) async => groupChatRoomModel);

        final result = await repository.createGroupChatRoom('그룹 채팅방', [1, 2, 3]);

        expect(result, isA<ChatRoom>());
        expect(result.id, 2);
        expect(result.type, ChatRoomType.group);
        verify(() => mockRemoteDataSource.createGroupChatRoom('그룹 채팅방', [1, 2, 3]))
            .called(1);
      });
    });

    group('leaveChatRoom', () {
      test('leaves chat room successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.leaveChatRoom(any(), any()))
            .thenAnswer((_) async {});

        await repository.leaveChatRoom(1);

        verify(() => mockRemoteDataSource.leaveChatRoom(1, 1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.leaveChatRoom(1),
          throwsException,
        );
      });
    });

    group('markAsRead', () {
      test('marks messages as read successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.markAsRead(any(), any()))
            .thenAnswer((_) async {});

        await repository.markAsRead(1);

        verify(() => mockRemoteDataSource.markAsRead(1, 1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.markAsRead(1),
          throwsException,
        );
      });
    });

    group('getMessages', () {
      test('returns messages with pagination info', () async {
        final messagesResponse = MessageHistoryResponse(
          messages: [testMessageModel],
          nextCursor: 'cursor123',
          hasMore: true,
        );

        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.getMessages(
              any(),
              any(),
              size: any(named: 'size'),
              cursor: any(named: 'cursor'),
            )).thenAnswer((_) async => messagesResponse);

        final result = await repository.getMessages(1, size: 50, cursor: null);

        expect(result.$1, isA<List<Message>>());
        expect(result.$1.length, 1);
        expect(result.$2, 'cursor123');
        expect(result.$3, true);
        verify(() => mockRemoteDataSource.getMessages(1, 1, size: 50, cursor: null))
            .called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.getMessages(1),
          throwsException,
        );
      });
    });

    group('sendMessage', () {
      test('sends and returns message', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => testMessageModel);

        final result = await repository.sendMessage(1, '안녕하세요!');

        expect(result, isA<Message>());
        expect(result.content, '안녕하세요!');
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.sendMessage(1, 'test'),
          throwsException,
        );
      });
    });

    group('updateMessage', () {
      test('updates and returns message', () async {
        final updatedMessageModel = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          senderNickname: 'TestUser',
          content: '수정된 메시지',
          type: 'TEXT',
          isDeleted: false,
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.updateMessage(any(), any(), any()))
            .thenAnswer((_) async => updatedMessageModel);

        final result = await repository.updateMessage(1, '수정된 메시지');

        expect(result, isA<Message>());
        expect(result.content, '수정된 메시지');
        verify(() => mockRemoteDataSource.updateMessage(1, 1, '수정된 메시지'))
            .called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.updateMessage(1, 'test'),
          throwsException,
        );
      });
    });

    group('deleteMessage', () {
      test('deletes message successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.deleteMessage(any(), any()))
            .thenAnswer((_) async {});

        await repository.deleteMessage(1);

        verify(() => mockRemoteDataSource.deleteMessage(1, 1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.deleteMessage(1),
          throwsException,
        );
      });
    });
  });
}
