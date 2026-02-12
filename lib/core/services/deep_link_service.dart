import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../router/app_router.dart';

/// 딥링크 서비스
///
/// cotalk:// 스킴의 딥링크를 처리하여 적절한 화면으로 네비게이션합니다.
/// - cotalk://chat/{roomId} → 채팅방
/// - cotalk://profile/{userId} → 프로필
@lazySingleton
class DeepLinkService {
  final AppRouter _appRouter;

  StreamSubscription<Uri>? _subscription;
  Uri? _pendingDeepLink;

  DeepLinkService(this._appRouter);

  /// 딥링크 서비스 초기화
  /// 초기 링크 확인 + 스트림 수신 시작
  Future<void> init() async {
    final appLinks = AppLinks();

    // 앱이 딥링크로 시작된 경우 초기 링크 처리
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkService] Failed to get initial link: $e');
      }
    }

    // 앱 실행 중 딥링크 수신
    _subscription = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[DeepLinkService] Link stream error: $error');
        }
      },
    );
  }

  /// 미처리 딥링크 저장 (로그인 전 수신 시)
  void storePendingDeepLink(Uri uri) {
    _pendingDeepLink = uri;
  }

  /// 미처리 딥링크가 있으면 처리 (로그인 후 호출)
  void processPendingDeepLink() {
    if (_pendingDeepLink != null) {
      final link = _pendingDeepLink!;
      _pendingDeepLink = null;
      _handleDeepLink(link);
    }
  }

  /// 딥링크 처리 (테스트용으로 public 노출)
  @visibleForTesting
  void handleDeepLinkForTest(Uri uri) => _handleDeepLink(uri);

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      debugPrint('[DeepLinkService] Received deep link: $uri');
    }

    // cotalk:// 스킴만 처리
    if (uri.scheme != 'cotalk') return;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      // cotalk://chat/123 형태 → host=chat, pathSegments=[123]
      // 처리할 path segment가 없으면 host만으로 판단 불가
    }

    switch (uri.host) {
      case 'chat':
        _handleChatDeepLink(pathSegments);
        break;
      case 'profile':
        _handleProfileDeepLink(pathSegments);
        break;
      default:
        if (kDebugMode) {
          debugPrint('[DeepLinkService] Unknown deep link host: ${uri.host}');
        }
    }
  }

  void _handleChatDeepLink(List<String> pathSegments) {
    if (pathSegments.isEmpty) return;

    final roomId = int.tryParse(pathSegments.first);
    if (roomId == null) return;

    try {
      _appRouter.router.go(AppRoutes.chatRoomPath(roomId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkService] Navigation failed: $e');
      }
    }
  }

  void _handleProfileDeepLink(List<String> pathSegments) {
    if (pathSegments.isEmpty) return;

    final userId = int.tryParse(pathSegments.first);
    if (userId == null) return;

    try {
      _appRouter.router.go(AppRoutes.profileViewPath(userId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkService] Navigation failed: $e');
      }
    }
  }

  /// 리소스 해제
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
