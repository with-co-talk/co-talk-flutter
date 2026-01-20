import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/chat_list_state.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/fake_entities.dart';

void main() {
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
  });

  group('ChatListBloc', () {
    test('initial state is ChatListState with initial status', () {
      final bloc = ChatListBloc(mockChatRepository);
      expect(bloc.state.status, ChatListStatus.initial);
      expect(bloc.state.chatRooms, isEmpty);
    });

    group('ChatListLoadRequested', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, success] when getChatRooms succeeds',
        build: () {
          when(() => mockChatRepository.getChatRooms()).thenAnswer(
            (_) async => [FakeEntities.directChatRoom, FakeEntities.groupChatRoom],
          );
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom, FakeEntities.groupChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.getChatRooms()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, success] with empty list when no chat rooms',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => []);
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          const ChatListState(status: ChatListStatus.success, chatRooms: []),
        ],
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits [loading, failure] when getChatRooms fails',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenThrow(Exception('Network error'));
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const ChatListLoadRequested()),
        expect: () => [
          const ChatListState(status: ChatListStatus.loading),
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('ChatListRefreshRequested', () {
      blocTest<ChatListBloc, ChatListState>(
        'emits [success] with updated chat rooms on refresh',
        build: () {
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return ChatListBloc(mockChatRepository);
        },
        seed: () => ChatListState(
          status: ChatListStatus.success,
          chatRooms: [FakeEntities.groupChatRoom],
        ),
        act: (bloc) => bloc.add(const ChatListRefreshRequested()),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
          ),
        ],
      );
    });

    group('ChatRoomCreated', () {
      blocTest<ChatListBloc, ChatListState>(
        'creates chat room and refreshes list',
        build: () {
          when(() => mockChatRepository.createDirectChatRoom(any()))
              .thenAnswer((_) async => FakeEntities.directChatRoom);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.directChatRoom]);
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const ChatRoomCreated(2)),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.directChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.createDirectChatRoom(2)).called(1);
          verify(() => mockChatRepository.getChatRooms()).called(1);
        },
      );

      blocTest<ChatListBloc, ChatListState>(
        'emits failure when createDirectChatRoom fails',
        build: () {
          when(() => mockChatRepository.createDirectChatRoom(any()))
              .thenThrow(Exception('Failed to create room'));
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const ChatRoomCreated(2)),
        expect: () => [
          isA<ChatListState>().having(
            (s) => s.status,
            'status',
            ChatListStatus.failure,
          ),
        ],
      );
    });

    group('GroupChatRoomCreated', () {
      blocTest<ChatListBloc, ChatListState>(
        'creates group chat room and refreshes list',
        build: () {
          when(() => mockChatRepository.createGroupChatRoom(any(), any()))
              .thenAnswer((_) async => FakeEntities.groupChatRoom);
          when(() => mockChatRepository.getChatRooms())
              .thenAnswer((_) async => [FakeEntities.groupChatRoom]);
          return ChatListBloc(mockChatRepository);
        },
        act: (bloc) => bloc.add(const GroupChatRoomCreated(
          name: '그룹 채팅방',
          memberIds: [1, 2, 3],
        )),
        expect: () => [
          ChatListState(
            status: ChatListStatus.success,
            chatRooms: [FakeEntities.groupChatRoom],
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.createGroupChatRoom(
                '그룹 채팅방',
                [1, 2, 3],
              )).called(1);
        },
      );
    });
  });
}
