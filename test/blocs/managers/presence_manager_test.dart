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

    test('stopPresencePing 이후에는 주기 ping이 더 이상 나가지 않는다', () {
      fakeAsync((async) {
        presenceManager.startPresencePing(1, 100);
        clearInteractions(mockWebSocketService);

        presenceManager.stopPresencePing();
        async.elapse(const Duration(seconds: 36));

        verifyNever(
            () => mockWebSocketService.sendPresencePing(roomId: any(named: 'roomId')));
      });
    });
  });
}
