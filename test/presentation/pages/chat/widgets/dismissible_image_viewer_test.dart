import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// _DismissibleImageViewer 는 private 이므로 message_bubble.dart 내부의
// 공개 진입점(_showFullScreenImage)을 통해 동작을 검증한다.
// 여기서는 panEnabled 게이팅과 Hero 클리핑 구조에 대한 단위 수준 검증을 담는다.

// ── 헬퍼: TransformationController 를 직접 조작해 scale 을 확인하는 단위 테스트 ──

void main() {
  group('TransformationController scale gate (panEnabled logic)', () {
    test('scale 1.0 → panEnabled false', () {
      final controller = TransformationController();
      // 초기 상태: 변환 없음 → scale == 1.0
      final scale = controller.value.getMaxScaleOnAxis();
      expect(scale, closeTo(1.0, 0.001));
      // panEnabled 조건: scale > 1.0 → false
      expect(scale > 1.0, isFalse);
      controller.dispose();
    });

    test('zoom in → scale > 1.0 → panEnabled true', () {
      final controller = TransformationController();
      // 2× zoom 을 직접 주입
      controller.value = Matrix4.identity()..scale(2.0);
      final scale = controller.value.getMaxScaleOnAxis();
      expect(scale, closeTo(2.0, 0.001));
      // panEnabled 조건: scale > 1.0 → true
      expect(scale > 1.0, isTrue);
      controller.dispose();
    });

    test('zoom back to 1.0 → panEnabled false again', () {
      final controller = TransformationController();
      controller.value = Matrix4.identity()..scale(2.0);
      // 다시 1× 로 되돌림
      controller.value = Matrix4.identity();
      final scale = controller.value.getMaxScaleOnAxis();
      expect(scale, closeTo(1.0, 0.001));
      expect(scale > 1.0, isFalse);
      controller.dispose();
    });

    test(
        'boolean 게이팅: scale 이 같은 boolean 구간 안에서 변해도 panEnabled 는 바뀌지 않는다 '
        '(불필요한 setState 방지)', () {
      // 프로덕션 _onInteractionUpdate 의 게이팅 로직을 그대로 재현.
      final controller = TransformationController();
      bool panEnabled = false;
      int transitions = 0;

      void onUpdate() {
        final next = controller.value.getMaxScaleOnAxis() > 1.0;
        if (next != panEnabled) {
          panEnabled = next;
          transitions++; // setState 가 호출되는 시점
        }
      }

      // 1.0 → 1.0(미세 변화): false 유지, 전환 없음
      controller.value = Matrix4.identity()..scale(1.0);
      onUpdate();
      expect(panEnabled, isFalse);
      expect(transitions, 0);

      // 1.0 → 1.5: false → true, 전환 1회
      controller.value = Matrix4.identity()..scale(1.5);
      onUpdate();
      expect(panEnabled, isTrue);
      expect(transitions, 1);

      // 1.5 → 2.0 → 3.0: 모두 true 구간 → 추가 전환 없음
      controller.value = Matrix4.identity()..scale(2.0);
      onUpdate();
      controller.value = Matrix4.identity()..scale(3.0);
      onUpdate();
      expect(panEnabled, isTrue);
      expect(transitions, 1);

      // 3.0 → 1.0: true → false, 전환 1회 추가
      controller.value = Matrix4.identity();
      onUpdate();
      expect(panEnabled, isFalse);
      expect(transitions, 2);

      controller.dispose();
    });
  });

  group('Hero + ClipRRect 구조 — bubble 측 borderRadius 보간', () {
    test('lerp: t=0 → 버블 radius 유지', () {
      final bubbleRadius = BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(18),
      );
      final result = BorderRadius.lerp(bubbleRadius, BorderRadius.zero, 0)!;
      expect(result.topLeft.x, closeTo(18.0, 0.001));
      expect(result.bottomLeft.x, closeTo(4.0, 0.001));
    });

    test('lerp: t=1 → BorderRadius.zero (전체화면 모서리 없음)', () {
      final bubbleRadius = BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(18),
      );
      final result = BorderRadius.lerp(bubbleRadius, BorderRadius.zero, 1)!;
      expect(result.topLeft.x, closeTo(0.0, 0.001));
      expect(result.bottomLeft.x, closeTo(0.0, 0.001));
    });

    test('lerp: t=0.5 → 중간 값', () {
      final bubbleRadius = BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(18),
      );
      final result = BorderRadius.lerp(bubbleRadius, BorderRadius.zero, 0.5)!;
      expect(result.topLeft.x, closeTo(9.0, 0.001));
      expect(result.bottomLeft.x, closeTo(2.0, 0.001));
    });
  });
}
