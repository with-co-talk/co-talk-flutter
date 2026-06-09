/// 어떤 메시지가 "방금 도착한 새 메시지"인지 추적한다.
///
/// 최초 한 번 [seedIfNeeded] 로 현재 보이는 메시지들을 모두 "본 것"으로
/// 등록하면, 이후 [registerAndCheckNew] 가 처음 보는 키에만 true 를 돌려준다.
/// 같은 키를 두 번째로 물으면(스크롤 재빌드 등) false — 진입 애니메이션이
/// 한 번만 재생되도록 한다.
class MessageEntryTracker {
  final Set<String> _seen = <String>{};
  bool _seeded = false;

  /// 최초 빌드 시 1회만: 현재 메시지 키들을 모두 본 것으로 시드한다.
  void seedIfNeeded(Iterable<String> keys) {
    if (_seeded) return;
    _seen.addAll(keys);
    _seeded = true;
  }

  /// 처음 보는 키면 true(이후 자동 기록), 이미 본 키면 false.
  bool registerAndCheckNew(String key) {
    if (_seen.contains(key)) return false;
    _seen.add(key);
    return true;
  }
}
