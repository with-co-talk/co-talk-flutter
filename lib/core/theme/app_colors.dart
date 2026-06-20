import 'package:flutter/material.dart';

/// Context 기반 다크 모드 대응 색상 확장
extension AppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor =>
      isDarkMode ? AppColors.backgroundDark : AppColors.background;
  Color get surfaceColor =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  Color get textPrimaryColor =>
      isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondaryColor =>
      isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get dividerColor =>
      isDarkMode ? AppColors.dividerDark : AppColors.divider;
  Color get myMessageBubbleColor =>
      isDarkMode ? AppColors.myMessageBubbleDark : AppColors.myMessageBubble;
  Color get otherMessageBubbleColor =>
      isDarkMode ? AppColors.otherMessageBubbleDark : AppColors.otherMessageBubble;

  /// 브랜드 시그니처 그라데이션 (테라코타 위 흰 글씨는 라이트/다크 모두 충분한 대비)
  List<Color> get brandGradient => AppColors.brandGradient;
  List<Color> get myMessageBubbleGradient =>
      isDarkMode ? AppColors.myMessageBubbleGradientDark : AppColors.brandGradient;
}

class AppColors {
  AppColors._();

  // ── Primary (Warm Sand · Terracotta) ───────────────────────────
  // 따뜻한 테라코타 — "오래 머물고 싶은" 코지한 메신저 톤
  static const Color primary = Color(0xFFE3744D); // 시그니처 테라코타
  static const Color primaryLight = Color(0xFFEC8B63);
  static const Color primaryDark = Color(0xFFC2693F);

  /// 브랜드 그라데이션 (라이트 테라코타 → 딥 테라코타)
  static const List<Color> brandGradient = [
    Color(0xFFEC8B63),
    Color(0xFFE3744D),
  ];

  /// 내 말풍선 그라데이션 (다크 모드용 — 약간 깊은 톤)
  static const List<Color> myMessageBubbleGradientDark = [
    Color(0xFFD97B52),
    Color(0xFFC2693F),
  ];

  // ── Secondary ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFFEC8B63);
  static const Color secondaryLight = Color(0xFFF2B393);
  static const Color secondaryDark = Color(0xFFC2693F);

  // ── Background / Surface (warm) ─────────────────────────────────
  static const Color background = Color(0xFFF5EDE1); // 웜 크림
  static const Color backgroundDark = Color(0xFF181410); // 웜 near-black
  static const Color surface = Color(0xFFFFFBF4); // 웜 화이트
  static const Color surfaceDark = Color(0xFF241F1A); // 웜 다크 표면

  // ── Text (warm) ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF40362C); // 웜 다크 브라운
  static const Color textSecondary = Color(0xFFA0917F); // 웜 그레이
  static const Color textPrimaryDark = Color(0xFFF4EEE6);
  static const Color textSecondaryDark = Color(0xFFB3A593);

  // ── Chat ────────────────────────────────────────────────────────
  static const Color myMessageBubble = Color(0xFFE3744D); // 폴백(그라데이션 미지원 시)
  static const Color otherMessageBubble = Color(0xFFFFFBF4); // 웜 화이트
  static const Color myMessageBubbleDark = Color(0xFFCE6E45);
  static const Color otherMessageBubbleDark = Color(0xFF2E2823);

  // ── Status ──────────────────────────────────────────────────────
  static const Color online = Color(0xFF7FB069); // 세이지 그린
  static const Color offline = Color(0xFFB3A593);
  static const Color away = Color(0xFFE0A458); // 웜 앰버

  // ── Semantic ────────────────────────────────────────────────────
  static const Color success = Color(0xFF7FB069);
  static const Color error = Color(0xFFD9685A); // 웜 레드
  static const Color warning = Color(0xFFE0A458);
  static const Color info = Color(0xFFE3744D);

  // ── Divider ─────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEADFCE); // 웜 디바이더
  static const Color dividerDark = Color(0xFF3A322B);
}
