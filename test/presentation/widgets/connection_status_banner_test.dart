import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_events.dart';
import 'package:co_talk_flutter/presentation/widgets/connection_status_banner.dart';

void main() {
  group('ConnectionStatusBanner', () {
    Widget _buildBanner(WebSocketConnectionState state) {
      return MaterialApp(
        home: Scaffold(
          body: ConnectionStatusBanner(
            connectionState: state,
            onReconnect: () {},
          ),
        ),
      );
    }

    testWidgets('disconnected 상태에서 배너 콘텐츠가 렌더링된다', (tester) async {
      await tester.pumpWidget(
        _buildBanner(WebSocketConnectionState.disconnected),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('연결이 끊어졌습니다'), findsOneWidget);
      expect(find.text('재연결'), findsOneWidget);
    });

    testWidgets('failed 상태에서 배너 콘텐츠가 렌더링된다', (tester) async {
      await tester.pumpWidget(
        _buildBanner(WebSocketConnectionState.failed),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('연결 실패 - 재시도가 중단되었습니다'), findsOneWidget);
    });

    testWidgets('connected 상태에서는 배너 콘텐츠가 없다', (tester) async {
      await tester.pumpWidget(
        _buildBanner(WebSocketConnectionState.connected),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('연결이 끊어졌습니다'), findsNothing);
      expect(find.text('연결 실패 - 재시도가 중단되었습니다'), findsNothing);
    });

    testWidgets('위젯 트리에 AnimatedSize와 AnimatedOpacity가 존재한다', (tester) async {
      await tester.pumpWidget(
        _buildBanner(WebSocketConnectionState.disconnected),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AnimatedSize), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });
  });
}
