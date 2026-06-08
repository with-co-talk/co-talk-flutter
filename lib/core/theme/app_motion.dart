import 'package:flutter/animation.dart';

/// 앱 전역 모션 토큰.
///
/// duration·curve를 한 곳에서 관리해 화면 전환/마이크로 인터랙션의
/// 리듬을 일관되게 유지한다. 매직넘버(`Duration(milliseconds: 200)`)를
/// 코드 곳곳에 흩뿌리지 않기 위한 단일 출처.
abstract final class AppMotion {
  // ── Durations ───────────────────────────────────────────────
  /// 작은 상태 변화(버튼 색/스케일, reveal). ~150ms.
  static const Duration fast = Duration(milliseconds: 150);

  /// 기본 전환(화면 전환, 리스트 항목 진입). ~250ms.
  static const Duration normal = Duration(milliseconds: 250);

  /// 강조 전환(시트, 큰 영역 변화). ~350ms.
  static const Duration slow = Duration(milliseconds: 350);

  // ── Curves ──────────────────────────────────────────────────
  /// 표준 감속 — 대부분의 전환에 사용.
  static const Curve standard = Curves.easeOutCubic;

  /// 살짝 튕기는 강조 — FAB/리액션 등 등장 강조.
  static const Curve emphasized = Curves.easeOutBack;

  /// 단순 감속.
  static const Curve decelerate = Curves.easeOut;
}
