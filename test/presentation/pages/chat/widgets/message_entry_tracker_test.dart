import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/message_entry_tracker.dart';

void main() {
  group('MessageEntryTracker', () {
    test('시드된 초기 키들은 새 것으로 보지 않는다', () {
      final t = MessageEntryTracker()..seedIfNeeded(['a', 'b', 'c']);
      expect(t.registerAndCheckNew('a'), isFalse);
      expect(t.registerAndCheckNew('b'), isFalse);
      expect(t.registerAndCheckNew('c'), isFalse);
    });

    test('seedIfNeeded는 최초 1회만 적용된다', () {
      final t = MessageEntryTracker()..seedIfNeeded(['a']);
      // 두 번째 시드는 무시 → 'b'는 여전히 새 것
      t.seedIfNeeded(['b']);
      expect(t.registerAndCheckNew('b'), isTrue);
    });

    test('시드 후 도착한 키는 처음 1회만 새 것', () {
      final t = MessageEntryTracker()..seedIfNeeded(['a']);
      expect(t.registerAndCheckNew('z'), isTrue); // 새 메시지
      expect(t.registerAndCheckNew('z'), isFalse); // 스크롤 재빌드 → 재생 안 함
    });

    test('시드 전에도 동작하지만, 첫 키는 새 것으로 본다', () {
      final t = MessageEntryTracker();
      expect(t.registerAndCheckNew('a'), isTrue);
      expect(t.registerAndCheckNew('a'), isFalse);
    });

    test('빈 대화방: 빈 집합으로 시드해도 첫 도착 메시지는 새 것으로 본다', () {
      // 빈 방으로 진입 → 시드할 메시지 없음(empty seed).
      final t = MessageEntryTracker()..seedIfNeeded(const <String>[]);
      // 이후 도착한 첫 말풍선은 진입 애니메이션 대상(새 것)이어야 한다.
      expect(t.registerAndCheckNew('first'), isTrue);
      expect(t.registerAndCheckNew('first'), isFalse); // 재빌드 시 재생 안 함
    });
  });
}
