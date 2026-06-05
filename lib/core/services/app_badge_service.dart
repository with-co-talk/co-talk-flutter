import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// 앱 아이콘 배지(미읽음 메시지 수) 관리 서비스.
///
/// iOS는 배지 숫자를 정확히 표시하며, Android는 런처에 따라 best-effort로 표시된다.
/// 데스크톱/웹 등 미지원 플랫폼에서는 아무 동작도 하지 않는다.
@lazySingleton
class AppBadgeService {
  /// 앱 아이콘 배지를 [count]로 갱신한다.
  ///
  /// [count]가 0 이하이면 배지를 제거한다. 미지원 플랫폼이거나 오류가 발생하면
  /// 조용히 무시한다(앱 동작에 영향을 주지 않는다).
  Future<void> updateBadge(int count) async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      return;
    }
    try {
      if (!await AppBadgePlus.isSupported()) {
        return;
      }
      await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppBadgeService] updateBadge failed: $e');
      }
    }
  }

  /// 앱 아이콘 배지를 제거한다.
  Future<void> clear() => updateBadge(0);
}
