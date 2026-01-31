import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/local/chat_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/chat_room_model.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/data/repositories/chat_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}
class MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

void main() {
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockChatLocalDataSource mockLocalDataSource;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockChatLocalDataSource();
    repository = ChatRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);

    // Setup default behavior for local data source
    when(() => mockLocalDataSource.saveChatRooms(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveChatRoom(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveMessages(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveMessage(any(), syncStatus: any(named: 'syncStatus'))).thenAnswer((_) async {});
    when(() => mockLocalDataSource.deleteChatRoom(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.resetUnreadCount(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.markMessageAsDeleted(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.updateLastMessage(
      roomId: any(named: 'roomId'),
      lastMessage: any(named: 'lastMessage'),
      lastMessageType: any(named: 'lastMessageType'),
      lastMessageAt: any(named: 'lastMessageAt'),
    )).thenAnswer((_) async {});
    when(() => mockLocalDataSource.updateOtherUserLeftStatus(any(), any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(const SendMessageRequest(
      chatRoomId: 1,
      content: 'test',
    ));
    // Register fallback values for local data source methods
    registerFallbackValue(ChatRoom(
      id: 1,
      type: ChatRoomType.direct,
      createdAt: DateTime(2024, 1, 1),
      unreadCount: 0,
    ));
    registerFallbackValue(Message(
      id: 1,
      chatRoomId: 1,
      senderId: 1,
      content: 'test',
      createdAt: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(<ChatRoom>[]);
    registerFallbackValue(<Message>[]);
  });

  final testChatRoomModel = ChatRoomModel(
    id: 1,
    name: 'Test Room',
    type: 'DIRECT',
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
      test('returns chat rooms', () async {
        when(() => mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [testChatRoomModel]);

        final result = await repository.getChatRooms();

        expect(result, isA<List<ChatRoom>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        verify(() => mockRemoteDataSource.getChatRooms()).called(1);
      });
    });

    group('createDirectChatRoom', () {
      test('creates and returns chat room', () async {
        when(() => mockRemoteDataSource.createDirectChatRoom(any()))
            .thenAnswer((_) async => testChatRoomModel);

        final result = await repository.createDirectChatRoom(2);

        expect(result, isA<ChatRoom>());
        expect(result.id, 1);
        verify(() => mockRemoteDataSource.createDirectChatRoom(2)).called(1);
      });
    });

    group('createGroupChatRoom', () {
      test('creates and returns group chat room', () async {
        final groupChatRoomModel = ChatRoomModel(
          id: 2,
          name: '그룹 채팅방',
          type: 'GROUP',
          unreadCount: 0,
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockRemoteDataSource.createGroupChatRoom(any(), any()))
            .thenAnswer((_) async => groupChatRoomModel);

        final result = await repository.createGroupChatRoom('그룹 채팅방', [2, 3]);

        expect(result, isA<ChatRoom>());
        expect(result.id, 2);
        expect(result.type, ChatRoomType.group);
        verify(() => mockRemoteDataSource.createGroupChatRoom('그룹 채팅방', [2, 3]))
            .called(1);
      });
    });

    group('leaveChatRoom', () {
      test('leaves chat room successfully', () async {
        when(() => mockRemoteDataSource.leaveChatRoom(any()))
            .thenAnswer((_) async {});

        await repository.leaveChatRoom(1);

        verify(() => mockRemoteDataSource.leaveChatRoom(1)).called(1);
      });
    });

    group('markAsRead', () {
      test('marks messages as read successfully', () async {
        when(() => mockRemoteDataSource.markAsRead(any()))
            .thenAnswer((_) async {});

        await repository.markAsRead(1);

        verify(() => mockRemoteDataSource.markAsRead(1)).called(1);
      });
    });

    group('getMessages', () {
      test('returns messages with pagination info', () async {
        final messagesResponse = MessageHistoryResponse(
          messages: [testMessageModel],
          nextCursor: 123,
          hasMore: true,
        );

        when(() => mockRemoteDataSource.getMessages(
              any(),
              size: any(named: 'size'),
              beforeMessageId: any(named: 'beforeMessageId'),
            )).thenAnswer((_) async => messagesResponse);

        final result = await repository.getMessages(1, size: 50, beforeMessageId: null);

        expect(result.$1, isA<List<Message>>());
        expect(result.$1.length, 1);
        expect(result.$2, 123);
        expect(result.$3, true);
        verify(() => mockRemoteDataSource.getMessages(1, size: 50, beforeMessageId: null))
            .called(1);
      });
    });

    group('sendMessage', () {
      test('sends and returns message', () async {
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => testMessageModel);

        final result = await repository.sendMessage(1, '안녕하세요!');

        expect(result, isA<Message>());
        expect(result.content, '안녕하세요!');
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
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

        when(() => mockRemoteDataSource.updateMessage(any(), any()))
            .thenAnswer((_) async => updatedMessageModel);

        final result = await repository.updateMessage(1, '수정된 메시지');

        expect(result, isA<Message>());
        expect(result.content, '수정된 메시지');
        verify(() => mockRemoteDataSource.updateMessage(1, '수정된 메시지'))
            .called(1);
      });
    });

    group('deleteMessage', () {
      test('deletes message successfully', () async {
        when(() => mockRemoteDataSource.deleteMessage(any()))
            .thenAnswer((_) async {});

        await repository.deleteMessage(1);

        verify(() => mockRemoteDataSource.deleteMessage(1)).called(1);
      });
    });
  });
}
