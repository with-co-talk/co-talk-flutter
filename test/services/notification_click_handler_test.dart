import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:co_talk_flutter/core/services/active_room_tracker.dart';
import 'package:co_talk_flutter/core/services/notification_click_handler.dart';
import 'package:co_talk_flutter/core/services/notification_service.dart';
import 'package:co_talk_flutter/core/router/app_router.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockGoRouter extends Mock implements GoRouter {}

class MockAppRouter extends Mock implements AppRouter {}

class MockActiveRoomTracker extends Mock implements ActiveRoomTracker {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockAppRouter mockAppRouter;
  late MockGoRouter mockRouter;
  late MockActiveRoomTracker mockActiveRoomTracker;
  late NotificationClickHandler handler;
  late StreamController<String?> notificationClickController;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockAppRouter = MockAppRouter();
    mockRouter = MockGoRouter();
    mockActiveRoomTracker = MockActiveRoomTracker();
    notificationClickController = StreamController<String?>.broadcast();

    when(() => mockNotificationService.onNotificationClick)
        .thenAnswer((_) => notificationClickController.stream);
    when(() => mockAppRouter.router).thenReturn(mockRouter);
    when(() => mockActiveRoomTracker.activeRoomId).thenReturn(null);

    handler = NotificationClickHandler(
      notificationService: mockNotificationService,
      appRouter: mockAppRouter,
      activeRoomTracker: mockActiveRoomTracker,
    );
  });

  tearDown(() {
    handler.dispose();
    notificationClickController.close();
  });

  group('NotificationClickHandler', () {
    test('should navigate to chat room when notification payload is chatRoom:123', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('chatRoom:123');

      // then - wait for stream to process
      await Future.delayed(Duration.zero);
      verify(() => mockRouter.go('/chat/room/123')).called(1);
    });

    test('should handle multiple chat room notifications', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('chatRoom:100');
      await Future.delayed(Duration.zero);
      notificationClickController.add('chatRoom:200');
      await Future.delayed(Duration.zero);

      // then
      verify(() => mockRouter.go('/chat/room/100')).called(1);
      verify(() => mockRouter.go('/chat/room/200')).called(1);
    });

    test('should ignore null payload', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add(null);

      // then
      await Future.delayed(Duration.zero);
      verifyNever(() => mockRouter.go(any()));
    });

    test('should ignore empty payload', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('');

      // then
      await Future.delayed(Duration.zero);
      verifyNever(() => mockRouter.go(any()));
    });

    test('should ignore invalid payload format', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('invalidPayload');

      // then
      await Future.delayed(Duration.zero);
      verifyNever(() => mockRouter.go(any()));
    });

    test('should ignore non-numeric room id', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('chatRoom:abc');

      // then
      await Future.delayed(Duration.zero);
      verifyNever(() => mockRouter.go(any()));
    });

    test('should not navigate before startListening is called', () async {
      // given - handler created but not started

      // when
      notificationClickController.add('chatRoom:123');

      // then
      await Future.delayed(Duration.zero);
      verifyNever(() => mockRouter.go(any()));
    });

    test('should stop navigating after stopListening is called', () async {
      // given
      handler.startListening();
      notificationClickController.add('chatRoom:100');
      await Future.delayed(Duration.zero);

      handler.stopListening();

      // when
      notificationClickController.add('chatRoom:200');

      // then
      await Future.delayed(Duration.zero);
      verify(() => mockRouter.go('/chat/room/100')).called(1);
      verifyNever(() => mockRouter.go('/chat/room/200'));
    });

    test('should handle chatRoom:0 as valid room id', () async {
      // given
      handler.startListening();

      // when
      notificationClickController.add('chatRoom:0');

      // then
      await Future.delayed(Duration.zero);
      verify(() => mockRouter.go('/chat/room/0')).called(1);
    });

    test('should not start listening twice', () async {
      // given
      handler.startListening();
      handler.startListening();

      // when
      notificationClickController.add('chatRoom:123');

      // then - should only navigate once, not twice
      await Future.delayed(Duration.zero);
      verify(() => mockRouter.go('/chat/room/123')).called(1);
    });
  });
}
