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

  /// 브랜드 시그니처 그라데이션 (라이트/다크 공통 — 보라 위 흰 글씨는 양쪽 모두 충분한 대비)
  List<Color> get brandGradient => AppColors.brandGradient;
  List<Color> get myMessageBubbleGradient =>
      isDarkMode ? AppColors.myMessageBubbleGradientDark : AppColors.brandGradient;
}

class AppColors {
  AppColors._();

  // ── Primary (Aurora Violet) ─────────────────────────────────────
  // 기존 #8B5CF6 대비 살짝 더 맑고 깊은 톤으로 정제 — "기본 보라" 인상에서 탈피
  static const Color primary = Color(0xFF7C5CFF); // 시그니처 보라
  static const Color primaryLight = Color(0xFFA992FF);
  static const Color primaryDark = Color(0xFF5B3FE0);

  /// 브랜드 그라데이션 (보라 → 라이트 바이올렛)
  static const List<Color> brandGradient = [
    Color(0xFF7C5CFF),
    Color(0xFF9D6BFF),
  ];

  /// 내 말풍선 그라데이션 (다크 모드용 — 약간 깊은 톤)
  static const List<Color> myMessageBubbleGradientDark = [
    Color(0xFF6B4DE8),
    Color(0xFF865CF0),
  ];

  // ── Secondary ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFFA992FF);
  static const Color secondaryLight = Color(0xFFC9B9FF);
  static const Color secondaryDark = Color(0xFF5B3FE0);

  // ── Background / Surface ────────────────────────────────────────
  // 라이트: 살짝 쿨한 오프화이트로 깊이감 / 다크: 거의 검정에 가까운 뉴트럴
  static const Color background = Color(0xFFF6F6FB);
  static const Color backgroundDark = Color(0xFF0E0E13);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A22);

  // ── Text ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B1B23); // 살짝 따뜻한 near-black
  static const Color textSecondary = Color(0xFF8A8A99);
  static const Color textPrimaryDark = Color(0xFFF4F4F7);
  static const Color textSecondaryDark = Color(0xFF9A9AAB);

  // ── Chat ────────────────────────────────────────────────────────
  static const Color myMessageBubble = Color(0xFF7C5CFF); // 그라데이션 미지원 시 폴백
  static const Color otherMessageBubble = Color(0xFFF0F0F6); // 쿨 그레이
  static const Color myMessageBubbleDark = Color(0xFF7858E8);
  static const Color otherMessageBubbleDark = Color(0xFF26262F);

  // ── Status ──────────────────────────────────────────────────────
  static const Color online = Color(0xFF34D399); // 살짝 모던한 그린
  static const Color offline = Color(0xFF9E9EAD);
  static const Color away = Color(0xFFFBBF24);

  // ── Semantic ────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF26B6B);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF7C5CFF);

  // ── Divider ─────────────────────────────────────────────────────
  static const Color divider = Color(0xFFECECF2);
  static const Color dividerDark = Color(0xFF2C2C37);
}
