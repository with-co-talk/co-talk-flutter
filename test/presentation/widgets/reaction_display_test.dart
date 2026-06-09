import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/message.dart';
import 'package:co_talk_flutter/presentation/widgets/reaction_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReactionDisplay', () {
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    List<MessageReaction> _reactions(String emoji, int userId) => [
          MessageReaction(
            id: 1,
            messageId: 10,
            userId: userId,
            emoji: emoji,
          ),
        ];

    testWidgets('리액션 탭 시 selectionClick 햅틱이 발생한다', (tester) async {
      String? tappedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionDisplay(
              reactions: _reactions('👍', 1),
              currentUserId: 1,
              isMe: false,
              onReactionTap: (emoji) => tappedEmoji = emoji,
            ),
          ),
        ),
      );

      await tester.tap(find.text('👍'));
      await tester.pump();

      // 햅틱 호출 검증
      expect(
        calls.any((c) =>
            c.method == 'HapticFeedback.vibrate' &&
            c.arguments == 'HapticFeedbackType.selectionClick'),
        isTrue,
      );
    });

    testWidgets('리액션 탭 시 onReactionTap 콜백이 호출된다', (tester) async {
      String? tappedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionDisplay(
              reactions: _reactions('❤️', 2),
              currentUserId: 1,
              isMe: true,
              onReactionTap: (emoji) => tappedEmoji = emoji,
            ),
          ),
        ),
      );

      await tester.tap(find.text('❤️'));
      await tester.pump();

      expect(tappedEmoji, '❤️');
    });

    testWidgets('위젯 트리에 AnimatedSize가 존재한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionDisplay(
              reactions: _reactions('😂', 3),
              currentUserId: 1,
              isMe: false,
              onReactionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSize), findsOneWidget);
    });
  });
}
