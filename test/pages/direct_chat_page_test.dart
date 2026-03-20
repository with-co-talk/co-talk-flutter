import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/di/injection.dart';
import 'package:co_talk_flutter/domain/entities/chat_room.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/presentation/pages/chat/direct_chat_page.dart';
import '../mocks/mock_repositories.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockChatRepository mockChatRepository;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockChatRepository = MockChatRepository();

    getIt.reset();
    getIt.registerLazySingleton<ChatRepository>(() => mockChatRepository);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const User(id: 1, email: 'me@example.com', nickname: 'Me'),
      ),
    );
  });

  tearDown(() => getIt.reset());

  Widget createWidgetUnderTest({
    int targetUserId = 2,
    bool isSelfChat = false,
  }) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: DirectChatPage(
          targetUserId: targetUserId,
          isSelfChat: isSelfChat,
        ),
      ),
    );
  }

  group('DirectChatPage', () {
    testWidgets('Scaffold와 AppBar가 렌더링된다', (tester) async {
      when(() => mockChatRepository.createDirectChatRoom(any()))
          .thenAnswer((_) => Completer<ChatRoom>().future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('createDirectChatRoom 실패 시 에러 상태를 표시한다', (tester) async {
      when(() => mockChatRepository.createDirectChatRoom(any()))
          .thenThrow(Exception('네트워크 오류'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('에러 상태에서 다시 시도 버튼을 표시한다', (tester) async {
      when(() => mockChatRepository.createDirectChatRoom(any()))
          .thenThrow(Exception('네트워크 오류'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('에러 메시지를 표시한다', (tester) async {
      when(() => mockChatRepository.createDirectChatRoom(any()))
          .thenThrow(Exception('네트워크 오류'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('채팅방을 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('isSelfChat=false일 때 타이틀이 1:1 채팅으로 표시된다',
        (tester) async {
      when(() => mockChatRepository.createDirectChatRoom(any()))
          .thenAnswer((_) => Completer<ChatRoom>().future);

      await tester.pumpWidget(
        createWidgetUnderTest(targetUserId: 2, isSelfChat: false),
      );
      await tester.pump();

      expect(find.text('1:1 채팅'), findsOneWidget);
    });

  });
}
