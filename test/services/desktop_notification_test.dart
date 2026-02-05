import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/services/notification_service.dart';
import 'package:co_talk_flutter/core/services/desktop_notification_bridge.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/core/window/window_focus_tracker.dart';
import 'package:co_talk_flutter/domain/repositories/settings_repository.dart';
import 'package:co_talk_flutter/domain/entities/notification_settings.dart' as entity;

class MockNotificationService extends Mock implements NotificationService {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockWindowFocusTracker extends Mock implements WindowFocusTracker {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockWebSocketService mockWebSocketService;
  late MockWindowFocusTracker mockWindowFocusTracker;
  late MockSettingsRepository mockSettingsRepository;
  late StreamController<WebSocketChatRoomUpdateEvent> chatRoomUpdateController;
  late StreamController<bool> focusController;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockWebSocketService = MockWebSocketService();
    mockWindowFocusTracker = MockWindowFocusTracker();
    mockSettingsRepository = MockSettingsRepository();
    chatRoomUpdateController = StreamController<WebSocketChatRoomUpdateEvent>.broadcast();
    focusController = StreamController<bool>.broadcast();

    when(() => mockWebSocketService.chatRoomUpdates)
        .thenAnswer((_) => chatRoomUpdateController.stream);
    when(() => mockWindowFocusTracker.focusStream)
        .thenAnswer((_) => focusController.stream);
    when(() => mockWindowFocusTracker.currentFocus())
        .thenAnswer((_) async => false);
    when(() => mockNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => mockSettingsRepository.getNotificationSettingsCached())
        .thenAnswer((_) async => const entity.NotificationSettings(
              messageNotification: true,
              friendRequestNotification: true,
              soundEnabled: true,
              vibrationEnabled: true,
            ));
  });

  tearDown(() {
    chatRoomUpdateController.close();
    focusController.close();
  });

  DesktopNotificationBridge createBridge({int? currentUserId}) {
    final bridge = DesktopNotificationBridge(
      notificationService: mockNotificationService,
      webSocketService: mockWebSocketService,
      windowFocusTracker: mockWindowFocusTracker,
      settingsRepository: mockSettingsRepository,
    );
    if (currentUserId != null) {
      bridge.setCurrentUserId(currentUserId);
    }
    return bridge;
  }

  group('Desktop Notification', () {
    group('새 메시지 수신 시', () {
      test('알림을 표시한다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('내가 보낸 메시지는 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'My message',
          senderNickname: 'Me',
          senderId: 1,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });

      test('앱이 포커스 상태이고 해당 채팅방이 열려있으면 알림을 표시하지 않는다', () async {
        when(() => mockWindowFocusTracker.currentFocus())
            .thenAnswer((_) async => true);

        final bridge = createBridge(currentUserId: 1);
        bridge.setActiveRoomId(123);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });

      test('앱이 포커스 상태이지만 다른 채팅방이면 알림을 표시한다', () async {
        when(() => mockWindowFocusTracker.currentFocus())
            .thenAnswer((_) async => true);

        final bridge = createBridge(currentUserId: 1);
        bridge.setActiveRoomId(999);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('앱이 포커스 해제 상태면 채팅방이 열려있어도 알림을 표시한다', () async {
        when(() => mockWindowFocusTracker.currentFocus())
            .thenAnswer((_) async => false);

        final bridge = createBridge(currentUserId: 1);
        bridge.setActiveRoomId(123);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });
    });

    group('엣지케이스 - null 값 처리', () {
      test('senderNickname이 null이면 "새 메시지"를 제목으로 표시한다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: null,
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: '새 메시지',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('lastMessage가 null이면 빈 문자열을 본문으로 표시한다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: null,
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: '',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('senderId가 null이면 알림을 표시한다 (시스템 메시지)', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: '시스템 메시지',
          senderNickname: 'System',
          senderId: null,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'System',
              body: '시스템 메시지',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('currentUserId가 설정되지 않으면 모든 메시지에 알림을 표시한다', () async {
        final bridge = createBridge(); // currentUserId 미설정
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 1,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // currentUserId가 null이므로 senderId와 비교 불가 → 알림 표시
        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('windowFocusTracker.currentFocus()가 null을 반환하면 포커스 해제로 간주하고 알림을 표시한다', () async {
        when(() => mockWindowFocusTracker.currentFocus())
            .thenAnswer((_) async => null);

        final bridge = createBridge(currentUserId: 1);
        bridge.setActiveRoomId(123);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // currentFocus()가 null → false로 간주 → 알림 표시
        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('activeRoomId가 null이면 앱이 포커스여도 알림을 표시한다', () async {
        when(() => mockWindowFocusTracker.currentFocus())
            .thenAnswer((_) async => true);

        final bridge = createBridge(currentUserId: 1);
        // activeRoomId를 설정하지 않음 (null 상태)
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // activeRoomId가 null이므로 chatRoomId와 일치하지 않음 → 알림 표시
        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });
    });

    group('엣지케이스 - 이벤트 타입', () {
      test('READ 이벤트는 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'READ',
          chatRoomId: 123,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });

      test('eventType이 null이면 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: null,
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });

      test('TYPING 이벤트는 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'TYPING',
          chatRoomId: 123,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });
    });

    group('엣지케이스 - 연속 메시지', () {
      test('여러 메시지가 연속으로 오면 각각 알림을 표시한다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'First!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Second!',
          senderNickname: 'Bob',
          senderId: 3,
        ));

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 456,
          lastMessage: 'Third!',
          senderNickname: 'Charlie',
          senderId: 4,
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            )).called(3);

        bridge.dispose();
      });

      test('내 메시지와 다른 사람 메시지가 섞여있으면 다른 사람 메시지만 알림을 표시한다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'From me',
          senderNickname: 'Me',
          senderId: 1, // 내 메시지
        ));

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'From Alice',
          senderNickname: 'Alice',
          senderId: 2, // 다른 사람
        ));

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'From me again',
          senderNickname: 'Me',
          senderId: 1, // 내 메시지
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // 다른 사람 메시지 1개만 알림 표시
        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'From Alice',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });
    });

    group('엣지케이스 - 리스닝 상태', () {
      test('startListening을 여러 번 호출해도 중복 구독되지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);

        bridge.startListening();
        bridge.startListening();
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // 중복 구독이 없으므로 알림은 1번만 표시
        verify(() => mockNotificationService.showNotification(
              title: 'Alice',
              body: 'Hello!',
              payload: any(named: 'payload'),
            )).called(1);

        bridge.dispose();
      });

      test('stopListening 후에는 메시지가 와도 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();
        bridge.stopListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });

      test('dispose 후에는 메시지가 와도 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();
        bridge.dispose();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));
      });

      test('startListening 전에는 메시지가 와도 알림을 표시하지 않는다', () async {
        final bridge = createBridge(currentUserId: 1);
        // startListening 호출 안 함

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 123,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));

        bridge.dispose();
      });
    });

    group('payload 검증', () {
      test('payload에 chatRoomId가 포함된다', () async {
        String? capturedPayload;
        when(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            )).thenAnswer((invocation) async {
          capturedPayload = invocation.namedArguments[#payload] as String?;
        });

        final bridge = createBridge(currentUserId: 1);
        bridge.startListening();

        chatRoomUpdateController.add(WebSocketChatRoomUpdateEvent(
          eventType: 'NEW_MESSAGE',
          chatRoomId: 12345,
          lastMessage: 'Hello!',
          senderNickname: 'Alice',
          senderId: 2,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(capturedPayload, 'chatRoom:12345');

        bridge.dispose();
      });
    });

    group('상태 관리', () {
      test('setActiveRoomId로 현재 채팅방 설정', () async {
        final bridge = createBridge(currentUserId: 1);

        bridge.setActiveRoomId(123);
        expect(bridge.activeRoomId, 123);

        bridge.setActiveRoomId(null);
        expect(bridge.activeRoomId, isNull);

        bridge.dispose();
      });

      test('setCurrentUserId로 현재 사용자 ID 설정', () async {
        final bridge = createBridge();

        expect(bridge.currentUserId, isNull);

        bridge.setCurrentUserId(42);
        expect(bridge.currentUserId, 42);

        bridge.setCurrentUserId(null);
        expect(bridge.currentUserId, isNull);

        bridge.dispose();
      });
    });
  });
}
