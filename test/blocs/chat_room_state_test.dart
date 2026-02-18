import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';

void main() {
  group('ChatRoomState.displayTitle', () {
    test('returns "나와의 채팅" for self chat room', () {
      const state = ChatRoomState(roomType: ChatRoomType.self);
      expect(state.displayTitle, '나와의 채팅');
    });

    test('returns otherUserNickname for direct chat room', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: 'Alice',
      );
      expect(state.displayTitle, 'Alice');
    });

    test('returns "채팅" for direct chat room without otherUserNickname', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: null,
      );
      expect(state.displayTitle, '채팅');
    });

    test('returns roomName for group chat room', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: '프로젝트 팀',
      );
      expect(state.displayTitle, '프로젝트 팀');
    });

    test('returns "채팅" for group chat room without name', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: null,
      );
      expect(state.displayTitle, '채팅');
    });

    test('returns "채팅" for group chat room with empty name', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.group,
        roomName: '',
      );
      expect(state.displayTitle, '채팅');
    });

    test('returns "채팅" when roomType is null', () {
      const state = ChatRoomState();
      expect(state.displayTitle, '채팅');
    });

    test('returns roomName when roomType is null but roomName is set', () {
      const state = ChatRoomState(roomName: '임시 방');
      expect(state.displayTitle, '임시 방');
    });

    test('self type takes priority over roomName', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.self,
        roomName: 'Custom Name',
      );
      expect(state.displayTitle, '나와의 채팅');
    });

    test('direct type with nickname takes priority over roomName', () {
      const state = ChatRoomState(
        roomType: ChatRoomType.direct,
        otherUserNickname: 'Bob',
        roomName: 'Custom Name',
      );
      expect(state.displayTitle, 'Bob');
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

  group('ChatRoomState.typingIndicatorText', () {
    test('returns empty string when no one is typing', () {
      const state = ChatRoomState(typingUsers: {});
      expect(state.typingIndicatorText, '');
    });

    test('returns single user typing text', () {
      const state = ChatRoomState(typingUsers: {2: 'Alice'});
      expect(state.typingIndicatorText, 'Alice님이 입력 중...');
    });

    test('returns multiple users typing text', () {
      const state = ChatRoomState(typingUsers: {2: 'Alice', 3: 'Bob'});
      expect(state.typingIndicatorText, '2명이 입력 중...');
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
