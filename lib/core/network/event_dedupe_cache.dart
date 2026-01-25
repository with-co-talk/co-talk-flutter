import 'dart:collection';

/// eventId 기반 중복 이벤트 필터(LRU + TTL).
///
/// - 네트워크 재전송/재연결/다중 채널 수신으로 인해 동일 이벤트가 여러 번 들어오는 것을 막는다.
/// - TTL 윈도우 내 동일 key(eventId)가 다시 들어오면 "중복"으로 판단한다.
class EventDedupeCache {
  final Duration ttl;
  final int maxSize;
  final DateTime Function() _now;

  final LinkedHashMap<String, DateTime> _seenAt = LinkedHashMap();

  EventDedupeCache({
    required this.ttl,
    required this.maxSize,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// **true**면 중복(처리하면 안 됨), **false**면 신규(처리해야 함)
  bool isDuplicate(String? eventId) {
    if (eventId == null || eventId.isEmpty) return false;

    final now = _now();

    // TTL 만료 정리 (최소 비용으로: 오래된 것부터)
    _evictExpired(now);

    final prev = _seenAt[eventId];
    if (prev != null && now.difference(prev) <= ttl) {
      // LRU 갱신
      _seenAt.remove(eventId);
      _seenAt[eventId] = prev;
      return true;
    }

    _seenAt[eventId] = now;
    _evictOverflow();
    return false;
  }

  void _evictExpired(DateTime now) {
    if (_seenAt.isEmpty) return;
    final keysToRemove = <String>[];
    for (final entry in _seenAt.entries) {
      if (now.difference(entry.value) > ttl) {
        keysToRemove.add(entry.key);
      } else {
        // LinkedHashMap은 insertion order라, 여기서 멈추면 뒤는 더 최신이다.
        break;
      }
    }
    for (final k in keysToRemove) {
      _seenAt.remove(k);
    }
  }

  void _evictOverflow() {
    while (_seenAt.length > maxSize) {
      _seenAt.remove(_seenAt.keys.first);
    }
  }
}

