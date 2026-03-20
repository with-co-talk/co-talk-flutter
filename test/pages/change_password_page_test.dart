import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_event.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/change_password_state.dart';
import 'package:co_talk_flutter/presentation/pages/settings/change_password_page.dart';

class MockChangePasswordBloc extends Mock implements ChangePasswordBloc {}

class FakeChangePasswordEvent extends Fake implements ChangePasswordEvent {}

void main() {
  late MockChangePasswordBloc mockBloc;
  late StreamController<ChangePasswordState> stateController;

  setUpAll(() {
    registerFallbackValue(FakeChangePasswordEvent());
  });

  setUp(() {
    mockBloc = MockChangePasswordBloc();
    stateController = StreamController<ChangePasswordState>.broadcast();
    when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => mockBloc.isClosed).thenReturn(false);
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    stateController.close();
  });

  Widget createWidgetUnderTest({ChangePasswordState? initialState}) {
    final state = initialState ?? const ChangePasswordState.initial();
    when(() => mockBloc.state).thenReturn(state);

    final router = GoRouter(
      initialLocation: '/change-password',
      routes: [
        GoRoute(
          path: '/change-password',
          builder: (context, routerState) =>
              BlocProvider<ChangePasswordBloc>.value(
            value: mockBloc,
            child: const ChangePasswordPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, routerState) =>
              const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('ChangePasswordPage', () {
    testWidgets('앱바 타이틀 "비밀번호 변경"을 렌더링한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // AppBar title + ElevatedButton text = 2 occurrences
      expect(find.text('비밀번호 변경'), findsNWidgets(2));
    });

    testWidgets('현재 비밀번호 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('현재 비밀번호'), findsOneWidget);
    });

    testWidgets('새 비밀번호 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('새 비밀번호'), findsOneWidget);
    });

    testWidgets('새 비밀번호 확인 필드를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('새 비밀번호 확인'), findsOneWidget);
    });

    testWidgets('비밀번호 요구사항 섹션을 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('비밀번호 요구 사항'), findsOneWidget);
      expect(find.text('최소 8자 이상'), findsOneWidget);
      expect(find.text('영문 대/소문자 포함'), findsOneWidget);
      expect(find.text('숫자 포함'), findsOneWidget);
      expect(find.text('특수문자 포함'), findsOneWidget);
    });

    testWidgets('세 개의 TextFormField가 있다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('initial 상태에서 제출 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('loading 상태에서 제출 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ChangePasswordState.loading(),
      ));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading 상태에서 CircularProgressIndicator를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const ChangePasswordState.loading(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('현재 비밀번호 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('현재 비밀번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('새 비밀번호 없이 제출하면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPassword1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('새 비밀번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('새 비밀번호가 8자 미만이면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPassword1');
      await tester.enterText(fields.at(1), 'abc1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('비밀번호는 8자 이상이어야 합니다'), findsOneWidget);
    });

    testWidgets('새 비밀번호에 영문과 숫자가 없으면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPassword1');
      await tester.enterText(fields.at(1), 'abcdefgh');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('영문과 숫자를 포함해야 합니다'), findsOneWidget);
    });

    testWidgets('비밀번호 확인이 일치하지 않으면 유효성 검사 오류를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPassword1');
      await tester.enterText(fields.at(1), 'newPassword1');
      await tester.enterText(fields.at(2), 'differentPassword1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    });

    testWidgets('모든 필드 유효 시 ChangePasswordSubmitted 이벤트를 디스패치한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPassword1');
      await tester.enterText(fields.at(1), 'newPassword1');
      await tester.enterText(fields.at(2), 'newPassword1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => mockBloc.add(
            const ChangePasswordSubmitted(
              currentPassword: 'currentPassword1',
              newPassword: 'newPassword1',
            ),
          )).called(1);
    });

    testWidgets('success 상태에서 성공 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final successState = const ChangePasswordState.success();
      when(() => mockBloc.state).thenReturn(successState);
      stateController.add(successState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('비밀번호가 성공적으로 변경되었습니다.'), findsOneWidget);
    });

    testWidgets('error 상태에서 에러 SnackBar를 표시한다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final errorState =
          const ChangePasswordState.error('현재 비밀번호가 올바르지 않습니다');
      when(() => mockBloc.state).thenReturn(errorState);
      stateController.add(errorState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('현재 비밀번호가 올바르지 않습니다'), findsOneWidget);
    });

    testWidgets('비밀번호 가시성 토글 버튼이 각 필드마다 있다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 3 password fields × 1 IconButton each + 1 back button in AppBar
      expect(find.byType(IconButton), findsNWidgets(4));
    });

    testWidgets('현재 비밀번호 필드의 가시성 토글 버튼을 탭하면 아이콘이 변경된다', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Initially all 3 password fields have visibility_off icons
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(3));

      // Tap the first visibility toggle (first password field)
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
