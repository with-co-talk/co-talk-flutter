import 'package:flutter/services.dart';

/// 전역 햅틱(진동) 피드백 헬퍼.
///
/// 호출부에서 `AppHaptics.light()` 한 줄로 일관된 촉각 피드백을 준다.
/// 어떤 액션에 어떤 강도를 쓸지 의미 단위로 묶어, 코드 전반의
/// `HapticFeedback.*` 직접 호출 산재를 막는다.
abstract final class AppHaptics {
  /// 가벼운 일상 액션 — 메시지 전송, 1차 버튼 탭 등.
  static void light() => HapticFeedback.lightImpact();

  /// 중간 강도 — 롱프레스, 바텀시트 오픈, 스와이프 액션 등.
  static void medium() => HapticFeedback.mediumImpact();

  /// 선택 변경 — 토글/스위치, 탭 전환, 리액션 선택 등.
  static void selection() => HapticFeedback.selectionClick();

  /// 강한 피드백 — 에러, 파괴적 동작 확정(탈퇴/삭제), 생체인증 트리거 등.
  static void heavy() => HapticFeedback.heavyImpact();
}
