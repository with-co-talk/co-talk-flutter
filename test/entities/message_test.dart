import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

void main() {
  group('Message', () {
    test('creates message with required fields', () {
      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: '안녕하세요',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.id, 1);
      expect(message.chatRoomId, 1);
      expect(message.senderId, 1);
      expect(message.content, '안녕하세요');
      expect(message.type, MessageType.text);
      expect(message.isDeleted, false);
      expect(message.reactions, isEmpty);
    });

    test('creates message with all fields', () {
      final replyMessage = Message(
        id: 0,
        chatRoomId: 1,
        senderId: 2,
        content: '원본 메시지',
        createdAt: DateTime(2024, 1, 1),
      );

      final reaction = const MessageReaction(
        id: 1,
        messageId: 1,
        userId: 2,
        emoji: '👍',
      );

      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'TestUser',
        senderAvatarUrl: 'https://example.com/avatar.jpg',
        content: 'image.jpg',
        type: MessageType.image,
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
        reactions: [reaction],
      );

      expect(message.senderNickname, 'TestUser');
      expect(message.senderAvatarUrl, 'https://example.com/avatar.jpg');
      expect(message.type, MessageType.image);
      expect(message.fileUrl, 'https://example.com/image.jpg');
      expect(message.fileName, 'image.jpg');
      expect(message.fileSize, 1024);
      expect(message.fileContentType, 'image/jpeg');
      expect(message.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(message.replyToMessage, replyMessage);
      expect(message.forwardedFromMessageId, 10);
      expect(message.reactions.length, 1);
    });

    group('isFile', () {
      test('returns true for image type', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'image.jpg',
          type: MessageType.image,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(message.isFile, true);
      });

      test('returns true for file type', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'document.pdf',
          type: MessageType.file,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(message.isFile, true);
      });

      test('returns false for text type', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(message.isFile, false);
      });
    });

    group('displayContent', () {
      test('returns content when not deleted', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '안녕하세요',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(message.displayContent, '안녕하세요');
      });

      test('returns deleted message text when deleted', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: '안녕하세요',
          isDeleted: true,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(message.displayContent, '삭제된 메시지입니다');
      });
    });

    test('copyWith creates new message with updated fields', () {
      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = message.copyWith(
        content: 'Updated',
        isDeleted: true,
      );

      expect(updated.id, 1);
      expect(updated.content, 'Updated');
      expect(updated.isDeleted, true);
      expect(updated.chatRoomId, 1);
    });

    test('copyWith preserves unchanged fields', () {
      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'User',
        content: 'Hello',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = message.copyWith(content: 'New Content');

      expect(updated.senderNickname, 'User');
      expect(updated.type, MessageType.text);
      expect(updated.senderId, 1);
    });

    test('equality works correctly', () {
      final message1 = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello',
        createdAt: DateTime(2024, 1, 1),
      );

      final message2 = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello',
        createdAt: DateTime(2024, 1, 1),
      );

      final message3 = Message(
        id: 2,
        chatRoomId: 1,
        senderId: 1,
        content: 'Different',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });
  });

  group('MessageReaction', () {
    test('creates reaction with required fields', () {
      const reaction = MessageReaction(
        id: 1,
        messageId: 1,
        userId: 1,
        emoji: '👍',
      );

      expect(reaction.id, 1);
      expect(reaction.messageId, 1);
      expect(reaction.userId, 1);
      expect(reaction.emoji, '👍');
      expect(reaction.userNickname, isNull);
    });

    test('creates reaction with user nickname', () {
      const reaction = MessageReaction(
        id: 1,
        messageId: 1,
        userId: 1,
        userNickname: 'TestUser',
        emoji: '❤️',
      );

      expect(reaction.userNickname, 'TestUser');
    });

    test('equality works correctly', () {
      const reaction1 = MessageReaction(
        id: 1,
        messageId: 1,
        userId: 1,
        emoji: '👍',
      );

      const reaction2 = MessageReaction(
        id: 1,
        messageId: 1,
        userId: 1,
        emoji: '👍',
      );

      expect(reaction1, equals(reaction2));
    });
  });

  group('MessageType', () {
    test('has all expected values', () {
      expect(MessageType.values.length, 4);
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.file));
      expect(MessageType.values, contains(MessageType.system));
    });
  });
}
