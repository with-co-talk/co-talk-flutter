import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 설정 로컬 저장소 인터페이스
abstract class ThemeLocalDataSource {
  /// 저장된 테마 모드 조회
  Future<ThemeMode?> getThemeMode();

  /// 테마 모드 저장
  Future<void> saveThemeMode(ThemeMode mode);
}

/// 테마 설정 로컬 저장소 구현체
///
/// SharedPreferences를 사용하여 테마 설정을 저장합니다.
@LazySingleton(as: ThemeLocalDataSource)
class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  static const String _themeModeKey = 'theme_mode';

  @override
  Future<ThemeMode?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);

    if (value == null) return null;

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await prefs.setString(_themeModeKey, value);
  }
}
