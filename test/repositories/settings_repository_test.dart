import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/remote/settings_remote_datasource.dart';
import 'package:co_talk_flutter/data/datasources/local/chat_settings_local_datasource.dart';
import 'package:co_talk_flutter/data/models/notification_settings_model.dart';
import 'package:co_talk_flutter/data/models/chat_settings_model.dart';
import 'package:co_talk_flutter/data/repositories/settings_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/notification_settings.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';

class MockSettingsRemoteDataSource extends Mock
    implements SettingsRemoteDataSource {}

class MockChatSettingsLocalDataSource extends Mock
    implements ChatSettingsLocalDataSource {}

void main() {
  late MockSettingsRemoteDataSource mockRemoteDataSource;
  late MockChatSettingsLocalDataSource mockLocalDataSource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockSettingsRemoteDataSource();
    mockLocalDataSource = MockChatSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  setUpAll(() {
    registerFallbackValue(const NotificationSettingsModel());
    registerFallbackValue(const ChatSettingsModel());
  });

  group('SettingsRepository', () {
    group('getNotificationSettings', () {
      const notificationSettingsModel = NotificationSettingsModel(
        messageNotification: true,
        friendRequestNotification: false,
        groupInviteNotification: true,
        notificationPreviewMode: 'NAME_AND_MESSAGE',
        soundEnabled: true,
        vibrationEnabled: false,
        doNotDisturbEnabled: false,
        doNotDisturbStart: null,
        doNotDisturbEnd: null,
      );

      test('returns NotificationSettings from remote datasource', () async {
        when(() => mockRemoteDataSource.getNotificationSettings())
            .thenAnswer((_) async => notificationSettingsModel);

        final result = await repository.getNotificationSettings();

        expect(result, isA<NotificationSettings>());
        expect(result.messageNotification, true);
        expect(result.friendRequestNotification, false);
        expect(result.groupInviteNotification, true);
        expect(result.notificationPreviewMode,
            NotificationPreviewMode.nameAndMessage);
        verify(() => mockRemoteDataSource.getNotificationSettings()).called(1);
      });

      test('caches the result after fetching', () async {
        when(() => mockRemoteDataSource.getNotificationSettings())
            .thenAnswer((_) async => notificationSettingsModel);

        await repository.getNotificationSettings();
        final cachedResult = await repository.getNotificationSettingsCached();

        expect(cachedResult, isA<NotificationSettings>());
        expect(cachedResult.messageNotification, true);
        verify(() => mockRemoteDataSource.getNotificationSettings()).called(1);
      });

      test('throws exception when remote datasource fails', () async {
        when(() => mockRemoteDataSource.getNotificationSettings())
            .thenThrow(Exception('Network error'));

        expect(
          () => repository.getNotificationSettings(),
          throwsException,
        );
      });
    });

    group('getNotificationSettingsCached', () {
      const notificationSettingsModel = NotificationSettingsModel(
        messageNotification: true,
        friendRequestNotification: true,
        groupInviteNotification: true,
      );

      test('returns cached settings if available', () async {
        when(() => mockRemoteDataSource.getNotificationSettings())
            .thenAnswer((_) async => notificationSettingsModel);

        await repository.getNotificationSettings();
        final result = await repository.getNotificationSettingsCached();

        expect(result, isA<NotificationSettings>());
        verify(() => mockRemoteDataSource.getNotificationSettings()).called(1);
      });

      test('fetches from remote if cache is empty', () async {
        when(() => mockRemoteDataSource.getNotificationSettings())
            .thenAnswer((_) async => notificationSettingsModel);

        final result = await repository.getNotificationSettingsCached();

        expect(result, isA<NotificationSettings>());
        verify(() => mockRemoteDataSource.getNotificationSettings()).called(1);
      });
    });

    group('updateNotificationSettings', () {
      const settings = NotificationSettings(
        messageNotification: false,
        friendRequestNotification: true,
        groupInviteNotification: false,
        notificationPreviewMode: NotificationPreviewMode.nameOnly,
        soundEnabled: false,
        vibrationEnabled: true,
        doNotDisturbEnabled: true,
        doNotDisturbStart: '22:00',
        doNotDisturbEnd: '07:00',
      );

      test('updates notification settings via remote datasource', () async {
        when(() => mockRemoteDataSource.updateNotificationSettings(any()))
            .thenAnswer((_) async {});

        await repository.updateNotificationSettings(settings);

        verify(() => mockRemoteDataSource.updateNotificationSettings(any()))
            .called(1);
      });

      test('updates cache after successful update', () async {
        when(() => mockRemoteDataSource.updateNotificationSettings(any()))
            .thenAnswer((_) async {});

        await repository.updateNotificationSettings(settings);
        final cachedResult = await repository.getNotificationSettingsCached();

        expect(cachedResult, equals(settings));
        verify(() => mockRemoteDataSource.updateNotificationSettings(any()))
            .called(1);
      });

      test('throws exception when update fails', () async {
        when(() => mockRemoteDataSource.updateNotificationSettings(any()))
            .thenThrow(Exception('Update failed'));

        expect(
          () => repository.updateNotificationSettings(settings),
          throwsException,
        );
      });
    });

    group('getChatSettings', () {
      const chatSettingsModel = ChatSettingsModel(
        fontSize: 1.2,
        autoDownloadImagesOnWifi: true,
        autoDownloadImagesOnMobile: false,
        autoDownloadVideosOnWifi: false,
        autoDownloadVideosOnMobile: false,
        showTypingIndicator: true,
      );

      test('returns ChatSettings from local datasource', () async {
        when(() => mockLocalDataSource.getChatSettings())
            .thenAnswer((_) async => chatSettingsModel);

        final result = await repository.getChatSettings();

        expect(result, isA<ChatSettings>());
        expect(result.fontSize, 1.2);
        expect(result.autoDownloadImagesOnWifi, true);
        expect(result.autoDownloadImagesOnMobile, false);
        expect(result.showTypingIndicator, true);
        verify(() => mockLocalDataSource.getChatSettings()).called(1);
      });

      test('throws exception when local datasource fails', () async {
        when(() => mockLocalDataSource.getChatSettings())
            .thenThrow(Exception('Storage error'));

        expect(
          () => repository.getChatSettings(),
          throwsException,
        );
      });
    });

    group('saveChatSettings', () {
      const settings = ChatSettings(
        fontSize: 1.4,
        autoDownloadImagesOnWifi: false,
        autoDownloadImagesOnMobile: false,
        autoDownloadVideosOnWifi: true,
        autoDownloadVideosOnMobile: true,
        showTypingIndicator: false,
      );

      test('saves chat settings to local datasource', () async {
        when(() => mockLocalDataSource.saveChatSettings(any()))
            .thenAnswer((_) async {});

        await repository.saveChatSettings(settings);

        verify(() => mockLocalDataSource.saveChatSettings(any())).called(1);
      });

      test('throws exception when save fails', () async {
        when(() => mockLocalDataSource.saveChatSettings(any()))
            .thenThrow(Exception('Save failed'));

        expect(
          () => repository.saveChatSettings(settings),
          throwsException,
        );
      });
    });

    group('clearCache', () {
      test('clears cache via local datasource', () async {
        when(() => mockLocalDataSource.clearCache())
            .thenAnswer((_) async {});

        await repository.clearCache();

        verify(() => mockLocalDataSource.clearCache()).called(1);
      });

      test('throws exception when clear fails', () async {
        when(() => mockLocalDataSource.clearCache())
            .thenThrow(Exception('Clear failed'));

        expect(
          () => repository.clearCache(),
          throwsException,
        );
      });
    });

    group('deleteAccount', () {
      test('deletes account via remote datasource', () async {
        when(() => mockRemoteDataSource.deleteAccount(any(), any()))
            .thenAnswer((_) async {});

        await repository.deleteAccount(123, 'password123');

        verify(() => mockRemoteDataSource.deleteAccount(123, 'password123'))
            .called(1);
      });

      test('throws exception when delete fails', () async {
        when(() => mockRemoteDataSource.deleteAccount(any(), any()))
            .thenThrow(Exception('Invalid password'));

        expect(
          () => repository.deleteAccount(123, 'wrongpassword'),
          throwsException,
        );
      });
    });

    group('changePassword', () {
      test('changes password via remote datasource', () async {
        when(() => mockRemoteDataSource.changePassword(any(), any()))
            .thenAnswer((_) async {});

        await repository.changePassword('oldPassword', 'newPassword');

        verify(() =>
                mockRemoteDataSource.changePassword('oldPassword', 'newPassword'))
            .called(1);
      });

      test('throws exception when password change fails', () async {
        when(() => mockRemoteDataSource.changePassword(any(), any()))
            .thenThrow(Exception('Current password is incorrect'));

        expect(
          () => repository.changePassword('wrongPassword', 'newPassword'),
          throwsException,
        );
      });
    });
  });
}
