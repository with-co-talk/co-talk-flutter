import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/managers/presence_manager.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late MockWebSocketService mockWebSocketService;
  late PresenceManager presenceManager;

  setUp(() {
    mockWebSocketService = MockWebSocketService();
    presenceManager = PresenceManager(mockWebSocketService);

    when(() => mockWebSocketService.sendPresencePing(
          roomId: any(named: 'roomId'),
        )).thenReturn(null);
  });

  group('startPresencePing 주기', () {
    test('시작 즉시 ping 1회를 보낸다', () {
      fakeAsync((async) {
        presenceManager.startPresencePing(1, 100);

        verify(() => mockWebSocketService.sendPresencePing(roomId: 1)).called(1);

        presenceManager.dispose();
      });
    });

    test('12초마다 주기적으로 ping을 보낸다 (TTL 30s > 2*ping 24s 보장)', () {
      fakeAsync((async) {
        presenceManager.startPresencePing(1, 100);
        // 즉시 전송된 1회를 소거하고 주기 ping만 검증한다.
        clearInteractions(mockWebSocketService);

        // 11초 시점: 아직 주기가 도래하지 않아 ping이 없어야 한다.
        async.elapse(const Duration(seconds: 11));
        verifyNever(
            () => mockWebSocketService.sendPresencePing(roomId: any(named: 'roomId')));

        // 12초 시점: 첫 주기 ping이 나가야 한다.
        async.elapse(const Duration(seconds: 1));
        verify(() => mockWebSocketService.sendPresencePing(roomId: 1)).called(1);

        // 24초 시점: 두 번째 주기 ping이 나가야 한다.
        async.elapse(const Duration(seconds: 12));
        verify(() => mockWebSocketService.sendPresencePing(roomId: 1)).called(1);

        presenceManager.dispose();
      });
    });

    test('30s TTL 경계 안에 최소 2회 ping이 들어간다(단일 누락 허용 계약)', () {
      // 이 PR의 의도(주석: TTL 30s > 2×ping 24s → 단일 ping 누락에도
      // 시청 중 presence가 만료되지 않음)를 직접 단언한다.
      // t=0 즉시 1회 + t=12s, t=24s 두 번 → 30s 경계 직전까지 총 3회.
      // 주기를 16s 등으로 잘못 늘리면(2×16=32>30) 이 단언이 깨져 계약 위반을 잡는다.
      fakeAsync((async) {
        presenceManager.startPresencePing(1, 100);

        // 30s TTL 직전(29s): 즉시 1회 + 12s + 24s = 총 3회가 송신되어,
        // 단일 ping이 누락되어도 두 번째 ping(24s)이 30s 경계 안에 들어온다.
        async.elapse(const Duration(seconds: 29));
        verify(() => mockWebSocketService.sendPresencePing(roomId: 1)).called(3);

        presenceManager.dispose();
      });
    });

    test('stopPresencePing 이후에는 주기 ping이 더 이상 나가지 않는다', () {
      fakeAsync((async) {
        presenceManager.startPresencePing(1, 100);
        clearInteractions(mockWebSocketService);

        presenceManager.stopPresencePing();
        async.elapse(const Duration(seconds: 36));

        verifyNever(
            () => mockWebSocketService.sendPresencePing(roomId: any(named: 'roomId')));

        presenceManager.dispose();
      });
    });
  });
}
