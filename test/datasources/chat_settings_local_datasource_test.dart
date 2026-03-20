import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:co_talk_flutter/data/datasources/local/chat_settings_local_datasource.dart';
import 'package:co_talk_flutter/data/models/chat_settings_model.dart';

void main() {
  late ChatSettingsLocalDataSourceImpl dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = ChatSettingsLocalDataSourceImpl();
  });

  group('ChatSettingsLocalDataSource', () {
    group('getChatSettings', () {
      test('returns default ChatSettingsModel when nothing is saved', () async {
        final result = await dataSource.getChatSettings();

        expect(result.fontSize, 1.0);
        expect(result.autoDownloadImagesOnWifi, isTrue);
        expect(result.autoDownloadImagesOnMobile, isFalse);
        expect(result.autoDownloadVideosOnWifi, isTrue);
        expect(result.autoDownloadVideosOnMobile, isFalse);
        expect(result.showTypingIndicator, isFalse);
      });

      test('returns default ChatSettingsModel when stored JSON is invalid', () async {
        SharedPreferences.setMockInitialValues({
          'chat_settings': 'not_valid_json{{{{',
        });

        final result = await dataSource.getChatSettings();

        expect(result.fontSize, 1.0);
        expect(result.autoDownloadImagesOnWifi, isTrue);
      });

      test('returns saved settings when valid JSON exists', () async {
        const settings = ChatSettingsModel(
          fontSize: 1.5,
          autoDownloadImagesOnWifi: false,
          autoDownloadImagesOnMobile: true,
          autoDownloadVideosOnWifi: false,
          autoDownloadVideosOnMobile: true,
          showTypingIndicator: true,
        );
        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();

        expect(result.fontSize, 1.5);
        expect(result.autoDownloadImagesOnWifi, isFalse);
        expect(result.autoDownloadImagesOnMobile, isTrue);
        expect(result.autoDownloadVideosOnWifi, isFalse);
        expect(result.autoDownloadVideosOnMobile, isTrue);
        expect(result.showTypingIndicator, isTrue);
      });
    });

    group('saveChatSettings', () {
      test('persists settings that can be retrieved', () async {
        const settings = ChatSettingsModel(
          fontSize: 2.0,
          autoDownloadImagesOnWifi: true,
          autoDownloadImagesOnMobile: true,
          autoDownloadVideosOnWifi: false,
          autoDownloadVideosOnMobile: false,
          showTypingIndicator: true,
        );

        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();
        expect(result.fontSize, 2.0);
        expect(result.autoDownloadImagesOnWifi, isTrue);
        expect(result.autoDownloadImagesOnMobile, isTrue);
        expect(result.autoDownloadVideosOnWifi, isFalse);
        expect(result.autoDownloadVideosOnMobile, isFalse);
        expect(result.showTypingIndicator, isTrue);
      });

      test('overwrites previously saved settings', () async {
        const firstSettings = ChatSettingsModel(fontSize: 1.0);
        await dataSource.saveChatSettings(firstSettings);

        const secondSettings = ChatSettingsModel(fontSize: 1.8, showTypingIndicator: true);
        await dataSource.saveChatSettings(secondSettings);

        final result = await dataSource.getChatSettings();
        expect(result.fontSize, 1.8);
        expect(result.showTypingIndicator, isTrue);
      });

      test('saves default-valued settings correctly', () async {
        const settings = ChatSettingsModel();

        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();
        expect(result.fontSize, 1.0);
        expect(result.autoDownloadImagesOnWifi, isTrue);
        expect(result.autoDownloadImagesOnMobile, isFalse);
        expect(result.autoDownloadVideosOnWifi, isTrue);
        expect(result.autoDownloadVideosOnMobile, isFalse);
        expect(result.showTypingIndicator, isFalse);
      });
    });

    group('clearCache', () {
      test('clearCache completes without throwing', () async {
        await expectLater(dataSource.clearCache(), completes);
      });

      test('getChatSettings still works after clearCache', () async {
        const settings = ChatSettingsModel(fontSize: 1.5);
        await dataSource.saveChatSettings(settings);

        // clearCache deletes filesystem temp dir, not SharedPreferences
        await dataSource.clearCache();

        // SharedPreferences-stored settings should still be accessible
        final result = await dataSource.getChatSettings();
        expect(result, isA<ChatSettingsModel>());
      });
    });

    group('round-trip', () {
      test('fontSize round-trip', () async {
        const settings = ChatSettingsModel(fontSize: 1.25);
        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();
        expect(result.fontSize, 1.25);
      });

      test('boolean flags round-trip all true', () async {
        const settings = ChatSettingsModel(
          autoDownloadImagesOnWifi: true,
          autoDownloadImagesOnMobile: true,
          autoDownloadVideosOnWifi: true,
          autoDownloadVideosOnMobile: true,
          showTypingIndicator: true,
        );
        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();
        expect(result.autoDownloadImagesOnWifi, isTrue);
        expect(result.autoDownloadImagesOnMobile, isTrue);
        expect(result.autoDownloadVideosOnWifi, isTrue);
        expect(result.autoDownloadVideosOnMobile, isTrue);
        expect(result.showTypingIndicator, isTrue);
      });

      test('boolean flags round-trip all false', () async {
        const settings = ChatSettingsModel(
          autoDownloadImagesOnWifi: false,
          autoDownloadImagesOnMobile: false,
          autoDownloadVideosOnWifi: false,
          autoDownloadVideosOnMobile: false,
          showTypingIndicator: false,
        );
        await dataSource.saveChatSettings(settings);

        final result = await dataSource.getChatSettings();
        expect(result.autoDownloadImagesOnWifi, isFalse);
        expect(result.autoDownloadImagesOnMobile, isFalse);
        expect(result.autoDownloadVideosOnWifi, isFalse);
        expect(result.autoDownloadVideosOnMobile, isFalse);
        expect(result.showTypingIndicator, isFalse);
      });
    });
  });
}
