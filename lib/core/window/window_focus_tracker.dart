import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// 데스크탑 창 포커스 상태를 스트림으로 제공하는 추상화.
///
/// - 실제 구현은 `window_manager` 이벤트를 사용한다.
/// - 테스트에서는 Fake 구현으로 대체하여 blur/focus를 결정적으로 재현한다.
abstract class WindowFocusTracker {
  Stream<bool> get focusStream;

  /// 현재 창 포커스 상태를 조회한다.
  ///
  /// - Desktop에서는 `window_manager.isFocused()` 결과를 반환한다.
  /// - 지원하지 않거나(모바일/웹) 조회 실패 시 `null`을 반환한다.
  Future<bool?> currentFocus();

  void dispose();

  factory WindowFocusTracker.platform() => PlatformWindowFocusTracker();
}

/// 플랫폼 기본 구현체.
///
/// - Desktop: window_manager의 focus/blur 이벤트를 focusStream으로 변환
/// - Mobile/Web: no-op (포커스 개념이 다르거나 불필요)
class PlatformWindowFocusTracker implements WindowFocusTracker, WindowListener {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isDisposed = false;
  late final bool _isDesktopEnabled;

  PlatformWindowFocusTracker() {
    // flutter test 환경에서는 window_manager가 초기화되지 않아 예외/타이머 누수가 날 수 있다.
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final isDesktop = !kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    _isDesktopEnabled = isDesktop && !isTest;
    if (isDesktop) {
      // 테스트에서는 window_manager가 초기화되지 않아 예외/타이머 누수가 날 수 있어 비활성화한다.
      if (isTest) return;

      windowManager.addListener(this);
      // 초기 포커스 상태를 한 번 방출(이벤트가 안 오는 환경에서도 상태가 고정되지 않게)
      Future(() async {
        if (_isDisposed) return;
        try {
          final focused = await windowManager.isFocused();
          if (_isDisposed) return;
          _controller.add(focused);
        } catch (_) {
          // window_manager 초기화/권한/플랫폼에 따라 실패할 수 있으므로 무시
        }
      });
    }
  }

  @override
  Stream<bool> get focusStream => _controller.stream;

  @override
  Future<bool?> currentFocus() async {
    if (_isDisposed) return null;
    if (!_isDesktopEnabled) return null;
    try {
      return await windowManager.isFocused();
    } catch (_) {
      return null;
    }
  }

  @override
  void onWindowFocus() {
    if (_isDisposed) return;
    _controller.add(true);
  }

  @override
  void onWindowBlur() {
    if (_isDisposed) return;
    _controller.add(false);
  }

  // WindowListener는 메서드가 많아서, 관심 이벤트만 처리하고 나머지는 no-op로 둔다.
  @override
  void onWindowClose() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowLeaveFullScreen() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowMoved() {}

  @override
  void onWindowResize() {}

  @override
  void onWindowResized() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowUndocked() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      windowManager.removeListener(this);
    } catch (_) {
      // 테스트/환경에 따라 window_manager가 초기화되지 않았을 수 있다.
    }
    _controller.close();
  }
}

