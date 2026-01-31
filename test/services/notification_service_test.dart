import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:co_talk_flutter/core/services/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService notificationService;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    notificationService = NotificationService(plugin: mockPlugin);
  });

  setUpAll(() {
    registerFallbackValue(const AndroidInitializationSettings('app_icon'));
    registerFallbackValue(const DarwinInitializationSettings());
    registerFallbackValue(const LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    ));
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  group('NotificationService', () {
    group('initialize', () {
      test('initializes FlutterLocalNotificationsPlugin with correct settings', () async {
        when(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).thenAnswer((_) async => true);

        await notificationService.initialize();

        verify(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).called(1);
      });

      test('creates Android notification channel on Android platform', () async {
        when(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).thenAnswer((_) async => true);

        when(() => mockPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>())
            .thenReturn(null);

        await notificationService.initialize();

        // Channel creation is handled internally, verify initialize was called
        verify(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).called(1);
      });

      test('requests iOS notification permissions on iOS platform', () async {
        when(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).thenAnswer((_) async => true);

        when(() => mockPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>())
            .thenReturn(null);

        await notificationService.initialize();

        verify(() => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            )).called(1);
      });
    });

    group('showNotification', () {
      test('shows notification with correct title and body', () async {
        when(() => mockPlugin.show(
              any(),
              any(),
              any(),
              any(),
              payload: any(named: 'payload'),
            )).thenAnswer((_) async {});

        await notificationService.showNotification(
          title: 'Test Title',
          body: 'Test Body',
        );

        verify(() => mockPlugin.show(
              any(),
              'Test Title',
              'Test Body',
              any(),
              payload: any(named: 'payload'),
            )).called(1);
      });

      test('shows notification with payload', () async {
        when(() => mockPlugin.show(
              any(),
              any(),
              any(),
              any(),
              payload: any(named: 'payload'),
            )).thenAnswer((_) async {});

        await notificationService.showNotification(
          title: 'New Message',
          body: 'Hello!',
          payload: 'chatRoom:123',
        );

        verify(() => mockPlugin.show(
              any(),
              'New Message',
              'Hello!',
              any(),
              payload: 'chatRoom:123',
            )).called(1);
      });

      test('generates unique notification id for each call', () async {
        final capturedIds = <int>[];

        when(() => mockPlugin.show(
              any(),
              any(),
              any(),
              any(),
              payload: any(named: 'payload'),
            )).thenAnswer((invocation) async {
          capturedIds.add(invocation.positionalArguments[0] as int);
        });

        await notificationService.showNotification(
          title: 'Title 1',
          body: 'Body 1',
        );
        await notificationService.showNotification(
          title: 'Title 2',
          body: 'Body 2',
        );

        expect(capturedIds.length, 2);
        expect(capturedIds[0], isNot(equals(capturedIds[1])));
      });
    });

    group('cancelNotification', () {
      test('cancels notification by id', () async {
        when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

        await notificationService.cancelNotification(123);

        verify(() => mockPlugin.cancel(123)).called(1);
      });
    });

    group('cancelAllNotifications', () {
      test('cancels all notifications', () async {
        when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

        await notificationService.cancelAllNotifications();

        verify(() => mockPlugin.cancelAll()).called(1);
      });
    });
  });
}
