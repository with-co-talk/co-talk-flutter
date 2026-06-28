import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/received_requests_page.dart';
import 'package:co_talk_flutter/presentation/widgets/gradient_button.dart';
import 'package:co_talk_flutter/di/injection.dart';
import '../mocks/fake_entities.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

void main() {
  late MockFriendBloc mockFriendBloc;

  setUp(() {
    mockFriendBloc = MockFriendBloc();
    if (getIt.isRegistered<FriendBloc>()) {
      getIt.unregister<FriendBloc>();
    }
    getIt.registerFactory<FriendBloc>(() => mockFriendBloc);
  });

  tearDown(() {
    if (getIt.isRegistered<FriendBloc>()) {
      getIt.unregister<FriendBloc>();
    }
  });

  Widget createWidget() {
    return MaterialApp(
      home: const ReceivedRequestsPage(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  // Warm Sand 리뉴얼: 수락 버튼이 ElevatedButton -> GradientButton 으로 변경됐다.
  // 거절은 그대로 OutlinedButton. 처리 중 비활성화/스피너 동작은 유지된다.
  GradientButton acceptButton(WidgetTester tester) =>
      tester.widget<GradientButton>(find.byType(GradientButton));
  OutlinedButton rejectButton(WidgetTester tester) =>
      tester.widget<OutlinedButton>(find.byType(OutlinedButton));

  testWidgets('accept/reject enabled when request is not processing',
      (tester) async {
    when(() => mockFriendBloc.state).thenReturn(
      FriendState(
        receivedRequests: FakeEntities.receivedFriendRequests,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    expect(acceptButton(tester).onPressed, isNotNull);
    expect(rejectButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'accept/reject disabled and spinner shown while request is in flight '
      '(P3 double-tap guard)', (tester) async {
    final request = FakeEntities.receivedFriendRequests.first;
    when(() => mockFriendBloc.state).thenReturn(
      FriendState(
        receivedRequests: FakeEntities.receivedFriendRequests,
        processingRequestIds: {request.id},
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    // Both buttons disabled so a second tap cannot fire a duplicate event.
    expect(acceptButton(tester).onPressed, isNull);
    expect(rejectButton(tester).onPressed, isNull);
    // Accept button shows an in-flight spinner instead of the label.
    expect(
      find.descendant(
        of: find.byType(GradientButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });
}
