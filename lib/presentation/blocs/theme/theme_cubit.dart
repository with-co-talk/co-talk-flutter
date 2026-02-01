import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/local/theme_local_datasource.dart';

/// 테마 상태 관리 Cubit
///
/// 앱의 테마 모드(라이트/다크/시스템)를 관리합니다.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeLocalDataSource _dataSource;

  ThemeCubit(this._dataSource) : super(ThemeMode.system);

  /// 저장된 테마 설정 로드
  Future<void> loadTheme() async {
    final savedMode = await _dataSource.getThemeMode();
    emit(savedMode ?? ThemeMode.system);
  }

  /// 테마 모드 설정
  Future<void> setTheme(ThemeMode mode) async {
    await _dataSource.saveThemeMode(mode);
    emit(mode);
  }

  /// 다크 모드 토글
  ///
  /// [isDark]가 true면 다크 모드, false면 라이트 모드로 설정합니다.
  Future<void> toggleDarkMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    await setTheme(mode);
  }

  /// 현재 다크 모드 여부 (시스템 설정 기준)
  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
