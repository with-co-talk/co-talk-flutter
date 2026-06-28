import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';

void main() {
  group('ChatRoomState.displayTitleOrNull / isSelfChat', () {
    test('self chat room: isSelfChat true, dynamic title null', () {
      const state = ChatRoomState(roomType: ChatRoomType.self);
      expect(state.isSelfChat, isTrue);
      expect(state.displayTitleOrNull, isNull);
    });

    test('returns otherUserNickname for direct chat room', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: 'Alice',
      );
      expect(state.isSelfChat, isFalse);
      expect(state.displayTitleOrNull, 'Alice');
    });

    test('returns null for direct chat room without otherUserNickname', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: null,
      );
      expect(state.displayTitleOrNull, isNull);
    });

    test('returns roomName for group chat room', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: '프로젝트 팀',
      );
      expect(state.displayTitleOrNull, '프로젝트 팀');
    });

    test('returns null for group chat room without name', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: null,
      );
      expect(state.displayTitleOrNull, isNull);
    });

    test('returns null for group chat room with empty name', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: '',
      );
      expect(state.displayTitleOrNull, isNull);
    });

    test('returns null when roomType is null and no name', () {
      const state = ChatRoomState();
      expect(state.isSelfChat, isFalse);
      expect(state.displayTitleOrNull, isNull);
    });

    test('returns roomName when roomType is null but roomName is set', () {
      const state = ChatRoomState(roomName: '임시 방');
      expect(state.displayTitleOrNull, '임시 방');
    });

    test('self type takes priority: isSelfChat true even with roomName', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.self,
        roomName: 'Custom Name',
      );
      expect(state.isSelfChat, isTrue);
      expect(state.displayTitleOrNull, isNull);
    });

    test('direct type with nickname takes priority over roomName', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: 'Bob',
        roomName: 'Custom Name',
      );
      expect(state.displayTitleOrNull, 'Bob');
    });
  });

  group('ChatRoomState.showTypingIndicator', () {
    test('defaults to false', () {
      const state = ChatRoomState();
      expect(state.showTypingIndicator, isFalse);
    });

    test('can be set to true via copyWith', () {
      const state = ChatRoomState();
      final updated = state.copyWith(showTypingIndicator: true);
      expect(updated.showTypingIndicator, isTrue);
    });
  });

  group('ChatRoomState typing indicator data', () {
    test('no one typing: firstTypingNickname null, count 0', () {
      const state = ChatRoomState(typingUsers: {});
      expect(state.firstTypingNickname, isNull);
      expect(state.typingCount, 0);
    });

    test('single user typing exposes nickname and count 1', () {
      const state = ChatRoomState(typingUsers: {2: 'Alice'});
      expect(state.firstTypingNickname, 'Alice');
      expect(state.typingCount, 1);
    });

    test('multiple users typing exposes count', () {
      const state = ChatRoomState(typingUsers: {2: 'Alice', 3: 'Bob'});
      expect(state.firstTypingNickname, 'Alice');
      expect(state.typingCount, 2);
    });
  });

  group('ChatRoomState.copyWith', () {
    test('preserves roomName and roomType', () {
      const state = ChatRoomState(
        roomName: '테스트 방',
        roomType: ChatRoomType.group,
      );
      final updated = state.copyWith(status: ChatRoomStatus.success);
      expect(updated.roomName, '테스트 방');
      expect(updated.roomType, ChatRoomType.group);
    });

    test('can update roomName', () {
      const state = ChatRoomState(roomName: '이전 이름');
      final updated = state.copyWith(roomName: '새 이름');
      expect(updated.roomName, '새 이름');
    });
  });
}
