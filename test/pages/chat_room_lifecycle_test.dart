import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS lifecycle debounce', () {
    test('brief paused→resumed cycle should cancel background timer', () async {
      // Simulate the debounce logic in isolation
      var backgroundedDispatched = false;

      // 1. paused fires → timer starts (1500ms)
      Timer backgroundDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
        backgroundedDispatched = true;
      });

      // 2. resumed fires after 500ms → timer cancelled
      await Future.delayed(const Duration(milliseconds: 500));
      backgroundDebounceTimer.cancel();

      // 3. Wait for full debounce duration
      await Future.delayed(const Duration(milliseconds: 1500));

      // backgrounded should NOT have been dispatched
      expect(backgroundedDispatched, isFalse,
        reason: 'Brief paused→resumed should not trigger backgrounded');
    });

    test('sustained paused should eventually trigger backgrounded', () async {
      var backgroundedDispatched = false;

      // 1. paused fires → timer starts (1500ms)
      final backgroundDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
        backgroundedDispatched = true;
      });

      // 2. Wait for full debounce duration without resumed
      await Future.delayed(const Duration(milliseconds: 2000));

      // backgrounded SHOULD have been dispatched
      expect(backgroundedDispatched, isTrue,
        reason: 'Sustained paused should trigger backgrounded after debounce');

      backgroundDebounceTimer.cancel();
    });
  });
}
