import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';

void main() {
  group('AppTheme.lightTheme AppBar', () {
    final appBar = AppTheme.lightTheme.appBarTheme;

    test('uses background (not solid primary) — Warm Sand seamless look', () {
      expect(appBar.backgroundColor, AppColors.background);
      expect(appBar.backgroundColor, isNot(AppColors.primary));
    });

    test('uses primary text color as foreground for contrast on surface', () {
      expect(appBar.foregroundColor, AppColors.textPrimary);
    });

    test('has flat base elevation with subtle scroll-under hairline', () {
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0.5);
      expect(appBar.surfaceTintColor, Colors.transparent);
    });

    test('title style is w700 / 18sp / tight letterSpacing in textPrimary', () {
      expect(appBar.titleTextStyle?.fontWeight, FontWeight.w700);
      expect(appBar.titleTextStyle?.fontSize, 18);
      expect(appBar.titleTextStyle?.letterSpacing, -0.3);
      expect(appBar.titleTextStyle?.color, AppColors.textPrimary);
    });

    test('icon color matches textPrimary', () {
      expect(appBar.iconTheme?.color, AppColors.textPrimary);
    });

    test('systemOverlayStyle is dark (dark icons on light surface)', () {
      expect(appBar.systemOverlayStyle, SystemUiOverlayStyle.dark);
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

    test('uses dark background', () {
      expect(appBar.backgroundColor, AppColors.backgroundDark);
    });

    test('uses dark primary text color as foreground', () {
      expect(appBar.foregroundColor, AppColors.textPrimaryDark);
    });

    test('has subtle scroll-under hairline elevation, no tint', () {
      expect(appBar.scrolledUnderElevation, 0.5);
      expect(appBar.surfaceTintColor, Colors.transparent);
    });

    test('icon color matches textPrimaryDark', () {
      expect(appBar.iconTheme?.color, AppColors.textPrimaryDark);
    });

    test('systemOverlayStyle is light (light icons on dark surface)', () {
      expect(appBar.systemOverlayStyle, SystemUiOverlayStyle.light);
    });
  });
}
