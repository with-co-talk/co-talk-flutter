import 'package:flutter/foundation.dart';

import '../../../../core/network/websocket_service.dart';
import '../../../../domain/entities/message.dart';
import 'message_cache_manager.dart';

/// 리액션(이모지) 추가/제거/수신 처리를 담당하는 collaborator.
///
/// ChatRoomBloc의 세 reaction 핸들러에서 반복되던
/// "cache 동기화 → optimistic mutation → WebSocket 전송" 흐름을 모았다.
/// emit/state는 bloc이 그대로 보유하고, 이 핸들러는 캐시 변형과 WS 호출만
/// 담당하며 갱신된 메시지 리스트를 돌려준다(동작 보존).
class ReactionHandler {
  final MessageCacheManager _cacheManager;
  final WebSocketService _webSocketService;

  ReactionHandler(this._cacheManager, this._webSocketService);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ChatRoomBloc] $message');
    }
  }

  /// seeded state(테스트 등)에서 cache가 비어있고 state에는 메시지가 있으면 동기화.
  /// 원본 핸들러의 "Sync cache manager with state if out of sync" 가드와 동일.
  void _syncCacheIfNeeded(List<Message> stateMessages) {
    if (_cacheManager.messages.isEmpty && stateMessages.isNotEmpty) {
      _cacheManager.syncMessages(stateMessages);
    }
  }

  /// 리액션 추가 요청 처리(낙관적 갱신).
  ///
  /// [currentUserId]가 null이면 낙관적 갱신을 건너뛰지만, WebSocket 전송은
  /// 원본과 동일하게 항상 수행한다. 낙관적 갱신이 일어나 emit이 필요하면 갱신된
  /// 메시지 리스트를 반환하고, 아니면 null을 반환한다.
  List<Message>? addRequested({
    required int messageId,
    required String emoji,
    required int? currentUserId,
    required List<Message> stateMessages,
  }) {
    _log('_onReactionAddRequested: messageId=$messageId, emoji=$emoji');
    _syncCacheIfNeeded(stateMessages);

    List<Message>? updated;
    if (currentUserId != null) {
      final optimisticReaction = MessageReaction(
        id: 0, // temporary ID, will be replaced by server echo
        messageId: messageId,
        userId: currentUserId,
        emoji: emoji,
      );
      _cacheManager.addReaction(messageId, optimisticReaction);
      updated = _cacheManager.messages;
    }

    _webSocketService.addReaction(messageId: messageId, emoji: emoji);
    return updated;
  }

  /// 리액션 제거 요청 처리(낙관적 갱신).
  List<Message>? removeRequested({
    required int messageId,
    required String emoji,
    required int? currentUserId,
    required List<Message> stateMessages,
  }) {
    _log('_onReactionRemoveRequested: messageId=$messageId, emoji=$emoji');
    _syncCacheIfNeeded(stateMessages);

    List<Message>? updated;
    if (currentUserId != null) {
      _cacheManager.removeReaction(messageId, currentUserId, emoji);
      updated = _cacheManager.messages;
    }

    _webSocketService.removeReaction(messageId: messageId, emoji: emoji);
    return updated;
  }

  /// WebSocket으로 수신한 리액션 이벤트 처리. 항상 갱신된 메시지 리스트를 반환한다.
  List<Message> eventReceived({
    required int messageId,
    required int userId,
    String? userNickname,
    required String emoji,
    required bool isAdd,
    int? reactionId,
    required List<Message> stateMessages,
  }) {
    _log('_onReactionEventReceived: messageId=$messageId, userId=$userId, emoji=$emoji, isAdd=$isAdd');
    _syncCacheIfNeeded(stateMessages);

    if (isAdd) {
      final reaction = MessageReaction(
        id: reactionId ?? 0,
        messageId: messageId,
        userId: userId,
        userNickname: userNickname,
        emoji: emoji,
      );
      _cacheManager.addReaction(messageId, reaction);
    } else {
      _cacheManager.removeReaction(messageId, userId, emoji);
    }

    return _cacheManager.messages;
  }
}
