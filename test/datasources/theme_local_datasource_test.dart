import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:co_talk_flutter/data/datasources/local/theme_local_datasource.dart';

void main() {
  late ThemeLocalDataSourceImpl dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = ThemeLocalDataSourceImpl();
  });

  group('ThemeLocalDataSource', () {
    group('getThemeMode', () {
      test('returns null when no theme mode is saved', () async {
        final result = await dataSource.getThemeMode();

        expect(result, isNull);
      });

      test('returns ThemeMode.light when light is saved', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

        final result = await dataSource.getThemeMode();

        expect(result, ThemeMode.light);
      });

      test('returns ThemeMode.dark when dark is saved', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

        final result = await dataSource.getThemeMode();

        expect(result, ThemeMode.dark);
      });

      test('returns ThemeMode.system when system is saved', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'system'});

        final result = await dataSource.getThemeMode();

        expect(result, ThemeMode.system);
      });

      test('returns null for unknown/invalid saved value', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'unknown_value'});

        final result = await dataSource.getThemeMode();

        expect(result, isNull);
      });
    });

    group('saveThemeMode', () {
      test('saves ThemeMode.light correctly', () async {
        await dataSource.saveThemeMode(ThemeMode.light);

        final result = await dataSource.getThemeMode();
        expect(result, ThemeMode.light);
      });

      test('saves ThemeMode.dark correctly', () async {
        await dataSource.saveThemeMode(ThemeMode.dark);

        final result = await dataSource.getThemeMode();
        expect(result, ThemeMode.dark);
      });

      test('saves ThemeMode.system correctly', () async {
        await dataSource.saveThemeMode(ThemeMode.system);

        final result = await dataSource.getThemeMode();
        expect(result, ThemeMode.system);
      });

      test('overwrites previous theme mode', () async {
        await dataSource.saveThemeMode(ThemeMode.light);
        await dataSource.saveThemeMode(ThemeMode.dark);

        final result = await dataSource.getThemeMode();
        expect(result, ThemeMode.dark);
      });
    });

    group('round-trip', () {
      test('save and retrieve light mode round-trip', () async {
        await dataSource.saveThemeMode(ThemeMode.light);
        final retrieved = await dataSource.getThemeMode();
        expect(retrieved, ThemeMode.light);
      });

      test('save and retrieve dark mode round-trip', () async {
        await dataSource.saveThemeMode(ThemeMode.dark);
        final retrieved = await dataSource.getThemeMode();
        expect(retrieved, ThemeMode.dark);
      });

      test('save and retrieve system mode round-trip', () async {
        await dataSource.saveThemeMode(ThemeMode.system);
        final retrieved = await dataSource.getThemeMode();
        expect(retrieved, ThemeMode.system);
      });

      test('all three modes can be saved and retrieved correctly', () async {
        for (final mode in ThemeMode.values) {
          await dataSource.saveThemeMode(mode);
          final result = await dataSource.getThemeMode();
          expect(result, mode);
        }
      });
    });
  });
}
