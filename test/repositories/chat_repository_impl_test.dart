import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/local/chat_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/chat_room_model.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/data/repositories/chat_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

class MockFile extends Mock implements File {}

void main() {
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockChatLocalDataSource mockLocalDataSource;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockChatLocalDataSource();
    repository = ChatRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);

    // Default stub: all local writes succeed silently
    when(() => mockLocalDataSource.saveChatRooms(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveChatRoom(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.saveMessages(any())).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.saveMessage(
        any(),
        syncStatus: any(named: 'syncStatus'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockLocalDataSource.deleteChatRoom(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.resetUnreadCount(any())).thenAnswer((_) async {});
    when(() => mockLocalDataSource.markMessageAsDeleted(any())).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.updateLastMessage(
        roomId: any(named: 'roomId'),
        lastMessage: any(named: 'lastMessage'),
        lastMessageType: any(named: 'lastMessageType'),
        lastMessageAt: any(named: 'lastMessageAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockLocalDataSource.updateOtherUserLeftStatus(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.clearAllData()).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(const SendMessageRequest(chatRoomId: 1, content: 'test'));
    registerFallbackValue(const SendFileMessageRequest(
      chatRoomId: 1,
      fileUrl: 'https://example.com/file.png',
      fileName: 'file.png',
      fileSize: 1024,
      contentType: 'image/png',
    ));
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
    registerFallbackValue(MockFile());
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
    content: 'Hello',
    type: 'TEXT',
    isDeleted: false,
    createdAt: DateTime(2024, 1, 1),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // getChatRooms
  // ─────────────────────────────────────────────────────────────────────────
  group('getChatRooms', () {
    test('returns chat rooms from remote and saves to local', () async {
      when(() => mockRemoteDataSource.getChatRooms())
          .thenAnswer((_) async => [testChatRoomModel]);

      final result = await repository.getChatRooms();

      expect(result, isA<List<ChatRoom>>());
      expect(result.length, 1);
      expect(result.first.id, 1);
      verify(() => mockRemoteDataSource.getChatRooms()).called(1);
    });

    test('falls back to cached rooms when remote throws', () async {
      final cachedRoom = ChatRoom(
        id: 1,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.getChatRooms()).thenThrow(Exception('network'));
      when(() => mockLocalDataSource.getChatRooms()).thenAnswer((_) async => [cachedRoom]);

      final result = await repository.getChatRooms();

      expect(result.length, 1);
      expect(result.first.id, 1);
      verify(() => mockLocalDataSource.getChatRooms()).called(1);
    });

    test('rethrows when remote throws and cache is empty', () async {
      when(() => mockRemoteDataSource.getChatRooms()).thenThrow(Exception('network'));
      when(() => mockLocalDataSource.getChatRooms()).thenAnswer((_) async => []);

      await expectLater(repository.getChatRooms(), throwsA(isA<Exception>()));
    });

    test('rethrows when remote throws and cache also throws', () async {
      when(() => mockRemoteDataSource.getChatRooms()).thenThrow(Exception('network'));
      when(() => mockLocalDataSource.getChatRooms()).thenThrow(Exception('cache error'));

      await expectLater(repository.getChatRooms(), throwsA(isA<Exception>()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getChatRoom
  // ─────────────────────────────────────────────────────────────────────────
  group('getChatRoom', () {
    test('returns chat room from remote and saves to local', () async {
      when(() => mockRemoteDataSource.getChatRoom(1))
          .thenAnswer((_) async => testChatRoomModel);

      final result = await repository.getChatRoom(1);

      expect(result.id, 1);
      verify(() => mockRemoteDataSource.getChatRoom(1)).called(1);
      verify(() => mockLocalDataSource.saveChatRoom(any())).called(1);
    });

    test('propagates exception from remote', () async {
      when(() => mockRemoteDataSource.getChatRoom(any())).thenThrow(Exception('error'));

      await expectLater(repository.getChatRoom(1), throwsA(isA<Exception>()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // createDirectChatRoom
  // ─────────────────────────────────────────────────────────────────────────
  group('createDirectChatRoom', () {
    test('creates and returns chat room, saves to local', () async {
      when(() => mockRemoteDataSource.createDirectChatRoom(any()))
          .thenAnswer((_) async => testChatRoomModel);

      final result = await repository.createDirectChatRoom(2);

      expect(result.id, 1);
      verify(() => mockRemoteDataSource.createDirectChatRoom(2)).called(1);
      verify(() => mockLocalDataSource.saveChatRoom(any())).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // createGroupChatRoom
  // ─────────────────────────────────────────────────────────────────────────
  group('createGroupChatRoom', () {
    test('creates group room with name and members', () async {
      final groupRoomModel = ChatRoomModel(
        id: 2,
        name: 'Group Room',
        type: 'GROUP',
        unreadCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.createGroupChatRoom(any(), any()))
          .thenAnswer((_) async => groupRoomModel);

      final result = await repository.createGroupChatRoom('Group Room', [2, 3]);

      expect(result.id, 2);
      expect(result.type, ChatRoomType.group);
      verify(() => mockRemoteDataSource.createGroupChatRoom('Group Room', [2, 3])).called(1);
      verify(() => mockLocalDataSource.saveChatRoom(any())).called(1);
    });

    test('creates group room with null name', () async {
      when(() => mockRemoteDataSource.createGroupChatRoom(any(), any()))
          .thenAnswer((_) async => testChatRoomModel);

      final result = await repository.createGroupChatRoom(null, [2, 3]);

      expect(result, isA<ChatRoom>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // leaveChatRoom
  // ─────────────────────────────────────────────────────────────────────────
  group('leaveChatRoom', () {
    test('calls remote then deletes from local cache', () async {
      when(() => mockRemoteDataSource.leaveChatRoom(any())).thenAnswer((_) async {});

      await repository.leaveChatRoom(1);

      verify(() => mockRemoteDataSource.leaveChatRoom(1)).called(1);
      verify(() => mockLocalDataSource.deleteChatRoom(1)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // markAsRead
  // ─────────────────────────────────────────────────────────────────────────
  group('markAsRead', () {
    test('calls remote then resets unread count in local', () async {
      when(() => mockRemoteDataSource.markAsRead(any())).thenAnswer((_) async {});

      await repository.markAsRead(1);

      verify(() => mockRemoteDataSource.markAsRead(1)).called(1);
      verify(() => mockLocalDataSource.resetUnreadCount(1)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getMessages
  // ─────────────────────────────────────────────────────────────────────────
  group('getMessages', () {
    test('returns messages with pagination info and saves to local', () async {
      final response = MessageHistoryResponse(
        messages: [testMessageModel],
        nextCursor: 123,
        hasMore: true,
      );
      when(() => mockRemoteDataSource.getMessages(
            any(),
            size: any(named: 'size'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => response);

      final result = await repository.getMessages(1, size: 50);

      expect(result.$1.length, 1);
      expect(result.$2, 123);
      expect(result.$3, true);
      verify(() => mockLocalDataSource.saveMessages(any())).called(1);
    });

    test('passes beforeMessageId for pagination', () async {
      final response = MessageHistoryResponse(messages: [], nextCursor: null, hasMore: false);
      when(() => mockRemoteDataSource.getMessages(
            any(),
            size: any(named: 'size'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => response);

      final result = await repository.getMessages(1, size: 20, beforeMessageId: 50);

      expect(result.$3, false);
      verify(() => mockRemoteDataSource.getMessages(1, size: 20, beforeMessageId: 50)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // sendMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('sendMessage', () {
    test('sends message, saves to local, and updates last message', () async {
      when(() => mockRemoteDataSource.sendMessage(any()))
          .thenAnswer((_) async => testMessageModel);

      final result = await repository.sendMessage(1, 'Hello');

      expect(result.content, 'Hello');
      verify(() => mockLocalDataSource.saveMessage(any())).called(1);
      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'Hello',
            lastMessageType: 'TEXT',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // updateMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('updateMessage', () {
    test('updates and returns message without saving to local', () async {
      final updatedModel = MessageModel(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Updated',
        type: 'TEXT',
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.updateMessage(any(), any()))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.updateMessage(1, 'Updated');

      expect(result.content, 'Updated');
      verify(() => mockRemoteDataSource.updateMessage(1, 'Updated')).called(1);
      // Should NOT save to local (slim response)
      verifyNever(() => mockLocalDataSource.saveMessage(any()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // deleteMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('deleteMessage', () {
    test('calls remote delete then marks as deleted in local', () async {
      when(() => mockRemoteDataSource.deleteMessage(any())).thenAnswer((_) async {});

      await repository.deleteMessage(1);

      verify(() => mockRemoteDataSource.deleteMessage(1)).called(1);
      verify(() => mockLocalDataSource.markMessageAsDeleted(1)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // reinviteUser
  // ─────────────────────────────────────────────────────────────────────────
  group('reinviteUser', () {
    test('calls remote reinvite and updates other user left status to false', () async {
      when(() => mockRemoteDataSource.reinviteUser(any(), any())).thenAnswer((_) async {});

      await repository.reinviteUser(1, 2);

      verify(() => mockRemoteDataSource.reinviteUser(1, 2)).called(1);
      verify(() => mockLocalDataSource.updateOtherUserLeftStatus(1, false)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // replyToMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('replyToMessage', () {
    test('sends reply, saves to local, and returns message', () async {
      final replyModel = MessageModel(
        id: 2,
        chatRoomId: 1,
        senderId: 1,
        content: 'Reply',
        type: 'TEXT',
        replyToMessageId: 1,
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.replyToMessage(any(), any()))
          .thenAnswer((_) async => replyModel);

      final result = await repository.replyToMessage(1, 'Reply');

      expect(result.content, 'Reply');
      verify(() => mockRemoteDataSource.replyToMessage(1, 'Reply')).called(1);
      verify(() => mockLocalDataSource.saveMessage(any())).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // forwardMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('forwardMessage', () {
    test('forwards message, saves to local, and returns message', () async {
      final forwardModel = MessageModel(
        id: 3,
        chatRoomId: 2,
        senderId: 1,
        content: 'Forwarded',
        type: 'TEXT',
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.forwardMessage(any(), any()))
          .thenAnswer((_) async => forwardModel);

      final result = await repository.forwardMessage(1, 2);

      expect(result.content, 'Forwarded');
      verify(() => mockRemoteDataSource.forwardMessage(1, 2)).called(1);
      verify(() => mockLocalDataSource.saveMessage(any())).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // updateChatRoomImage
  // ─────────────────────────────────────────────────────────────────────────
  group('updateChatRoomImage', () {
    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.updateChatRoomImage(any(), any()))
          .thenAnswer((_) async {});

      await repository.updateChatRoomImage(1, 'https://example.com/image.jpg');

      verify(() =>
              mockRemoteDataSource.updateChatRoomImage(1, 'https://example.com/image.jpg'))
          .called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // uploadFile
  // ─────────────────────────────────────────────────────────────────────────
  group('uploadFile', () {
    test('uploads file and maps response to FileUploadResult', () async {
      final fakeFile = MockFile();
      when(() => mockRemoteDataSource.uploadFile(any())).thenAnswer(
        (_) async => const FileUploadResponse(
          fileUrl: 'https://example.com/file.png',
          fileName: 'file.png',
          contentType: 'image/png',
          fileSize: 1024,
          isImage: true,
        ),
      );

      final result = await repository.uploadFile(fakeFile);

      expect(result, isA<FileUploadResult>());
      expect(result.fileUrl, 'https://example.com/file.png');
      expect(result.isImage, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // sendFileMessage
  // ─────────────────────────────────────────────────────────────────────────
  group('sendFileMessage', () {
    test('sends image file message, updates last message with IMAGE type', () async {
      final imageMessageModel = MessageModel(
        id: 10,
        chatRoomId: 1,
        senderId: 1,
        content: 'photo.png',
        type: 'IMAGE',
        fileUrl: 'https://example.com/photo.png',
        fileName: 'photo.png',
        fileSize: 2048,
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.sendFileMessage(any()))
          .thenAnswer((_) async => imageMessageModel);

      final result = await repository.sendFileMessage(
        roomId: 1,
        fileUrl: 'https://example.com/photo.png',
        fileName: 'photo.png',
        fileSize: 2048,
        contentType: 'image/png',
      );

      expect(result.id, 10);
      verify(() => mockLocalDataSource.saveMessage(any())).called(1);
      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'photo.png',
            lastMessageType: 'IMAGE',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });

    test('sends non-image file message, updates last message with FILE type', () async {
      final fileMessageModel = MessageModel(
        id: 11,
        chatRoomId: 1,
        senderId: 1,
        content: 'document.pdf',
        type: 'FILE',
        fileUrl: 'https://example.com/document.pdf',
        fileName: 'document.pdf',
        fileSize: 4096,
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRemoteDataSource.sendFileMessage(any()))
          .thenAnswer((_) async => fileMessageModel);

      await repository.sendFileMessage(
        roomId: 1,
        fileUrl: 'https://example.com/document.pdf',
        fileName: 'document.pdf',
        fileSize: 4096,
        contentType: 'application/pdf',
      );

      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'document.pdf',
            lastMessageType: 'FILE',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });

    test('sends file message with thumbnailUrl', () async {
      when(() => mockRemoteDataSource.sendFileMessage(any()))
          .thenAnswer((_) async => testMessageModel);

      await repository.sendFileMessage(
        roomId: 1,
        fileUrl: 'https://example.com/video.mp4',
        fileName: 'video.mp4',
        fileSize: 8192,
        contentType: 'video/mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      final captured = verify(() => mockRemoteDataSource.sendFileMessage(captureAny())).captured;
      final request = captured.first as SendFileMessageRequest;
      expect(request.thumbnailUrl, 'https://example.com/thumb.jpg');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getLocalMessages
  // ─────────────────────────────────────────────────────────────────────────
  group('getLocalMessages', () {
    test('returns messages from local data source', () async {
      final localMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'local',
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockLocalDataSource.getMessages(
            any(),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => [localMessage]);

      final result = await repository.getLocalMessages(1, limit: 20);

      expect(result.length, 1);
      expect(result.first.content, 'local');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // searchMessages
  // ─────────────────────────────────────────────────────────────────────────
  group('searchMessages', () {
    test('returns searched messages from local', () async {
      final found = Message(
        id: 5,
        chatRoomId: 1,
        senderId: 1,
        content: 'findme',
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockLocalDataSource.searchMessages(
            any(),
            chatRoomId: any(named: 'chatRoomId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [found]);

      final result = await repository.searchMessages('findme', chatRoomId: 1);

      expect(result.length, 1);
      expect(result.first.content, 'findme');
    });

    test('uses default limit of 50', () async {
      when(() => mockLocalDataSource.searchMessages(
            any(),
            chatRoomId: any(named: 'chatRoomId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await repository.searchMessages('query');

      verify(() => mockLocalDataSource.searchMessages('query', chatRoomId: null, limit: 50))
          .called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // saveMessageLocally
  // ─────────────────────────────────────────────────────────────────────────
  group('saveMessageLocally', () {
    test('saves TEXT message and updates last message with TEXT type', () async {
      final textMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 1),
      );

      await repository.saveMessageLocally(textMessage);

      verify(() => mockLocalDataSource.saveMessage(textMessage)).called(1);
      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'Hello',
            lastMessageType: 'TEXT',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });

    test('saves IMAGE message and updates with IMAGE type', () async {
      final imageMessage = Message(
        id: 2,
        chatRoomId: 1,
        senderId: 1,
        content: 'photo.png',
        type: MessageType.image,
        createdAt: DateTime(2024, 1, 1),
      );

      await repository.saveMessageLocally(imageMessage);

      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'photo.png',
            lastMessageType: 'IMAGE',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });

    test('saves FILE message and updates with FILE type', () async {
      final fileMessage = Message(
        id: 3,
        chatRoomId: 1,
        senderId: 1,
        content: 'doc.pdf',
        type: MessageType.file,
        createdAt: DateTime(2024, 1, 1),
      );

      await repository.saveMessageLocally(fileMessage);

      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'doc.pdf',
            lastMessageType: 'FILE',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });

    test('saves SYSTEM message and updates with SYSTEM type', () async {
      final systemMessage = Message(
        id: 4,
        chatRoomId: 1,
        senderId: 0,
        content: 'User joined',
        type: MessageType.system,
        createdAt: DateTime(2024, 1, 1),
      );

      await repository.saveMessageLocally(systemMessage);

      verify(() => mockLocalDataSource.updateLastMessage(
            roomId: 1,
            lastMessage: 'User joined',
            lastMessageType: 'SYSTEM',
            lastMessageAt: any(named: 'lastMessageAt'),
          )).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getLocalChatRooms
  // ─────────────────────────────────────────────────────────────────────────
  group('getLocalChatRooms', () {
    test('returns chat rooms from local data source', () async {
      final cachedRoom = ChatRoom(
        id: 5,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockLocalDataSource.getChatRooms()).thenAnswer((_) async => [cachedRoom]);

      final result = await repository.getLocalChatRooms();

      expect(result.length, 1);
      expect(result.first.id, 5);
    });

    test('returns empty list when no cached rooms', () async {
      when(() => mockLocalDataSource.getChatRooms()).thenAnswer((_) async => []);

      final result = await repository.getLocalChatRooms();

      expect(result, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // clearLocalData
  // ─────────────────────────────────────────────────────────────────────────
  group('clearLocalData', () {
    test('delegates to local data source clearAllData', () async {
      await repository.clearLocalData();

      verify(() => mockLocalDataSource.clearAllData()).called(1);
    });
  });
}
