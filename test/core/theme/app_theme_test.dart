import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';

void main() {
  group('AppTheme.lightTheme AppBar', () {
    final appBar = AppTheme.lightTheme.appBarTheme;

    test('uses surface background (not solid primary) — M3 modern look', () {
      expect(appBar.backgroundColor, AppColors.surface);
      expect(appBar.backgroundColor, isNot(AppColors.primary));
    });

    test('uses primary text color as foreground for contrast on surface', () {
      expect(appBar.foregroundColor, AppColors.textPrimary);
    });

    test('has no scroll-under elevation tint', () {
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
    });

    test('title style is w600 / 18sp in textPrimary', () {
      expect(appBar.titleTextStyle?.fontWeight, FontWeight.w600);
      expect(appBar.titleTextStyle?.fontSize, 18);
      expect(appBar.titleTextStyle?.color, AppColors.textPrimary);
    });
  });

  group('AppTheme typography (Pretendard)', () {
    test('light theme uses Pretendard font family', () {
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily, 'Pretendard');
    });

    test('dark theme uses Pretendard font family', () {
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily, 'Pretendard');
    });

    test('AppBar title also uses Pretendard (no system-font fallback)', () {
      expect(
        AppTheme.lightTheme.appBarTheme.titleTextStyle?.fontFamily,
        'Pretendard',
      );
      expect(
        AppTheme.darkTheme.appBarTheme.titleTextStyle?.fontFamily,
        'Pretendard',
      );
    });
  });

  group('AppTheme.darkTheme AppBar', () {
    final appBar = AppTheme.darkTheme.appBarTheme;

    test('uses dark surface background', () {
      expect(appBar.backgroundColor, AppColors.surfaceDark);
    });

    test('uses dark primary text color as foreground', () {
      expect(appBar.foregroundColor, AppColors.textPrimaryDark);
    });

    test('has no scroll-under elevation tint', () {
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
    });
  });
}
