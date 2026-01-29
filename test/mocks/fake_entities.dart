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
        createdAt: DateTime(2024, 1, 1),
        unreadCount: 0,
        otherUserId: 2,
        otherUserNickname: 'OtherUser',
        otherUserAvatarUrl: null,
      );

  /// 상대방 정보가 없는 1:1 채팅방 (테스트용)
  static ChatRoom get directChatRoomWithoutOtherUser => ChatRoom(
        id: 1,
        name: null,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
        unreadCount: 0,
      );

  static ChatRoom get groupChatRoom => ChatRoom(
        id: 2,
        name: '그룹 채팅방',
        type: ChatRoomType.group,
        createdAt: DateTime(2024, 1, 1),
        unreadCount: 5,
      );

  static ChatRoomMember get chatRoomMember => const ChatRoomMember(
        userId: 1,
        nickname: 'TestUser',
        avatarUrl: null,
        role: ChatRoomMemberRole.member,
      );

  static ChatRoomMember get chatRoomAdmin => const ChatRoomMember(
        userId: 2,
        nickname: 'AdminUser',
        avatarUrl: 'https://example.com/avatar.png',
        role: ChatRoomMemberRole.admin,
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

  static FriendRequest get friendRequest => FriendRequest(
        id: 1,
        requester: otherUser,
        receiver: user,
        status: FriendRequestStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

  static List<FriendRequest> get receivedFriendRequests => [
        friendRequest,
      ];

  static List<FriendRequest> get sentFriendRequests => [
        FriendRequest(
          id: 2,
          requester: user,
          receiver: otherUser,
          status: FriendRequestStatus.pending,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];
}
