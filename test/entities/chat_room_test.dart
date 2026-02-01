import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';

void main() {
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
      expect(chatRoom.lastMessage, isNull);
      expect(chatRoom.lastMessageAt, isNull);
      expect(chatRoom.unreadCount, 0);
      expect(chatRoom.otherUserId, isNull);
      expect(chatRoom.otherUserNickname, isNull);
      expect(chatRoom.otherUserAvatarUrl, isNull);
    });

    test('creates chat room with all fields', () {
      final chatRoom = ChatRoom(
        id: 1,
        name: 'Test Room',
        type: ChatRoomType.group,
        createdAt: DateTime(2024, 1, 1),
        lastMessage: '안녕하세요',
        lastMessageAt: DateTime(2024, 1, 1, 10, 30),
        unreadCount: 5,
        otherUserId: 2,
        otherUserNickname: 'OtherUser',
        otherUserAvatarUrl: 'https://example.com/avatar.png',
      );

      expect(chatRoom.name, 'Test Room');
      expect(chatRoom.lastMessage, '안녕하세요');
      expect(chatRoom.lastMessageAt, DateTime(2024, 1, 1, 10, 30));
      expect(chatRoom.unreadCount, 5);
      expect(chatRoom.otherUserId, 2);
      expect(chatRoom.otherUserNickname, 'OtherUser');
      expect(chatRoom.otherUserAvatarUrl, 'https://example.com/avatar.png');
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

      test('returns otherUserNickname for direct chat', () {
        final chatRoom = ChatRoom(
          id: 1,
          type: ChatRoomType.direct,
          createdAt: DateTime(2024, 1, 1),
          otherUserId: 2,
          otherUserNickname: 'OtherUser',
        );

        expect(chatRoom.displayName, 'OtherUser');
      });

      test('returns default name when no name set and no other user info', () {
        final chatRoom = ChatRoom(
          id: 1,
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, '채팅방');
      });

      test('returns default name when name is empty', () {
        final chatRoom = ChatRoom(
          id: 1,
          name: '',
          type: ChatRoomType.group,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(chatRoom.displayName, '채팅방');
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
        createdAt: DateTime(2024, 1, 1),
        lastMessage: '마지막 메시지',
        unreadCount: 5,
        otherUserId: 2,
        otherUserNickname: 'OtherUser',
      );

      final updated = chatRoom.copyWith(name: 'New Name');

      expect(updated.lastMessage, '마지막 메시지');
      expect(updated.unreadCount, 5);
      expect(updated.otherUserId, 2);
      expect(updated.otherUserNickname, 'OtherUser');
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
      const member = ChatRoomMember(
        userId: 1,
        nickname: 'TestUser',
      );

      expect(member.userId, 1);
      expect(member.nickname, 'TestUser');
      expect(member.avatarUrl, isNull);
      expect(member.role, ChatRoomMemberRole.member);
      expect(member.isAdmin, false);
    });

    test('creates member with admin role', () {
      const member = ChatRoomMember(
        userId: 1,
        nickname: 'AdminUser',
        avatarUrl: 'https://example.com/avatar.png',
        role: ChatRoomMemberRole.admin,
      );

      expect(member.isAdmin, true);
      expect(member.avatarUrl, 'https://example.com/avatar.png');
    });

    test('equality works correctly', () {
      const member1 = ChatRoomMember(
        userId: 1,
        nickname: 'TestUser',
        role: ChatRoomMemberRole.admin,
      );

      const member2 = ChatRoomMember(
        userId: 1,
        nickname: 'TestUser',
        role: ChatRoomMemberRole.admin,
      );

      expect(member1, equals(member2));
    });

    test('props returns correct list', () {
      const member = ChatRoomMember(
        userId: 1,
        nickname: 'TestUser',
        role: ChatRoomMemberRole.admin,
      );

      expect(member.props.length, 4);
    });
  });

  group('ChatRoomType', () {
    test('has all expected values', () {
      expect(ChatRoomType.values.length, 3);
      expect(ChatRoomType.values, contains(ChatRoomType.direct));
      expect(ChatRoomType.values, contains(ChatRoomType.group));
      expect(ChatRoomType.values, contains(ChatRoomType.self));
    });
  });

  group('ChatRoomMemberRole', () {
    test('has all expected values', () {
      expect(ChatRoomMemberRole.values.length, 2);
      expect(ChatRoomMemberRole.values, contains(ChatRoomMemberRole.admin));
      expect(ChatRoomMemberRole.values, contains(ChatRoomMemberRole.member));
    });
  });
}
