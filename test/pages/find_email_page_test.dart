import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/find_email_bloc.dart';
import 'package:co_talk_flutter/presentation/pages/auth/find_email_page.dart';

class MockFindEmailBloc extends Mock implements FindEmailBloc {}

class FakeFindEmailEvent extends Fake implements FindEmailEvent {}

void main() {
  late MockFindEmailBloc mockBloc;
  late StreamController<FindEmailState> stateController;

  setUpAll(() {
    registerFallbackValue(FakeFindEmailEvent());
  });

  setUp(() {
    mockBloc = MockFindEmailBloc();
    stateController = StreamController<FindEmailState>.broadcast();
    when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => mockBloc.isClosed).thenReturn(false);
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    stateController.close();
  });

  Widget createWidgetUnderTest({FindEmailState? initialState}) {
    final state = initialState ?? const FindEmailState();
    when(() => mockBloc.state).thenReturn(state);

    final router = GoRouter(
      initialLocation: '/find-email',
      routes: [
        GoRoute(
          path: '/find-email',
          builder: (context, routerState) =>
              BlocProvider<FindEmailBloc>.value(
            value: mockBloc,
            child: const FindEmailPage(),
          ),
        ),
        GoRoute(
          path: '/find-email/result',
          builder: (context, routerState) =>
              const Scaffold(body: Text('Result')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, routerState) =>
              const Scaffold(body: Text('Login')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('FindEmailPage', () {
    testWidgets('앱바 타이틀 "아이디 찾기"를 렌더링한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('아이디 찾기'), findsOneWidget);
    });

    testWidgets('닉네임 입력 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('닉네임'), findsOneWidget);
    });

    testWidgets('전화번호 입력 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('전화번호'), findsOneWidget);
    });

    testWidgets('"이메일 찾기" 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('이메일 찾기'), findsOneWidget);
    });

    testWidgets('닉네임과 전화번호 두 개의 TextFormField가 있다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('initial 상태에서 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('loading 상태에서 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const FindEmailState(status: FindEmailStatus.loading),
      ));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading 상태에서 CircularProgressIndicator를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const FindEmailState(status: FindEmailStatus.loading),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('닉네임 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('이메일 찾기'));
      await tester.pump();

      expect(find.text('닉네임을 입력해주세요'), findsOneWidget);
    });

    testWidgets('전화번호 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '테스트닉네임');
      await tester.tap(find.text('이메일 찾기'));
      await tester.pump();

      expect(find.text('전화번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('닉네임과 전화번호 입력 후 버튼 탭 시 FindEmailRequested 이벤트를 디스패치한다',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '테스트닉네임');
      await tester.enterText(fields.at(1), '010-1234-5678');
      await tester.tap(find.text('이메일 찾기'));
      await tester.pump();

      verify(() => mockBloc.add(
            FindEmailRequested(
              nickname: '테스트닉네임',
              phoneNumber: '010-1234-5678',
            ),
          )).called(1);
    });

    testWidgets('notFound 상태에서 에러 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final notFoundState = const FindEmailState(
        status: FindEmailStatus.notFound,
        message: '일치하는 계정을 찾을 수 없습니다.',
      );
      when(() => mockBloc.state).thenReturn(notFoundState);
      stateController.add(notFoundState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('일치하는 계정을 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('failure 상태에서 에러 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final failureState = const FindEmailState(
        status: FindEmailStatus.failure,
        errorMessage: '네트워크 오류가 발생했습니다',
      );
      when(() => mockBloc.state).thenReturn(failureState);
      stateController.add(failureState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('네트워크 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('안내 문구를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.textContaining('닉네임과 전화번호를'),
        findsOneWidget,
      );
    });

    testWidgets('전화번호 힌트 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('010-1234-5678'), findsOneWidget);
    });
  });
}
