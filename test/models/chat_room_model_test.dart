import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/chat_room_model.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/data/models/message_model.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';

void main() {
  final testUserModel = UserModel(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testMemberModel = ChatRoomMemberModel(
    id: 1,
    user: testUserModel,
    isAdmin: true,
    joinedAt: DateTime(2024, 1, 1),
  );

  final testMessageModel = MessageModel(
    id: 1,
    chatRoomId: 1,
    senderId: 1,
    senderNickname: 'TestUser',
    content: '안녕하세요',
    type: 'TEXT',
    createdAt: DateTime(2024, 1, 1),
  );

  group('ChatRoomModel', () {
    test('creates model with required fields', () {
      final model = ChatRoomModel(
        id: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.name, isNull);
      expect(model.type, isNull);
      expect(model.members, isNull);
    });

    test('creates model with all fields', () {
      final model = ChatRoomModel(
        id: 1,
        name: 'Test Room',
        type: 'GROUP',
        announcement: '공지사항',
        members: [testMemberModel],
        lastMessage: testMessageModel,
        unreadCount: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(model.name, 'Test Room');
      expect(model.type, 'GROUP');
      expect(model.announcement, '공지사항');
      expect(model.members!.length, 1);
      expect(model.lastMessage, testMessageModel);
      expect(model.unreadCount, 5);
    });

    group('toEntity', () {
      test('converts to ChatRoom entity', () {
        final model = ChatRoomModel(
          id: 1,
          name: 'Test Room',
          type: 'DIRECT',
          members: [testMemberModel],
          unreadCount: 3,
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity, isA<ChatRoom>());
        expect(entity.id, 1);
        expect(entity.name, 'Test Room');
        expect(entity.type, ChatRoomType.direct);
        expect(entity.members.length, 1);
        expect(entity.unreadCount, 3);
      });

      test('converts GROUP type correctly', () {
        final model = ChatRoomModel(
          id: 1,
          type: 'GROUP',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, ChatRoomType.group);
      });

      test('converts DIRECT type correctly', () {
        final model = ChatRoomModel(
          id: 1,
          type: 'DIRECT',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, ChatRoomType.direct);
      });

      test('handles null type as direct', () {
        final model = ChatRoomModel(
          id: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().type, ChatRoomType.direct);
      });

      test('handles null members as empty list', () {
        final model = ChatRoomModel(
          id: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().members, isEmpty);
      });

      test('handles null unreadCount as 0', () {
        final model = ChatRoomModel(
          id: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().unreadCount, 0);
      });

      test('converts lastMessage when present', () {
        final model = ChatRoomModel(
          id: 1,
          lastMessage: testMessageModel,
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();
        expect(entity.lastMessage, isNotNull);
        expect(entity.lastMessage!.content, '안녕하세요');
      });
    });
  });

  group('ChatRoomMemberModel', () {
    test('creates model with required fields', () {
      final model = ChatRoomMemberModel(
        id: 1,
        user: testUserModel,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.user, testUserModel);
      expect(model.isAdmin, isNull);
    });

    test('creates model with admin flag', () {
      final model = ChatRoomMemberModel(
        id: 1,
        user: testUserModel,
        isAdmin: true,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(model.isAdmin, true);
    });

    group('toEntity', () {
      test('converts to ChatRoomMember entity', () {
        final model = ChatRoomMemberModel(
          id: 1,
          user: testUserModel,
          isAdmin: true,
          joinedAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity.id, 1);
        expect(entity.user.nickname, 'TestUser');
        expect(entity.isAdmin, true);
      });

      test('handles null isAdmin as false', () {
        final model = ChatRoomMemberModel(
          id: 1,
          user: testUserModel,
          joinedAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().isAdmin, false);
      });
    });
  });

  group('CreateChatRoomRequest', () {
    test('creates request with required fields', () {
      const request = CreateChatRoomRequest(
        userId1: 1,
        userId2: 2,
      );

      expect(request.userId1, 1);
      expect(request.userId2, 2);
    });

    test('toJson returns correct map', () {
      const request = CreateChatRoomRequest(
        userId1: 1,
        userId2: 2,
      );

      final json = request.toJson();

      expect(json['userId1'], 1);
      expect(json['userId2'], 2);
    });
  });

  group('CreateGroupChatRoomRequest', () {
    test('creates request with required fields', () {
      const request = CreateGroupChatRoomRequest(
        memberIds: [1, 2, 3],
      );

      expect(request.name, isNull);
      expect(request.memberIds, [1, 2, 3]);
    });

    test('creates request with name', () {
      const request = CreateGroupChatRoomRequest(
        name: '그룹 채팅방',
        memberIds: [1, 2, 3],
      );

      expect(request.name, '그룹 채팅방');
    });

    test('toJson returns correct map', () {
      const request = CreateGroupChatRoomRequest(
        name: '그룹',
        memberIds: [1, 2],
      );

      final json = request.toJson();

      expect(json['name'], '그룹');
      expect(json['memberIds'], [1, 2]);
    });
  });

  group('ChatRoomsResponse', () {
    test('creates response with chat rooms', () {
      final chatRoom = ChatRoomModel(
        id: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      final response = ChatRoomsResponse(chatRooms: [chatRoom]);

      expect(response.chatRooms.length, 1);
      expect(response.chatRooms.first.id, 1);
    });

    test('toJson returns correct map', () {
      final chatRoom = ChatRoomModel(
        id: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      final response = ChatRoomsResponse(chatRooms: [chatRoom]);
      final json = response.toJson();

      expect(json['chatRooms'], isA<List>());
    });
  });
}
