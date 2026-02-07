import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:co_talk_flutter/core/services/active_room_tracker.dart';
import 'package:co_talk_flutter/core/services/fcm_service.dart';
import 'package:co_talk_flutter/core/services/notification_service.dart';
import 'package:co_talk_flutter/domain/repositories/settings_repository.dart';
import 'package:co_talk_flutter/domain/entities/notification_settings.dart' as entity;

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockNotificationService extends Mock implements NotificationService {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockActiveRoomTracker extends Mock implements ActiveRoomTracker {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late MockNotificationService mockNotificationService;
  late MockSettingsRepository mockSettingsRepository;
  late MockActiveRoomTracker mockActiveRoomTracker;
  late FcmServiceImpl fcmService;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockNotificationService = MockNotificationService();
    mockSettingsRepository = MockSettingsRepository();
    mockActiveRoomTracker = MockActiveRoomTracker();

    // Mock onTokenRefresh stream for constructor
    when(() => mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());
    when(() => mockSettingsRepository.getNotificationSettingsCached())
        .thenAnswer((_) async => const entity.NotificationSettings(
              messageNotification: true,
              friendRequestNotification: true,
              soundEnabled: true,
              vibrationEnabled: true,
            ));
    when(() => mockActiveRoomTracker.activeRoomId).thenReturn(null);

    fcmService = FcmServiceImpl(
      messaging: mockMessaging,
      notificationService: mockNotificationService,
      settingsRepository: mockSettingsRepository,
      activeRoomTracker: mockActiveRoomTracker,
    );
  });

  setUpAll(() {
    registerFallbackValue(const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      badge: AppleNotificationSetting.enabled,
      sound: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      carPlay: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    ));
  });

  group('FcmServiceImpl', () {
    group('initialize', () {
      // Note: initialize() checks for mobile platform (Android/iOS) and returns early on desktop
      // These tests verify the behavior when running on mobile platforms
      // Skip on desktop as initialize() exits early due to platform check
      test('requests notification permission', skip: 'FCM initialization only runs on mobile platforms', () async {
        when(() => mockMessaging.requestPermission(
              alert: any(named: 'alert'),
              badge: any(named: 'badge'),
              sound: any(named: 'sound'),
            )).thenAnswer((_) async => const NotificationSettings(
              authorizationStatus: AuthorizationStatus.authorized,
              alert: AppleNotificationSetting.enabled,
              badge: AppleNotificationSetting.enabled,
              sound: AppleNotificationSetting.enabled,
              announcement: AppleNotificationSetting.notSupported,
              carPlay: AppleNotificationSetting.notSupported,
              criticalAlert: AppleNotificationSetting.notSupported,
              lockScreen: AppleNotificationSetting.enabled,
              notificationCenter: AppleNotificationSetting.enabled,
              showPreviews: AppleShowPreviewSetting.always,
              timeSensitive: AppleNotificationSetting.notSupported,
              providesAppNotificationSettings: AppleNotificationSetting.notSupported,
            ));

        when(() => mockMessaging.getToken()).thenAnswer((_) async => 'test_token');
        when(() => mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());

        await fcmService.initialize();

        verify(() => mockMessaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            )).called(1);
      });

      test('gets initial FCM token after permission granted', skip: 'FCM initialization only runs on mobile platforms', () async {
        when(() => mockMessaging.requestPermission(
              alert: any(named: 'alert'),
              badge: any(named: 'badge'),
              sound: any(named: 'sound'),
            )).thenAnswer((_) async => const NotificationSettings(
              authorizationStatus: AuthorizationStatus.authorized,
              alert: AppleNotificationSetting.enabled,
              badge: AppleNotificationSetting.enabled,
              sound: AppleNotificationSetting.enabled,
              announcement: AppleNotificationSetting.notSupported,
              carPlay: AppleNotificationSetting.notSupported,
              criticalAlert: AppleNotificationSetting.notSupported,
              lockScreen: AppleNotificationSetting.enabled,
              notificationCenter: AppleNotificationSetting.enabled,
              showPreviews: AppleShowPreviewSetting.always,
              timeSensitive: AppleNotificationSetting.notSupported,
              providesAppNotificationSettings: AppleNotificationSetting.notSupported,
            ));

        when(() => mockMessaging.getToken()).thenAnswer((_) async => 'test_fcm_token');
        when(() => mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());

        await fcmService.initialize();

        verify(() => mockMessaging.getToken()).called(1);
      });
    });

    group('getToken', () {
      test('returns FCM token', () async {
        when(() => mockMessaging.getToken()).thenAnswer((_) async => 'test_fcm_token');

        final token = await fcmService.getToken();

        expect(token, 'test_fcm_token');
      });

      test('returns null when token retrieval fails', () async {
        when(() => mockMessaging.getToken()).thenThrow(Exception('Failed'));

        final token = await fcmService.getToken();

        expect(token, isNull);
      });
    });

    group('deleteToken', () {
      test('deletes FCM token', () async {
        when(() => mockMessaging.deleteToken()).thenAnswer((_) async {});

        await fcmService.deleteToken();

        verify(() => mockMessaging.deleteToken()).called(1);
      });
    });

    group('onTokenRefresh', () {
      test('emits new token when token is refreshed', () async {
        final tokenController = StreamController<String>();

        when(() => mockMessaging.onTokenRefresh)
            .thenAnswer((_) => tokenController.stream);

        final tokenStream = fcmService.onTokenRefresh;

        expectLater(
          tokenStream,
          emitsInOrder(['new_token_1', 'new_token_2']),
        );

        tokenController.add('new_token_1');
        tokenController.add('new_token_2');

        await tokenController.close();
      });
    });

    group('foreground message handling', () {
      test('shows local notification when foreground message received', () async {
        when(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            )).thenAnswer((_) async {});

        // Simulate foreground message
        fcmService.handleForegroundMessage(const RemoteMessage(
          notification: RemoteNotification(
            title: 'New Message',
            body: 'Hello from FCM!',
          ),
          data: {'chatRoomId': '123'},
        ));

        // Wait for the async _handleForegroundMessageAsync to complete
        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNotificationService.showNotification(
              title: 'New Message',
              body: 'Hello from FCM!',
              payload: any(named: 'payload'),
            )).called(1);
      });

      test('does not show notification when notification is null', () async {
        fcmService.handleForegroundMessage(const RemoteMessage(
          data: {'chatRoomId': '123'},
        ));

        verifyNever(() => mockNotificationService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            ));
      });
    });
  });

  group('NoOpFcmService', () {
    late NoOpFcmService noOpFcmService;

    setUp(() {
      noOpFcmService = NoOpFcmService();
    });

    test('initialize does nothing', () async {
      await noOpFcmService.initialize();
      // No exception means success
    });

    test('getToken returns null', () async {
      final token = await noOpFcmService.getToken();
      expect(token, isNull);
    });

    test('deleteToken does nothing', () async {
      await noOpFcmService.deleteToken();
      // No exception means success
    });

    test('onTokenRefresh returns empty stream', () async {
      final stream = noOpFcmService.onTokenRefresh;
      expect(stream, emitsDone);
    });

    test('dispose does nothing', () {
      noOpFcmService.dispose();
      // No exception means success
    });
  });
}
