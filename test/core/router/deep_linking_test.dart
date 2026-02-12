import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/router/app_router.dart';

void main() {
  group('Deep Linking', () {
    group('URI Scheme Validation', () {
      test('should recognize cotalk:// scheme in chat routes', () {
        final chatRoute = AppRoutes.chatRoom;
        expect(chatRoute, contains('/chat/room/'));
      });

      test('should recognize cotalk:// scheme in profile routes', () {
        final profileRoute = AppRoutes.profileView;
        expect(profileRoute, contains('/profile/view/'));
      });

      test('should recognize cotalk:// scheme in direct chat routes', () {
        final directChatRoute = AppRoutes.directChat;
        expect(directChatRoute, contains('/chat/direct/'));
      });

      test('should generate correct deep link path for chat room', () {
        expect(AppRoutes.chatRoomPath(123), equals('/chat/room/123'));
      });

      test('should generate correct deep link path for profile', () {
        expect(AppRoutes.profileViewPath(456), equals('/profile/view/456'));
      });

      test('should generate correct deep link path for direct chat', () {
        expect(AppRoutes.directChatPath(789), equals('/chat/direct/789'));
      });
    });

    group('Deep Link Route Validation', () {
      test('chat room route should accept numeric ID parameter', () {
        expect(AppRoutes.chatRoom, contains(':roomId'));
      });

      test('profile route should accept numeric ID parameter', () {
        expect(AppRoutes.profileView, contains(':userId'));
      });

      test('direct chat route should accept numeric ID parameter', () {
        expect(AppRoutes.directChat, contains(':targetUserId'));
      });

      test('self chat route should accept numeric ID parameter', () {
        expect(AppRoutes.selfChat, contains(':userId'));
      });
    });

    group('Deep Link Path Construction', () {
      test('should construct valid chat room deep link', () {
        final path = AppRoutes.chatRoomPath(12345);
        expect(path, equals('/chat/room/12345'));
        expect(path, matches(RegExp(r'^/chat/room/\d+$')));
      });

      test('should construct valid profile deep link', () {
        final path = AppRoutes.profileViewPath(67890);
        expect(path, equals('/profile/view/67890'));
        expect(path, matches(RegExp(r'^/profile/view/\d+$')));
      });

      test('should construct valid direct chat deep link', () {
        final path = AppRoutes.directChatPath(11111);
        expect(path, equals('/chat/direct/11111'));
        expect(path, matches(RegExp(r'^/chat/direct/\d+$')));
      });

      test('should construct valid self chat deep link', () {
        final path = AppRoutes.selfChatPath(22222);
        expect(path, equals('/chat/self/22222'));
        expect(path, matches(RegExp(r'^/chat/self/\d+$')));
      });
    });
  });
}
