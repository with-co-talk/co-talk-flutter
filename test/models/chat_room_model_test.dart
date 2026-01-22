import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/chat_room_model.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';

void main() {
  group('ChatRoomModel', () {
    test('creates model with required fields', () {
      final model = ChatRoomModel(
        id: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.name, isNull);
      expect(model.type, isNull);
      expect(model.lastMessage, isNull);
      expect(model.lastMessageAt, isNull);
    });

    test('creates model with all fields', () {
      final model = ChatRoomModel(
        id: 1,
        name: 'Test Room',
        type: 'GROUP',
        createdAt: DateTime(2024, 1, 1),
        lastMessage: '안녕하세요',
        lastMessageAt: DateTime(2024, 1, 1, 10, 30),
        unreadCount: 5,
        otherUserId: 2,
        otherUserNickname: 'OtherUser',
        otherUserAvatarUrl: 'https://example.com/avatar.png',
      );

      expect(model.name, 'Test Room');
      expect(model.type, 'GROUP');
      expect(model.lastMessage, '안녕하세요');
      expect(model.lastMessageAt, DateTime(2024, 1, 1, 10, 30));
      expect(model.unreadCount, 5);
      expect(model.otherUserId, 2);
      expect(model.otherUserNickname, 'OtherUser');
      expect(model.otherUserAvatarUrl, 'https://example.com/avatar.png');
    });

    group('toEntity', () {
      test('converts to ChatRoom entity', () {
        final model = ChatRoomModel(
          id: 1,
          name: 'Test Room',
          type: 'DIRECT',
          createdAt: DateTime(2024, 1, 1),
          lastMessage: '마지막 메시지',
          lastMessageAt: DateTime(2024, 1, 1, 10, 30),
          unreadCount: 3,
          otherUserId: 2,
          otherUserNickname: 'OtherUser',
        );

        final entity = model.toEntity();

        expect(entity, isA<ChatRoom>());
        expect(entity.id, 1);
        expect(entity.name, 'Test Room');
        expect(entity.type, ChatRoomType.direct);
        expect(entity.lastMessage, '마지막 메시지');
        expect(entity.unreadCount, 3);
        expect(entity.otherUserId, 2);
        expect(entity.otherUserNickname, 'OtherUser');
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

      test('handles null unreadCount as 0', () {
        final model = ChatRoomModel(
          id: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().unreadCount, 0);
      });
    });
  });

  group('ChatRoomMemberModel', () {
    test('creates model with required fields', () {
      const model = ChatRoomMemberModel(
        userId: 1,
        nickname: 'TestUser',
      );

      expect(model.userId, 1);
      expect(model.nickname, 'TestUser');
      expect(model.avatarUrl, isNull);
      expect(model.role, isNull);
    });

    test('creates model with all fields', () {
      const model = ChatRoomMemberModel(
        userId: 1,
        nickname: 'TestUser',
        avatarUrl: 'https://example.com/avatar.png',
        role: 'ADMIN',
      );

      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.role, 'ADMIN');
    });

    group('toEntity', () {
      test('converts to ChatRoomMember entity', () {
        const model = ChatRoomMemberModel(
          userId: 1,
          nickname: 'TestUser',
          avatarUrl: 'https://example.com/avatar.png',
          role: 'ADMIN',
        );

        final entity = model.toEntity();

        expect(entity.userId, 1);
        expect(entity.nickname, 'TestUser');
        expect(entity.avatarUrl, 'https://example.com/avatar.png');
        expect(entity.isAdmin, true);
      });

      test('handles null role as member', () {
        const model = ChatRoomMemberModel(
          userId: 1,
          nickname: 'TestUser',
        );

        expect(model.toEntity().isAdmin, false);
        expect(model.toEntity().role, ChatRoomMemberRole.member);
      });

      test('handles MEMBER role correctly', () {
        const model = ChatRoomMemberModel(
          userId: 1,
          nickname: 'TestUser',
          role: 'MEMBER',
        );

        expect(model.toEntity().isAdmin, false);
        expect(model.toEntity().role, ChatRoomMemberRole.member);
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
        creatorId: 1,
        memberIds: [2, 3],
      );

      expect(request.creatorId, 1);
      expect(request.name, isNull);
      expect(request.memberIds, [2, 3]);
    });

    test('creates request with name', () {
      const request = CreateGroupChatRoomRequest(
        creatorId: 1,
        name: '그룹 채팅방',
        memberIds: [2, 3],
      );

      expect(request.name, '그룹 채팅방');
    });

    test('toJson returns correct map with roomName key', () {
      const request = CreateGroupChatRoomRequest(
        creatorId: 1,
        name: '그룹',
        memberIds: [2],
      );

      final json = request.toJson();

      expect(json['creatorId'], 1);
      expect(json['roomName'], '그룹');
      expect(json['memberIds'], [2]);
    });
  });

  group('ChatRoomModel fromJson', () {
    test('parses json correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Room',
        'type': 'GROUP',
        'unreadCount': 5,
        'createdAt': '2024-01-01T00:00:00.000',
        'lastMessage': '마지막 메시지',
        'lastMessageAt': '2024-01-01T10:30:00.000',
        'otherUserId': 2,
        'otherUserNickname': 'OtherUser',
        'otherUserAvatarUrl': 'https://example.com/avatar.png',
      };

      final model = ChatRoomModel.fromJson(json);

      expect(model.id, 1);
      expect(model.name, 'Test Room');
      expect(model.type, 'GROUP');
      expect(model.unreadCount, 5);
      expect(model.lastMessage, '마지막 메시지');
      expect(model.otherUserId, 2);
      expect(model.otherUserNickname, 'OtherUser');
    });

    test('handles nullable fields', () {
      final json = {
        'id': 1,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final model = ChatRoomModel.fromJson(json);

      expect(model.name, isNull);
      expect(model.type, isNull);
      expect(model.lastMessage, isNull);
      expect(model.lastMessageAt, isNull);
      expect(model.otherUserId, isNull);
      expect(model.otherUserNickname, isNull);
      expect(model.otherUserAvatarUrl, isNull);
    });
  });

  group('ChatRoomMemberModel fromJson', () {
    test('parses json correctly', () {
      final json = {
        'userId': 1,
        'nickname': 'TestUser',
        'avatarUrl': 'https://example.com/avatar.png',
        'role': 'ADMIN',
      };

      final model = ChatRoomMemberModel.fromJson(json);

      expect(model.userId, 1);
      expect(model.nickname, 'TestUser');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.role, 'ADMIN');
    });

    test('handles nullable fields', () {
      final json = {
        'userId': 1,
        'nickname': 'TestUser',
      };

      final model = ChatRoomMemberModel.fromJson(json);

      expect(model.avatarUrl, isNull);
      expect(model.role, isNull);
    });
  });

  group('CreateChatRoomRequest fromJson', () {
    test('parses json correctly', () {
      final json = {
        'userId1': 1,
        'userId2': 2,
      };

      final request = CreateChatRoomRequest.fromJson(json);

      expect(request.userId1, 1);
      expect(request.userId2, 2);
    });
  });

  group('CreateGroupChatRoomRequest fromJson', () {
    test('parses json correctly with roomName', () {
      final json = {
        'creatorId': 1,
        'roomName': '그룹',
        'memberIds': [1, 2, 3],
      };

      final request = CreateGroupChatRoomRequest.fromJson(json);

      expect(request.creatorId, 1);
      expect(request.name, '그룹');
      expect(request.memberIds.length, 3);
    });

    test('parses json without name', () {
      final json = {
        'creatorId': 1,
        'memberIds': [1, 2],
      };

      final request = CreateGroupChatRoomRequest.fromJson(json);

      expect(request.name, isNull);
      expect(request.memberIds.length, 2);
    });
  });
}
