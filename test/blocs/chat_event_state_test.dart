import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_room_state.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';

void main() {
  group('ChatListEvent', () {
    group('ChatListLoadRequested', () {
      test('creates event', () {
        const event = ChatListLoadRequested();
        expect(event, isA<ChatListEvent>());
      });

      test('equality works', () {
        const event1 = ChatListLoadRequested();
        const event2 = ChatListLoadRequested();
        expect(event1, equals(event2));
      });

      test('props is empty', () {
        const event = ChatListLoadRequested();
        expect(event.props, isEmpty);
      });
    });

    group('ChatListRefreshRequested', () {
      test('creates event', () {
        const event = ChatListRefreshRequested();
        expect(event, isA<ChatListEvent>());
      });

      test('props is empty', () {
        const event = ChatListRefreshRequested();
        expect(event.props, isEmpty);
      });
    });

    group('ChatRoomCreated', () {
      test('creates event with userId', () {
        const event = ChatRoomCreated(2);
        expect(event.otherUserId, 2);
      });

      test('equality works', () {
        const event1 = ChatRoomCreated(2);
        const event2 = ChatRoomCreated(2);
        const event3 = ChatRoomCreated(3);

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('props contains otherUserId', () {
        const event = ChatRoomCreated(2);
        expect(event.props, contains(2));
      });
    });

    group('GroupChatRoomCreated', () {
      test('creates event with name and memberIds', () {
        const event = GroupChatRoomCreated(
          name: '그룹 채팅방',
          memberIds: [1, 2, 3],
        );

        expect(event.name, '그룹 채팅방');
        expect(event.memberIds, [1, 2, 3]);
      });

      test('equality works', () {
        const event1 = GroupChatRoomCreated(
          name: '그룹',
          memberIds: [1, 2],
        );
        const event2 = GroupChatRoomCreated(
          name: '그룹',
          memberIds: [1, 2],
        );

        expect(event1, equals(event2));
      });

      test('props contains name and memberIds', () {
        const event = GroupChatRoomCreated(
          name: '그룹',
          memberIds: [1, 2],
        );

        expect(event.props, contains('그룹'));
        expect(event.props.any((p) => p is List), isTrue);
      });
    });
  });

  group('ChatListState', () {
    test('initial state', () {
      const state = ChatListState();

      expect(state.status, ChatListStatus.initial);
      expect(state.chatRooms, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('creates state with all fields', () {
      final chatRoom = ChatRoom(
        id: 1,
        type: ChatRoomType.direct,
        createdAt: DateTime(2024, 1, 1),
      );

      final state = ChatListState(
        status: ChatListStatus.success,
        chatRooms: [chatRoom],
        errorMessage: null,
      );

      expect(state.status, ChatListStatus.success);
      expect(state.chatRooms.length, 1);
    });

    test('copyWith creates new state', () {
      const state = ChatListState();

      final newState = state.copyWith(
        status: ChatListStatus.loading,
      );

      expect(newState.status, ChatListStatus.loading);
    });

    test('equality works', () {
      const state1 = ChatListState();
      const state2 = ChatListState();

      expect(state1, equals(state2));
    });

    group('copyWith clearErrorMessage', () {
      test('errorMessage can be cleared with clearErrorMessage: true', () {
        final stateWithError = const ChatListState().copyWith(
          errorMessage: 'some error',
        );
        expect(stateWithError.errorMessage, 'some error');

        final clearedState = stateWithError.copyWith(clearErrorMessage: true);
        expect(clearedState.errorMessage, isNull);
      });

      test('errorMessage stays when not explicitly cleared', () {
        final stateWithError = const ChatListState().copyWith(
          errorMessage: 'some error',
        );

        final updatedState = stateWithError.copyWith(
          status: ChatListStatus.success,
        );
        expect(updatedState.errorMessage, 'some error');
      });

      test('clearErrorMessage: false does not clear error', () {
        final stateWithError = const ChatListState().copyWith(
          errorMessage: 'some error',
        );
        final updatedState = stateWithError.copyWith(clearErrorMessage: false);
        expect(updatedState.errorMessage, 'some error');
      });

      test('clearErrorMessage: true takes precedence over new errorMessage', () {
        final stateWithError = const ChatListState().copyWith(
          errorMessage: 'old error',
        );
        final updatedState = stateWithError.copyWith(
          errorMessage: 'new error',
          clearErrorMessage: true,
        );
        // clearErrorMessage takes precedence - it clears to null
        expect(updatedState.errorMessage, isNull);
      });
    });
  });

  group('ChatRoomEvent', () {
    group('ChatRoomOpened', () {
      test('creates event with roomId', () {
        const event = ChatRoomOpened(1);
        expect(event.roomId, 1);
      });

      test('equality works', () {
        const event1 = ChatRoomOpened(1);
        const event2 = ChatRoomOpened(1);
        expect(event1, equals(event2));
      });

      test('props contains roomId', () {
        const event = ChatRoomOpened(1);
        expect(event.props, contains(1));
      });
    });

    group('ChatRoomClosed', () {
      test('creates event', () {
        const event = ChatRoomClosed();
        expect(event, isA<ChatRoomEvent>());
      });

      test('equality works', () {
        const event1 = ChatRoomClosed();
        const event2 = ChatRoomClosed();
        expect(event1, equals(event2));
      });

      test('props is empty', () {
        const event = ChatRoomClosed();
        expect(event.props, isEmpty);
      });
    });

    group('MessageSent', () {
      test('creates event with content', () {
        const event = MessageSent('안녕하세요');
        expect(event.content, '안녕하세요');
      });

      test('equality works', () {
        const event1 = MessageSent('Hello');
        const event2 = MessageSent('Hello');
        expect(event1, equals(event2));
      });

      test('props contains content', () {
        const event = MessageSent('Hello');
        expect(event.props, contains('Hello'));
      });
    });

    group('MessageReceived', () {
      test('creates event with message', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1),
        );

        final event = MessageReceived(message);
        expect(event.message, message);
      });

      test('props contains message', () {
        final message = Message(
          id: 1,
          chatRoomId: 1,
          senderId: 1,
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1),
        );

        final event = MessageReceived(message);
        expect(event.props, contains(message));
      });
    });

    group('MessageDeleted', () {
      test('creates event with messageId', () {
        const event = MessageDeleted(1);
        expect(event.messageId, 1);
      });

      test('props contains messageId', () {
        const event = MessageDeleted(1);
        expect(event.props, contains(1));
      });
    });

    group('MessagesLoadMoreRequested', () {
      test('creates event', () {
        const event = MessagesLoadMoreRequested();
        expect(event, isA<ChatRoomEvent>());
      });

      test('props is empty', () {
        const event = MessagesLoadMoreRequested();
        expect(event.props, isEmpty);
      });
    });
  });

  group('ChatRoomState', () {
    test('initial state', () {
      const state = ChatRoomState();

      expect(state.status, ChatRoomStatus.initial);
      expect(state.roomId, isNull);
      expect(state.messages, isEmpty);
      expect(state.isSending, false);
      expect(state.hasMore, false);
    });

    test('creates state with all fields', () {
      final message = Message(
        id: 1,
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello',
        createdAt: DateTime(2024, 1, 1),
      );

      final state = ChatRoomState(
        status: ChatRoomStatus.success,
        roomId: 1,
        messages: [message],
        nextCursor: 123,
        hasMore: false,
        isSending: true,
      );

      expect(state.status, ChatRoomStatus.success);
      expect(state.roomId, 1);
      expect(state.messages.length, 1);
      expect(state.nextCursor, 123);
      expect(state.hasMore, false);
      expect(state.isSending, true);
    });

    test('copyWith creates new state', () {
      const state = ChatRoomState();

      final newState = state.copyWith(
        status: ChatRoomStatus.loading,
        roomId: 1,
      );

      expect(newState.status, ChatRoomStatus.loading);
      expect(newState.roomId, 1);
    });

    test('equality works', () {
      const state1 = ChatRoomState();
      const state2 = ChatRoomState();

      expect(state1, equals(state2));
    });

    group('copyWith clearErrorMessage', () {
      test('clearErrorMessage: true resets errorMessage to null', () {
        final state = const ChatRoomState().copyWith(errorMessage: 'error');
        expect(state.errorMessage, 'error');

        final cleared = state.copyWith(clearErrorMessage: true);
        expect(cleared.errorMessage, isNull);
      });

      test('clearErrorMessage: false preserves errorMessage', () {
        final state = const ChatRoomState().copyWith(errorMessage: 'error');
        final unchanged = state.copyWith(clearErrorMessage: false);
        expect(unchanged.errorMessage, 'error');
      });

      test('new errorMessage overrides old when clearErrorMessage is false', () {
        final state = const ChatRoomState().copyWith(errorMessage: 'old');
        final updated = state.copyWith(errorMessage: 'new');
        expect(updated.errorMessage, 'new');
      });

      test('errorMessage is sticky when not explicitly cleared', () {
        final state = const ChatRoomState().copyWith(errorMessage: 'error');
        final updated = state.copyWith(status: ChatRoomStatus.success);
        expect(updated.errorMessage, 'error');
      });

      test('clearErrorMessage: true takes precedence over new errorMessage', () {
        final stateWithError = const ChatRoomState().copyWith(
          errorMessage: 'old error',
        );
        final updatedState = stateWithError.copyWith(
          errorMessage: 'new error',
          clearErrorMessage: true,
        );
        // clearErrorMessage takes precedence - it clears to null
        expect(updatedState.errorMessage, isNull);
      });
    });
  });

  group('ChatListStatus', () {
    test('has all expected values', () {
      expect(ChatListStatus.values.length, 4);
      expect(ChatListStatus.values, contains(ChatListStatus.initial));
      expect(ChatListStatus.values, contains(ChatListStatus.loading));
      expect(ChatListStatus.values, contains(ChatListStatus.success));
      expect(ChatListStatus.values, contains(ChatListStatus.failure));
    });
  });

  group('ChatRoomStatus', () {
    test('has all expected values', () {
      expect(ChatRoomStatus.values.length, 4);
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.initial));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.loading));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.success));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.failure));
    });
  });
}
