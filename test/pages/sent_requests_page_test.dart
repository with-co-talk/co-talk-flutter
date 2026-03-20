import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/sent_requests_page.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';
import 'package:co_talk_flutter/di/injection.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

FriendRequest makeFriendRequest({
  required int id,
  required User requester,
  required User receiver,
}) {
  return FriendRequest(
    id: id,
    requester: requester,
    receiver: receiver,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockFriendBloc mockFriendBloc;

  setUpAll(() {
    if (!getIt.isRegistered<FriendBloc>()) {
      getIt.registerFactory<FriendBloc>(() => mockFriendBloc);
    }
  });

  setUp(() {
    mockFriendBloc = MockFriendBloc();

    if (getIt.isRegistered<FriendBloc>()) {
      getIt.unregister<FriendBloc>();
    }
    getIt.registerFactory<FriendBloc>(() => mockFriendBloc);
  });

  tearDown(() {
    mockFriendBloc.close();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SentRequestsPage(),
    );
  }

  group('SentRequestsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('보낸 친구 요청'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading and list is empty', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.loading,
          sentRequests: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading indicator when loading with existing requests', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.loading,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows empty state when no sent requests', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.success,
          sentRequests: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.send_outlined), findsOneWidget);
      expect(find.text('보낸 친구 요청이 없습니다'), findsOneWidget);
      expect(find.text('친구를 검색하여 요청을 보내보세요'), findsOneWidget);
    });

    testWidgets('shows error state when error with empty list', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.failure,
          sentRequests: [],
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('보낸 친구 요청을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches SentFriendRequestsLoadRequested on retry tap', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.failure,
          sentRequests: [],
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const SentFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('displays list of sent requests with receiver info', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@test.com'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('bob@test.com'), findsOneWidget);
    });

    testWidgets('shows 대기 중 badge for each sent request', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('대기 중'), findsNWidgets(2));
    });

    testWidgets('shows receiver initial letter in avatar when no avatar URL', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'carol@test.com', nickname: 'Carol', avatarUrl: null),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('dispatches SentFriendRequestsLoadRequested on init', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const SentFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('shows error snackbar when error message changes', (tester) async {
      whenListen(
        mockFriendBloc,
        Stream.fromIterable([
          const FriendState(sentRequests: []),
          const FriendState(
            sentRequests: [],
            errorMessage: 'Network error',
          ),
        ]),
        initialState: const FriendState(sentRequests: []),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.text('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('dispatches SentFriendRequestsLoadRequested on pull-to-refresh', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      verify(() => mockFriendBloc.add(const SentFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('renders ListView with separators when requests exist', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows CircleAvatar for each sent request', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows no accept or reject buttons (sent page is read-only)', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
          receiver: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          sentRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('수락'), findsNothing);
      expect(find.text('거절'), findsNothing);
    });
  });
}
