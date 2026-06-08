import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_motion.dart';

void main() {
  group('AppMotion durations', () {
    test('are ordered fast < normal < slow', () {
      expect(AppMotion.fast < AppMotion.normal, isTrue);
      expect(AppMotion.normal < AppMotion.slow, isTrue);
    });

    test('have expected canonical values', () {
      expect(AppMotion.fast, const Duration(milliseconds: 150));
      expect(AppMotion.normal, const Duration(milliseconds: 250));
      expect(AppMotion.slow, const Duration(milliseconds: 350));
    });
  });

  group('AppMotion curves', () {
    test('expose standard/emphasized/decelerate curves', () {
      expect(AppMotion.standard, isA<Curve>());
      expect(AppMotion.emphasized, isA<Curve>());
      expect(AppMotion.decelerate, isA<Curve>());
    });
  });
}
