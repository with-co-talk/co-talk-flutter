import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_events.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/widgets/connection_status_banner.dart';

void main() {
  group('ConnectionStatusBanner', () {
    Widget buildBanner(WebSocketConnectionState state) {
      return MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        buildBanner(WebSocketConnectionState.disconnected),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('연결이 끊어졌습니다'), findsOneWidget);
      expect(find.text('재연결'), findsOneWidget);
    });

    testWidgets('failed 상태에서 배너 콘텐츠가 렌더링된다', (tester) async {
      await tester.pumpWidget(buildBanner(WebSocketConnectionState.failed));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('연결 실패 - 재시도가 중단되었습니다'), findsOneWidget);
    });

    testWidgets('connected 상태에서는 배너 콘텐츠가 없고 높이가 0으로 접힌다', (tester) async {
      await tester.pumpWidget(buildBanner(WebSocketConnectionState.connected));
      await tester.pumpAndSettle();

      expect(find.text('연결이 끊어졌습니다'), findsNothing);
      expect(find.text('연결 실패 - 재시도가 중단되었습니다'), findsNothing);

      // AnimatedSize가 완전히 접혀 높이가 0이어야 한다
      final animatedSize = tester.renderObject<RenderBox>(
        find.byType(AnimatedSize),
      );
      expect(animatedSize.size.height, equals(0.0));

      // IgnorePointer가 활성화되어 포인터 이벤트를 차단해야 한다.
      // AnimatedSize 내부에서 첫 번째로 발견되는 IgnorePointer가 우리 것이다.
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(AnimatedSize),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('위젯 트리에 AnimatedSize와 AnimatedOpacity가 존재한다', (tester) async {
      await tester.pumpWidget(
        buildBanner(WebSocketConnectionState.disconnected),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AnimatedSize), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });
  });
}
