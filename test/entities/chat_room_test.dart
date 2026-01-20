import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

void main() {
  final testUser = User(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testMember = ChatRoomMember(
    id: 1,
    user: testUser,
    isAdmin: true,
    joinedAt: DateTime(2024, 1, 1),
  );

  group('ChatRoom', () {
    test('creates chat room with required fields', () {
      final chatRoom = ChatRoom(
        id: 1,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(chatRoom.id, 1);
      expect(chatRoom.type, ChatRoomType.direct);
      expect(chatRoom.name, isNull);
      expect(chatRoom.announcement, isNull);
      expect(chatRoom.members, isEmpty);
      expect(chatRoom.lastMessage, isNull);
      expect(chatRoom.unreadCount, 0);
      expect(chatRoom.updatedAt, isNull);
    });

    test('creates chat room with all fields', () {
      final lastMessage = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: '안녕하세요',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 1),
      );

      final chatRoom = ChatRoom(
        id: 1,
        name: 'Test Room',
        type: ChatRoomType.group,
        announcement: '공지사항',
        members: [testMember],
        lastMessage: lastMessage,
        unreadCount: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(chatRoom.name, 'Test Room');
      expect(chatRoom.announcement, '공지사항');
      expect(chatRoom.members.length, 1);
      expect(chatRoom.lastMessage, lastMessage);
      expect(chatRoom.unreadCount, 5);
    });

    group('displayName', () {
      test('returns name when set', () {
        final chatRoom = ChatRoom(
          id: 1,
          name: 'My Room',
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, 'My Room');
      });

      test('returns first member nickname for direct chat', () {
        final chatRoom = ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          members: [testMember],
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, 'TestUser');
      });

      test('returns joined member names when no name set', () {
        final member2 = ChatRoomMember(
          id: 2,
          user: User(
            id: 2,
            email: 'user2@example.com',
            nickname: 'User2',
            createdAt: DateTime(2024, 1, 1),
          ),
          isAdmin: false,
          joinedAt: DateTime(2024, 1, 1),
        );

        final chatRoom = ChatRoom(
          id: 1,
          type: ChatRoomType.group,
          members: [testMember, member2],
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, 'TestUser, User2');
      });

      test('returns empty string when name is empty and no members', () {
        final chatRoom = ChatRoom(
          id: 1,
          name: '',
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, '');
      });
    });

    test('copyWith creates new chat room with updated fields', () {
      final chatRoom = ChatRoom(
        id: 1,
        name: 'Original',
        type: ChatRoomType.direct,
        unreadCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = chatRoom.copyWith(
        name: 'Updated',
        unreadCount: 10,
      );

      expect(updated.id, 1);
      expect(updated.name, 'Updated');
      expect(updated.unreadCount, 10);
      expect(updated.type, ChatRoomType.direct);
    });

    test('copyWith preserves unchanged fields', () {
      final chatRoom = ChatRoom(
        id: 1,
        name: 'Room',
        type: ChatRoomType.group,
        announcement: '공지',
        members: [testMember],
        unreadCount: 5,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = chatRoom.copyWith(name: 'New Name');

      expect(updated.announcement, '공지');
      expect(updated.members.length, 1);
      expect(updated.unreadCount, 5);
    });

    test('equality works correctly', () {
      final room1 = ChatRoom(
        id: 1,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );

      final room2 = ChatRoom(
        id: 1,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );

      final room3 = ChatRoom(
        id: 2,
        type: ChatRoomType.group,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(room1, equals(room2));
      expect(room1, isNot(equals(room3)));
    });
  });

  group('ChatRoomMember', () {
    test('creates member with required fields', () {
      final member = ChatRoomMember(
        id: 1,
        user: testUser,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(member.id, 1);
      expect(member.user, testUser);
      expect(member.isAdmin, false);
    });

    test('creates member with admin flag', () {
      final member = ChatRoomMember(
        id: 1,
        user: testUser,
        isAdmin: true,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(member.isAdmin, true);
    });

    test('equality works correctly', () {
      final member1 = ChatRoomMember(
        id: 1,
        user: testUser,
        isAdmin: true,
        joinedAt: DateTime(2024, 1, 1),
      );

      final member2 = ChatRoomMember(
        id: 1,
        user: testUser,
        isAdmin: true,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(member1, equals(member2));
    });

    test('props returns correct list', () {
      final member = ChatRoomMember(
        id: 1,
        user: testUser,
        isAdmin: true,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(member.props.length, 4);
    });
  });

  group('ChatRoomType', () {
    test('has all expected values', () {
      expect(ChatRoomType.values.length, 2);
      expect(ChatRoomType.values, contains(ChatRoomType.direct));
      expect(ChatRoomType.values, contains(ChatRoomType.group));
    });
  });
}
