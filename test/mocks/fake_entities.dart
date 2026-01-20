import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/domain/entities/auth_token.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';

class FakeEntities {
  static User get user => User(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        status: UserStatus.active,
        role: UserRole.user,
        onlineStatus: OnlineStatus.online,
        createdAt: DateTime(2024, 1, 1),
      );

  static User get otherUser => User(
        id: 2,
        email: 'other@example.com',
        nickname: 'OtherUser',
        status: UserStatus.active,
        role: UserRole.user,
        onlineStatus: OnlineStatus.offline,
        createdAt: DateTime(2024, 1, 1),
      );

  static AuthToken get authToken => const AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        tokenType: 'Bearer',
        expiresIn: 86400,
      );

  static ChatRoom get directChatRoom => ChatRoom(
        id: 1,
        name: null,
        type: ChatRoomType.direct,
        members: [
          ChatRoomMember(
            id: 1,
            user: otherUser,
            isAdmin: false,
            joinedAt: DateTime(2024, 1, 1),
          ),
        ],
        unreadCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );

  static ChatRoom get groupChatRoom => ChatRoom(
        id: 2,
        name: '그룹 채팅방',
        type: ChatRoomType.group,
        members: [
          ChatRoomMember(
            id: 1,
            user: user,
            isAdmin: true,
            joinedAt: DateTime(2024, 1, 1),
          ),
          ChatRoomMember(
            id: 2,
            user: otherUser,
            isAdmin: false,
            joinedAt: DateTime(2024, 1, 1),
          ),
        ],
        unreadCount: 5,
        createdAt: DateTime(2024, 1, 1),
      );

  static Message get textMessage => Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        senderNickname: 'TestUser',
        content: '안녕하세요!',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 1, 10, 0),
      );

  static Message get imageMessage => Message(
        id: 2,
        chatRoomId: 1,
        senderId: 2,
        senderNickname: 'OtherUser',
        content: 'image.jpg',
        type: MessageType.image,
        fileUrl: 'https://example.com/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024,
        createdAt: DateTime(2024, 1, 1, 10, 5),
      );

  static List<Message> get messages => [
        textMessage,
        imageMessage,
        Message(
          id: 3,
          chatRoomId: 1,
          senderId: 1,
          senderNickname: 'TestUser',
          content: '반갑습니다!',
          type: MessageType.text,
          createdAt: DateTime(2024, 1, 1, 10, 10),
        ),
      ];

  static Friend get friend => Friend(
        id: 1,
        user: otherUser,
        createdAt: DateTime(2024, 1, 1),
      );

  static List<Friend> get friends => [
        friend,
        Friend(
          id: 2,
          user: User(
            id: 3,
            email: 'friend2@example.com',
            nickname: 'Friend2',
            status: UserStatus.active,
            role: UserRole.user,
            onlineStatus: OnlineStatus.away,
            createdAt: DateTime(2024, 1, 1),
          ),
          createdAt: DateTime(2024, 1, 2),
        ),
      ];
}
