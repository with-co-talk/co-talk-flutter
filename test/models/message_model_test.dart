import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

void main() {
  group('MessageModel', () {
    test('creates model with required fields', () {
      final model = MessageModel(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: '안녕하세요',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.chatRoomId, 1);
      expect(model.senderId, 1);
      expect(model.content, '안녕하세요');
    });

    test('creates model with all fields', () {
      final replyMessage = MessageModel(
        id: 0,
        chatRoomId: 1,
        senderId: 2,
        content: '원본',
        createdAt: DateTime(2024, 1, 1),
      );

      final model = MessageModel(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'TestUser',
        senderAvatarUrl: 'https://example.com/avatar.jpg',
        content: 'image.jpg',
        type: 'IMAGE',
        fileUrl: 'https://example.com/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024,
        fileContentType: 'image/jpeg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        replyToMessageId: 0,
        replyToMessage: replyMessage,
        forwardedFromMessageId: 10,
        isDeleted: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        reactions: [],
      );

      expect(model.senderNickname, 'TestUser');
      expect(model.type, 'IMAGE');
      expect(model.fileUrl, 'https://example.com/image.jpg');
      expect(model.replyToMessage, replyMessage);
    });

    group('toEntity', () {
      test('converts to Message entity', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          senderNickname: 'TestUser',
          content: '안녕하세요',
          type: 'TEXT',
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity, isA<Message>());
        expect(entity.id, 1);
        expect(entity.content, '안녕하세요');
        expect(entity.type, MessageType.text);
      });

      test('converts IMAGE type correctly', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'image.jpg',
          type: 'IMAGE',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, MessageType.image);
      });

      test('converts FILE type correctly', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'document.pdf',
          type: 'FILE',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, MessageType.file);
      });

      test('handles null type as text', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, MessageType.text);
      });

      test('handles unknown type as text', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          type: 'UNKNOWN',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, MessageType.text);
      });

      test('handles null isDeleted as false', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().isDeleted, false);
      });

      test('converts replyToMessage when present', () {
        final replyMessage = MessageModel(
          id: 0,
          chatRoomId: 1,
          senderId: 2,
          content: '원본 메시지',
          createdAt: DateTime(2024, 1, 1),
        );

        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '답장',
          replyToMessage: replyMessage,
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();
        expect(entity.replyToMessage, isNotNull);
        expect(entity.replyToMessage!.content, '원본 메시지');
      });

      test('converts reactions when present', () {
        const reaction = MessageReactionModel(
          id: 1,
          messageId: 1,
          userId: 2,
          emoji: '👍',
        );

        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          reactions: [reaction],
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();
        expect(entity.reactions.length, 1);
        expect(entity.reactions.first.emoji, '👍');
      });

      test('handles null reactions as empty list', () {
        final model = MessageModel(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().reactions, isEmpty);
      });
    });
  });

  group('MessageReactionModel', () {
    test('creates model with required fields', () {
      const model = MessageReactionModel(
        id: 1,
        messageId: 1,
        userId: 1,
        emoji: '👍',
      );

      expect(model.id, 1);
      expect(model.messageId, 1);
      expect(model.userId, 1);
      expect(model.emoji, '👍');
      expect(model.userNickname, isNull);
    });

    test('creates model with user nickname', () {
      const model = MessageReactionModel(
        id: 1,
        messageId: 1,
        userId: 1,
        userNickname: 'TestUser',
        emoji: '❤️',
      );

      expect(model.userNickname, 'TestUser');
    });

    group('toEntity', () {
      test('converts to MessageReaction entity', () {
        const model = MessageReactionModel(
          id: 1,
          messageId: 1,
          userId: 1,
          userNickname: 'TestUser',
          emoji: '👍',
        );

        final entity = model.toEntity();

        expect(entity, isA<MessageReaction>());
        expect(entity.id, 1);
        expect(entity.emoji, '👍');
        expect(entity.userNickname, 'TestUser');
      });
    });
  });

  group('SendMessageRequest', () {
    test('creates request with required fields', () {
      const request = SendMessageRequest(
        senderId: 1,
        chatRoomId: 1,
        content: '안녕하세요',
      );

      expect(request.senderId, 1);
      expect(request.chatRoomId, 1);
      expect(request.content, '안녕하세요');
    });

    test('toJson returns correct map', () {
      const request = SendMessageRequest(
        senderId: 1,
        chatRoomId: 1,
        content: '안녕하세요',
      );

      final json = request.toJson();

      expect(json['senderId'], 1);
      expect(json['chatRoomId'], 1);
      expect(json['content'], '안녕하세요');
    });
  });

  group('MessageHistoryResponse', () {
    test('creates response with required fields', () {
      final message = MessageModel(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello',
        createdAt: DateTime(2024, 1, 1),
      );

      final response = MessageHistoryResponse(
        messages: [message],
        hasMore: true,
      );

      expect(response.messages.length, 1);
      expect(response.hasMore, true);
      expect(response.nextCursor, isNull);
    });

    test('creates response with cursor', () {
      final response = MessageHistoryResponse(
        messages: [],
        nextCursor: 'cursor123',
        hasMore: false,
      );

      expect(response.nextCursor, 'cursor123');
      expect(response.hasMore, false);
    });

    test('toJson returns correct map', () {
      final response = MessageHistoryResponse(
        messages: [],
        hasMore: false,
      );

      final json = response.toJson();

      expect(json['messages'], isA<List>());
      expect(json['hasMore'], false);
    });
  });
}
