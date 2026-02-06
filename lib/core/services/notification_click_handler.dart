import 'dart:async';
import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../router/app_router.dart';
import 'notification_service.dart';

/// 알림 클릭 핸들러
///
/// 알림 클릭 시 해당 채팅방으로 네비게이션합니다.
/// 데스크톱 로컬 알림과 모바일 FCM 알림 모두 지원합니다.
@lazySingleton
class NotificationClickHandler {
  final NotificationService _notificationService;
  final AppRouter _appRouter;

  StreamSubscription<String?>? _subscription;
  bool _isListening = false;

  NotificationClickHandler({
    required NotificationService notificationService,
    required AppRouter appRouter,
  })  : _notificationService = notificationService,
        _appRouter = appRouter;

  /// GoRouter 인스턴스 (테스트용)
  GoRouter get router => _appRouter.router;

  /// 알림 클릭 리스닝 시작
  void startListening() {
    if (_isListening) return;

    _subscription = _notificationService.onNotificationClick.listen(_handleNotificationClick);
    _isListening = true;
  }

  /// 알림 클릭 리스닝 중지
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  void _handleNotificationClick(String? payload) {
    _navigateToChatRoom(payload);
  }

  /// FCM 알림 클릭 처리 (외부에서 호출)
  void handleFcmNotificationClick(String payload) {
    _navigateToChatRoom(payload);
  }

  /// 채팅방으로 네비게이션
  void _navigateToChatRoom(String? payload) {
    if (payload == null || payload.isEmpty) return;

    int? roomId;

    // payload 형식: 'chatRoom:roomId'
    if (payload.startsWith('chatRoom:')) {
      final roomIdStr = payload.substring('chatRoom:'.length).trim();
      roomId = int.tryParse(roomIdStr);
    } else {
      // JSON 등 다른 형식에서 chatRoomId 추출 시도
      roomId = _parseChatRoomIdFromPayload(payload);
    }

    if (roomId != null) {
      _appRouter.router.go(AppRoutes.chatRoomPath(roomId));
    }
  }

  int? _parseChatRoomIdFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['chatRoomId'];
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
      }
    } catch (_) {}
    return null;
  }

  /// 리소스 해제
  void dispose() {
    stopListening();
  }
}
