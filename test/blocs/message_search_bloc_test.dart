import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_state.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
  });

  MessageSearchBloc createBloc() => MessageSearchBloc(mockChatRepository);

  final testMessages = [
    Message(
      id: 1,
      chatRoomId: 1,
      senderId: 1,
      content: '안녕하세요',
      createdAt: DateTime(2024, 1, 1),
    ),
    Message(
      id: 2,
      chatRoomId: 1,
      senderId: 2,
      content: '안녕하세요 반갑습니다',
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  group('MessageSearchBloc', () {
    test('initial state is MessageSearchState with initial status', () {
      final bloc = createBloc();
      expect(bloc.state.status, MessageSearchStatus.initial);
      expect(bloc.state.query, '');
      expect(bloc.state.results, isEmpty);
      expect(bloc.state.chatRoomId, isNull);
    });

    group('MessageSearchQueryChanged', () {
      blocTest<MessageSearchBloc, MessageSearchState>(
        '빈 쿼리는 초기 상태로 리셋함',
        build: () => createBloc(),
        seed: () => const MessageSearchState(
          query: '이전 쿼리',
          status: MessageSearchStatus.success,
        ),
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '')),
        expect: () => [
          const MessageSearchState(),
        ],
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        '공백만 있는 쿼리는 초기 상태로 리셋함',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '   ')),
        expect: () => [
          const MessageSearchState(),
        ],
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        '2글자 미만 쿼리는 검색하지 않고 쿼리만 저장함',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '안')),
        expect: () => [
          const MessageSearchState(
            query: '안',
            status: MessageSearchStatus.initial,
            results: [],
          ),
        ],
        verify: (_) {
          verifyNever(() => mockChatRepository.searchMessages(
                any(),
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              ));
        },
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        '2글자 이상 쿼리는 loading 상태로 전환 후 검색 실행',
        build: () {
          when(() => mockChatRepository.searchMessages(
                any(),
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => testMessages);
          return createBloc();
        },
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '안녕')),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          const MessageSearchState(
            query: '안녕',
            status: MessageSearchStatus.loading,
          ),
          MessageSearchState(
            query: '안녕',
            status: MessageSearchStatus.success,
            results: testMessages,
          ),
        ],
        verify: (_) {
          verify(() => mockChatRepository.searchMessages(
                '안녕',
                chatRoomId: null,
                limit: 50,
              )).called(1);
        },
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        'chatRoomId를 필터로 전달함',
        build: () {
          when(() => mockChatRepository.searchMessages(
                any(),
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => testMessages);
          return createBloc();
        },
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '검색어', chatRoomId: 5)),
        wait: const Duration(milliseconds: 400),
        verify: (_) {
          verify(() => mockChatRepository.searchMessages(
                '검색어',
                chatRoomId: 5,
                limit: 50,
              )).called(1);
        },
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        '검색 실패 시 failure 상태로 전환',
        build: () {
          when(() => mockChatRepository.searchMessages(
                any(),
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              )).thenThrow(Exception('검색 실패'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const MessageSearchQueryChanged(query: '테스트')),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          const MessageSearchState(
            query: '테스트',
            status: MessageSearchStatus.loading,
          ),
          isA<MessageSearchState>()
              .having((s) => s.status, 'status', MessageSearchStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<MessageSearchBloc, MessageSearchState>(
        'debounce 동안 새 쿼리가 들어오면 이전 검색은 취소됨',
        build: () {
          when(() => mockChatRepository.searchMessages(
                any(),
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => testMessages);
          return createBloc();
        },
        act: (bloc) async {
          bloc.add(const MessageSearchQueryChanged(query: '첫번째'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const MessageSearchQueryChanged(query: '두번째'));
        },
        wait: const Duration(milliseconds: 500),
        expect: () => [
          // debounce로 인해 마지막 이벤트만 처리됨
          const MessageSearchState(
            query: '두번째',
            status: MessageSearchStatus.loading,
          ),
          MessageSearchState(
            query: '두번째',
            status: MessageSearchStatus.success,
            results: testMessages,
          ),
        ],
        verify: (_) {
          // 첫번째 검색은 debounce로 인해 취소되고 두번째만 실행
          verify(() => mockChatRepository.searchMessages(
                '두번째',
                chatRoomId: null,
                limit: 50,
              )).called(1);
          verifyNever(() => mockChatRepository.searchMessages(
                '첫번째',
                chatRoomId: any(named: 'chatRoomId'),
                limit: any(named: 'limit'),
              ));
        },
      );
    });

    group('MessageSearchCleared', () {
      blocTest<MessageSearchBloc, MessageSearchState>(
        '검색 상태를 초기화함',
        build: () => createBloc(),
        seed: () => MessageSearchState(
          query: '검색어',
          status: MessageSearchStatus.success,
          results: testMessages,
          chatRoomId: 1,
        ),
        act: (bloc) => bloc.add(const MessageSearchCleared()),
        expect: () => [
          const MessageSearchState(),
        ],
      );
    });

    group('MessageSearchResultSelected', () {
      blocTest<MessageSearchBloc, MessageSearchState>(
        '선택한 메시지 ID를 저장함',
        build: () => createBloc(),
        seed: () => MessageSearchState(
          query: '검색어',
          status: MessageSearchStatus.success,
          results: testMessages,
        ),
        act: (bloc) => bloc.add(const MessageSearchResultSelected(
          messageId: 1,
          chatRoomId: 1,
        )),
        expect: () => [
          MessageSearchState(
            query: '검색어',
            status: MessageSearchStatus.success,
            results: testMessages,
            selectedMessageId: 1,
          ),
        ],
      );
    });

    group('MessageSearchState', () {
      test('hasResults는 결과가 있을 때 true 반환', () {
        final state = MessageSearchState(results: testMessages);
        expect(state.hasResults, isTrue);
      });

      test('hasResults는 결과가 없을 때 false 반환', () {
        const state = MessageSearchState(results: []);
        expect(state.hasResults, isFalse);
      });

      test('isSearching은 loading 상태일 때 true 반환', () {
        const state = MessageSearchState(status: MessageSearchStatus.loading);
        expect(state.isSearching, isTrue);
      });

      test('isSearching은 loading 아닐 때 false 반환', () {
        const state = MessageSearchState(status: MessageSearchStatus.success);
        expect(state.isSearching, isFalse);
      });

      test('hasQuery는 쿼리가 있을 때 true 반환', () {
        const state = MessageSearchState(query: '검색어');
        expect(state.hasQuery, isTrue);
      });

      test('hasQuery는 빈 쿼리일 때 false 반환', () {
        const state = MessageSearchState(query: '');
        expect(state.hasQuery, isFalse);
      });

      test('hasQuery는 공백만 있을 때 false 반환', () {
        const state = MessageSearchState(query: '   ');
        expect(state.hasQuery, isFalse);
      });
    });

    group('MessageSearchEvent props', () {
      test('MessageSearchQueryChanged props', () {
        const event = MessageSearchQueryChanged(query: 'test', chatRoomId: 1);
        expect(event.props, ['test', 1]);
      });

      test('MessageSearchCleared props', () {
        const event = MessageSearchCleared();
        expect(event.props, isEmpty);
      });

      test('MessageSearchResultSelected props', () {
        const event = MessageSearchResultSelected(messageId: 1, chatRoomId: 2);
        expect(event.props, [1, 2]);
      });
    });
  });
}
