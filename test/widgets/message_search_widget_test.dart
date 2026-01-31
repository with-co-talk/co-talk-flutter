import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_event.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/message_search/message_search_state.dart';
import 'package:co_talk_flutter/presentation/widgets/message_search_widget.dart';

class MockMessageSearchBloc extends Mock implements MessageSearchBloc {}

void main() {
  late MockMessageSearchBloc mockMessageSearchBloc;

  setUp(() {
    mockMessageSearchBloc = MockMessageSearchBloc();
  });

  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    registerFallbackValue(const MessageSearchQueryChanged(query: ''));
    registerFallbackValue(const MessageSearchCleared());
  });

  Widget createWidgetUnderTest({MessageSearchState? initialState}) {
    when(() => mockMessageSearchBloc.state)
        .thenReturn(initialState ?? const MessageSearchState());
    when(() => mockMessageSearchBloc.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockMessageSearchBloc.close()).thenAnswer((_) async {});

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<MessageSearchBloc>.value(
          value: mockMessageSearchBloc,
          child: MessageSearchWidget(
            chatRoomId: 1,
            onMessageSelected: (messageId) {},
          ),
        ),
      ),
    );
  }

  final testMessages = [
    Message(
      id: 1,
      chatRoomId: 1,
      senderId: 1,
      senderNickname: '홍길동',
      content: '안녕하세요',
      createdAt: DateTime(2024, 1, 1, 10, 30),
    ),
    Message(
      id: 2,
      chatRoomId: 1,
      senderId: 2,
      senderNickname: '김철수',
      content: '안녕하세요 반갑습니다',
      createdAt: DateTime(2024, 1, 1, 10, 31),
    ),
  ];

  group('MessageSearchWidget', () {
    testWidgets('검색 입력 필드를 렌더링함', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextField), findsOneWidget);
      // 초기 상태에서 검색 아이콘 2개: TextField prefixIcon + 빈 상태 뷰
      expect(find.byIcon(Icons.search), findsNWidgets(2));
    });

    testWidgets('텍스트 입력 시 MessageSearchQueryChanged 이벤트 발생', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), '안녕');
      await tester.pump();

      verify(() => mockMessageSearchBloc.add(
            const MessageSearchQueryChanged(query: '안녕', chatRoomId: 1),
          )).called(1);
    });

    testWidgets('로딩 상태일 때 로딩 인디케이터 표시', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const MessageSearchState(
          status: MessageSearchStatus.loading,
          query: '검색중',
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('검색 결과가 있을 때 결과 목록 표시', (tester) async {
      when(() => mockMessageSearchBloc.state).thenReturn(MessageSearchState(
        status: MessageSearchStatus.success,
        query: '안녕',
        results: testMessages,
      ));
      when(() => mockMessageSearchBloc.stream).thenAnswer(
        (_) => Stream.value(MessageSearchState(
          status: MessageSearchStatus.success,
          query: '안녕',
          results: testMessages,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest(
        initialState: MessageSearchState(
          status: MessageSearchStatus.success,
          query: '안녕',
          results: testMessages,
        ),
      ));
      await tester.pump();

      // 발신자 이름은 일반 Text로 표시됨
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
      // 메시지 내용은 RichText(하이라이트)로 표시되므로 Card 개수로 확인
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('검색 결과가 없을 때 빈 결과 메시지 표시', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const MessageSearchState(
          status: MessageSearchStatus.success,
          query: '없는검색어',
          results: [],
        ),
      ));

      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    });

    testWidgets('검색 결과 탭 시 onMessageSelected 콜백 호출', (tester) async {
      int? selectedMessageId;

      when(() => mockMessageSearchBloc.state).thenReturn(MessageSearchState(
        status: MessageSearchStatus.success,
        query: '안녕',
        results: testMessages,
      ));
      when(() => mockMessageSearchBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider<MessageSearchBloc>.value(
            value: mockMessageSearchBloc,
            child: MessageSearchWidget(
              chatRoomId: 1,
              onMessageSelected: (messageId) {
                selectedMessageId = messageId;
              },
            ),
          ),
        ),
      ));
      await tester.pump();

      // 첫 번째 검색 결과 Card 탭
      await tester.tap(find.byType(Card).first);
      await tester.pump();

      expect(selectedMessageId, 1);
    });

    testWidgets('X 버튼 탭 시 검색 초기화', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const MessageSearchState(
          status: MessageSearchStatus.success,
          query: '검색어',
        ),
      ));

      // 클리어 버튼 찾기 (X 아이콘)
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();

      verify(() => mockMessageSearchBloc.add(const MessageSearchCleared()))
          .called(1);
    });

    testWidgets('에러 상태일 때 에러 메시지 표시', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const MessageSearchState(
          status: MessageSearchStatus.failure,
          query: '검색어',
          errorMessage: '검색 중 오류가 발생했습니다',
        ),
      ));

      expect(find.text('검색 중 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('초기 상태에서 힌트 텍스트 표시', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('메시지 검색'), findsOneWidget);
    });
  });
}
