import 'dart:collection';

import '../../../../domain/entities/message.dart';

/// 읽음(read-receipt) 이벤트를 메시지 unreadCount에 반영하는 순수 계산기.
///
/// ChatRoomBloc._onMessagesReadUpdated에서 emit/state/manager와 얽혀 있던
/// "계산" 부분만 추출했다. 부수효과(emit, 네트워크, manager 호출)는 전혀 없고,
/// 입력 → 출력만 계산하므로 동작 보존(behavior-preserving) 검증이 쉽다.
class ReadReceiptCalculator {
  const ReadReceiptCalculator();

  /// 처리된 read 이벤트 중복 판별용 키.
  ///
  /// (userId, lastReadMessageId) 또는 (userId, lastReadAt) 조합으로 식별하며,
  /// 둘 다 없으면 'all'로 폴백한다.
  String dedupKey({
    required int userId,
    int? lastReadMessageId,
    DateTime? lastReadAt,
  }) {
    final suffix =
        lastReadMessageId ?? lastReadAt?.millisecondsSinceEpoch ?? 'all';
    return '${userId}_$suffix';
  }

  /// 단일 메시지의 unreadCount를 read 이벤트에 따라 갱신한다.
  ///
  /// 규칙(원본 _onMessagesReadUpdated.updateMessageReadCount와 동일):
  /// - 내가([currentUserId]) 보낸 메시지만 대상.
  /// - 이미 0 이하이면 그대로 둔다.
  /// - lastReadMessageId가 있으면 해당 ID 이하 메시지만 -1.
  /// - 없고 lastReadAt이 있으면 그 시각 이전(또는 같음) 메시지만 -1.
  /// - 둘 다 없으면 모든 대상 메시지 -1.
  Message applyToMessage(
    Message message, {
    required int currentUserId,
    int? lastReadMessageId,
    DateTime? lastReadAt,
  }) {
    // 내가 보낸 메시지만 업데이트
    if (message.senderId != currentUserId) return message;
    // 이미 0이면 더 감소하지 않음
    if (message.unreadCount <= 0) return message;

    // 1. lastReadMessageId가 있으면 해당 ID 이하 메시지만 업데이트
    if (lastReadMessageId != null) {
      if (message.id <= lastReadMessageId) {
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    }

    // 2. lastReadMessageId가 없고 lastReadAt이 있으면 해당 시간 이전 메시지만 업데이트
    if (lastReadAt != null) {
      if (!message.createdAt.isAfter(lastReadAt)) {
        return message.copyWith(unreadCount: message.unreadCount - 1);
      }
      return message;
    }

    // 3. 둘 다 없으면 모든 메시지를 읽음 처리
    return message.copyWith(unreadCount: message.unreadCount - 1);
  }

  /// 처리된 이벤트 키 집합에 [eventKey]를 추가하고, 무한 증가를 막기 위해
  /// 500개 초과 시 최근 250개만 남긴다(삽입 순서 보존, 원본 로직과 동일).
  LinkedHashSet<String> appendProcessedEvent(
    Set<String> processedEvents,
    String eventKey,
  ) {
    var result = LinkedHashSet<String>.from(processedEvents)..add(eventKey);
    if (result.length > 500) {
      final eventsList = result.toList();
      result = LinkedHashSet<String>.from(
        eventsList.sublist(eventsList.length - 250),
      );
    }
    return result;
  }
}
