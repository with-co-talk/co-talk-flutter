import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_event.dart';
import 'package:co_talk_flutter/presentation/blocs/friend/friend_state.dart';
import 'package:co_talk_flutter/presentation/pages/friends/received_requests_page.dart';
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
      home: ReceivedRequestsPage(),
    );
  }

  group('ReceivedRequestsPage', () {
    testWidgets('renders app bar with title', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('받은 친구 요청'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading and list is empty', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.loading,
          receivedRequests: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading indicator when loading with existing requests', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'a@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.loading,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows empty state when no received requests', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.success,
          receivedRequests: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('받은 친구 요청이 없습니다'), findsOneWidget);
      expect(find.text('다른 사용자가 친구 요청을 보내면 여기에 표시됩니다'), findsOneWidget);
    });

    testWidgets('shows error state when error with empty list', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.failure,
          receivedRequests: [],
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('받은 친구 요청을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('dispatches ReceivedFriendRequestsLoadRequested on retry tap', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(
        const FriendState(
          status: FriendStatus.failure,
          receivedRequests: [],
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const ReceivedFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('displays list of received requests', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@test.com'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('bob@test.com'), findsOneWidget);
    });

    testWidgets('shows accept and reject buttons for each request', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('수락'), findsNWidgets(2));
      expect(find.text('거절'), findsNWidgets(2));
    });

    testWidgets('dispatches FriendRequestAccepted when accept button tapped', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 42,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('수락'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const FriendRequestAccepted(42))).called(1);
    });

    testWidgets('dispatches FriendRequestRejected when reject button tapped', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 42,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.tap(find.text('거절'));
      await tester.pump();

      verify(() => mockFriendBloc.add(const FriendRequestRejected(42))).called(1);
    });

    testWidgets('shows requester initial letter in avatar when no avatar URL', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice', avatarUrl: null),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('dispatches ReceivedFriendRequestsLoadRequested on init', (tester) async {
      when(() => mockFriendBloc.state).thenReturn(const FriendState());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockFriendBloc.add(const ReceivedFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('shows error snackbar when error message changes', (tester) async {
      whenListen(
        mockFriendBloc,
        Stream.fromIterable([
          const FriendState(receivedRequests: []),
          const FriendState(
            receivedRequests: [],
            errorMessage: 'Network error',
          ),
        ]),
        initialState: const FriendState(receivedRequests: []),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.text('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('dispatches ReceivedFriendRequestsLoadRequested on pull-to-refresh', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      clearInteractions(mockFriendBloc);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      verify(() => mockFriendBloc.add(const ReceivedFriendRequestsLoadRequested())).called(1);
    });

    testWidgets('renders ListView with separators when requests exist', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
        makeFriendRequest(
          id: 2,
          requester: const User(id: 11, email: 'bob@test.com', nickname: 'Bob'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows CircleAvatar for each request', (tester) async {
      final requests = [
        makeFriendRequest(
          id: 1,
          requester: const User(id: 10, email: 'alice@test.com', nickname: 'Alice'),
          receiver: const User(id: 99, email: 'me@test.com', nickname: 'Me'),
        ),
      ];

      when(() => mockFriendBloc.state).thenReturn(
        FriendState(
          status: FriendStatus.success,
          receivedRequests: requests,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
