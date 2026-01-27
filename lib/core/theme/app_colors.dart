import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - 보라색 계열 (Violet)
  static const Color primary = Color(0xFF8B5CF6); // violet-500
  static const Color primaryLight = Color(0xFFA78BFA); // violet-400
  static const Color primaryDark = Color(0xFF7C3AED); // violet-600

  // Secondary Colors - 보라색 계열 (더 밝은 톤)
  static const Color secondary = Color(0xFFA78BFA); // violet-400
  static const Color secondaryLight = Color(0xFFC4B5FD); // violet-300
  static const Color secondaryDark = Color(0xFF7C3AED); // violet-600

  // Background Colors - 더 부드러운 톤
  static const Color background = Color(0xFFFAFAFA); // 더 밝고 깔끔한 배경
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Chat Colors
  static const Color myMessageBubble = Color(0xFF8B5CF6); // primary 보라색
  static const Color otherMessageBubble = Color(0xFFF3F4F6); // 더 부드러운 회색
  static const Color myMessageBubbleDark = Color(0xFF7C3AED); // 더 진한 보라색
  static const Color otherMessageBubbleDark = Color(0xFF374151); // 다크 모드용 회색

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color away = Color(0xFFFFC107);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF8B5CF6); // primary 보라색으로 변경

  // Divider - 더 부드러운 톤
  static const Color divider = Color(0xFFE5E7EB); // 더 부드러운 회색
  static const Color dividerDark = Color(0xFF424242);
}
