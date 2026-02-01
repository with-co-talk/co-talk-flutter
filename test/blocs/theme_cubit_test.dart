import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/presentation/blocs/theme/theme_cubit.dart';
import 'package:co_talk_flutter/data/datasources/local/theme_local_datasource.dart';

class MockThemeLocalDataSource extends Mock implements ThemeLocalDataSource {}

void main() {
  late MockThemeLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    mockDataSource = MockThemeLocalDataSource();
  });

  group('ThemeCubit', () {
    test('initial state is system theme mode', () {
      when(() => mockDataSource.getThemeMode()).thenAnswer((_) async => null);

      final cubit = ThemeCubit(mockDataSource);

      expect(cubit.state, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'loadTheme emits saved theme mode from local storage',
      setUp: () {
        when(() => mockDataSource.getThemeMode())
            .thenAnswer((_) async => ThemeMode.dark);
      },
      build: () => ThemeCubit(mockDataSource),
      act: (cubit) => cubit.loadTheme(),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'loadTheme emits system when no saved theme',
      setUp: () {
        when(() => mockDataSource.getThemeMode()).thenAnswer((_) async => null);
      },
      build: () => ThemeCubit(mockDataSource),
      act: (cubit) => cubit.loadTheme(),
      expect: () => [ThemeMode.system],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setTheme emits new theme mode and saves to local storage',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      act: (cubit) => cubit.setTheme(ThemeMode.dark),
      expect: () => [ThemeMode.dark],
      verify: (_) {
        verify(() => mockDataSource.saveThemeMode(ThemeMode.dark)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setTheme to light mode',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      act: (cubit) => cubit.setTheme(ThemeMode.light),
      expect: () => [ThemeMode.light],
      verify: (_) {
        verify(() => mockDataSource.saveThemeMode(ThemeMode.light)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setTheme to system mode',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      act: (cubit) => cubit.setTheme(ThemeMode.system),
      expect: () => [ThemeMode.system],
      verify: (_) {
        verify(() => mockDataSource.saveThemeMode(ThemeMode.system)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleDarkMode switches from system to dark',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      seed: () => ThemeMode.system,
      act: (cubit) => cubit.toggleDarkMode(true),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleDarkMode switches from dark to light',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      seed: () => ThemeMode.dark,
      act: (cubit) => cubit.toggleDarkMode(false),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleDarkMode switches from light to dark',
      setUp: () {
        when(() => mockDataSource.saveThemeMode(any()))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(mockDataSource),
      seed: () => ThemeMode.light,
      act: (cubit) => cubit.toggleDarkMode(true),
      expect: () => [ThemeMode.dark],
    );
  });

  group('ThemeLocalDataSource', () {
    // Integration test placeholder - actual implementation will use SharedPreferences
  });
}
