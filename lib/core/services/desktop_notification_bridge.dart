import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../network/websocket_service.dart';
import '../window/window_focus_tracker.dart';
import 'notification_service.dart';

/// 데스크톱 알림 브릿지
///
/// WebSocket 메시지 수신 시 로컬 알림을 표시합니다.
/// - 데스크톱 플랫폼(macOS, Windows, Linux)에서만 동작
/// - 앱이 포커스 상태이고 해당 채팅방이 열려있으면 알림 억제
/// - 내가 보낸 메시지는 알림 표시 안함
@lazySingleton
class DesktopNotificationBridge {
  final NotificationService _notificationService;
  final WebSocketService _webSocketService;
  final WindowFocusTracker _windowFocusTracker;
  final SettingsRepository _settingsRepository;

  int? _currentUserId;
  int? _activeRoomId;
  StreamSubscription<WebSocketChatRoomUpdateEvent>? _subscription;
  bool _isListening = false;

  DesktopNotificationBridge({
    required NotificationService notificationService,
    required WebSocketService webSocketService,
    required WindowFocusTracker windowFocusTracker,
    required SettingsRepository settingsRepository,
  })  : _notificationService = notificationService,
        _webSocketService = webSocketService,
        _windowFocusTracker = windowFocusTracker,
        _settingsRepository = settingsRepository;

  /// 현재 활성 채팅방 ID
  int? get activeRoomId => _activeRoomId;

  /// 현재 사용자 ID
  int? get currentUserId => _currentUserId;

  /// 현재 사용자 ID 설정
  ///
  /// 로그인 시 호출하여 내가 보낸 메시지 필터링에 사용
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }

  /// 현재 활성 채팅방 ID 설정
  ///
  /// 채팅방 진입/퇴장 시 호출하여 알림 억제에 사용
  void setActiveRoomId(int? roomId) {
    _activeRoomId = roomId;
  }

  /// 알림 리스닝 시작
  ///
  /// 데스크톱 플랫폼에서만 WebSocket 메시지를 구독하고 알림을 표시합니다.
  void startListening() {
    // 이미 리스닝 중이면 무시
    if (_isListening) return;

    // 데스크톱 플랫폼에서만 동작
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return;
    }

    _subscription = _webSocketService.chatRoomUpdates.listen(_handleChatRoomUpdate);
    _isListening = true;
    if (kDebugMode) {
      debugPrint('[DesktopNotificationBridge] Started listening for desktop notifications');
    }
  }

  /// 알림 리스닝 중지
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    if (kDebugMode) {
      debugPrint('[DesktopNotificationBridge] Stopped listening for desktop notifications');
    }
  }

  Future<void> _handleChatRoomUpdate(WebSocketChatRoomUpdateEvent event) async {
    // NEW_MESSAGE 이벤트만 처리
    if (event.eventType != 'NEW_MESSAGE') {
      return;
    }

    // 내가 보낸 메시지는 무시
    if (_currentUserId != null && event.senderId == _currentUserId) {
      return;
    }

    // 앱이 포커스 상태이고 해당 채팅방이 열려있으면 무시
    final isFocused = await _windowFocusTracker.currentFocus() ?? false;
    if (isFocused && _activeRoomId == event.chatRoomId) {
      return;
    }

    // Settings
    NotificationPreviewMode previewMode = NotificationPreviewMode.nameAndMessage;
    bool soundEnabled = true;
    bool vibrationEnabled = true;
    try {
      final settings = await _settingsRepository.getNotificationSettingsCached();
      previewMode = settings.notificationPreviewMode;
      soundEnabled = settings.soundEnabled;
      vibrationEnabled = settings.vibrationEnabled;
    } catch (_) {}

    // Apply preview mode
    String title;
    String body;
    switch (previewMode) {
      case NotificationPreviewMode.nameAndMessage:
        title = event.senderNickname ?? '새 메시지';
        if (event.lastMessageType == 'IMAGE') {
          body = '사진을 보냈습니다';
        } else {
          body = event.lastMessage ?? '';
        }
      case NotificationPreviewMode.nameOnly:
        title = event.senderNickname ?? '새 메시지';
        body = '새 메시지';
      case NotificationPreviewMode.nothing:
        title = '새 메시지';
        body = '새 메시지가 도착했습니다';
    }

    await _notificationService.showNotification(
      title: title,
      body: body,
      payload: 'chatRoom:${event.chatRoomId}',
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
    );
  }

  /// 리소스 해제
  void dispose() {
    stopListening();
  }
}
