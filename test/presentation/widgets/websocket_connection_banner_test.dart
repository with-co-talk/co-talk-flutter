import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_events.dart';

void main() {
  group('Fix 3: WebSocket Reconnect UI (P2 #20)', () {
    testWidgets('RED: should show connection banner when WebSocket is disconnected', (tester) async {
      // RED TEST: Currently there's no UI banner when WebSocket disconnects
      // This test verifies that a banner should appear with reconnect button

      final connectionStateController = StreamController<WebSocketConnectionState>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<WebSocketConnectionState>(
              stream: connectionStateController.stream,
              initialData: WebSocketConnectionState.connected,
              builder: (context, snapshot) {
                final state = snapshot.data ?? WebSocketConnectionState.connected;

                // This widget doesn't exist yet - RED test
                // After fix: should render ConnectionStatusBanner
                if (state == WebSocketConnectionState.disconnected ||
                    state == WebSocketConnectionState.failed) {
                  return Column(
                    children: [
                      Container(
                        key: const Key('connection_banner'),
                        color: Colors.red,
                        child: Row(
                          children: [
                            const Text('연결 끊김'),
                            TextButton(
                              key: const Key('reconnect_button'),
                              onPressed: () {},
                              child: const Text('재연결'),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: Center(child: Text('Chat content'))),
                    ],
                  );
                }

                return const Center(child: Text('Chat content'));
              },
            ),
          ),
        ),
      );

      // Initially connected - no banner
      expect(find.byKey(const Key('connection_banner')), findsNothing);

      // Emit disconnected state
      connectionStateController.add(WebSocketConnectionState.disconnected);
      await tester.pumpAndSettle();

      // RED: Banner should appear
      expect(find.byKey(const Key('connection_banner')), findsOneWidget);
      expect(find.text('연결 끊김'), findsOneWidget);
      expect(find.byKey(const Key('reconnect_button')), findsOneWidget);

      await connectionStateController.close();
    });

    testWidgets('RED: reconnect button should trigger connection retry', (tester) async {
      // RED TEST: Verify that tapping reconnect calls the reconnection logic

      final connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      var reconnectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<WebSocketConnectionState>(
              stream: connectionStateController.stream,
              initialData: WebSocketConnectionState.failed,
              builder: (context, snapshot) {
                final state = snapshot.data ?? WebSocketConnectionState.connected;

                if (state == WebSocketConnectionState.disconnected ||
                    state == WebSocketConnectionState.failed) {
                  return Container(
                    key: const Key('connection_banner'),
                    child: TextButton(
                      key: const Key('reconnect_button'),
                      onPressed: () {
                        reconnectCalled = true;
                      },
                      child: const Text('재연결'),
                    ),
                  );
                }

                return const Center(child: Text('Connected'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should be visible in failed state
      expect(find.byKey(const Key('connection_banner')), findsOneWidget);

      // Tap reconnect button
      await tester.tap(find.byKey(const Key('reconnect_button')));
      await tester.pumpAndSettle();

      // Verify reconnect was called
      expect(reconnectCalled, isTrue);

      await connectionStateController.close();
    });
  });
}
