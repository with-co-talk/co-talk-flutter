import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/widgets/skeletons/skeleton_list_tile.dart';
import 'package:co_talk_flutter/presentation/widgets/skeletons/skeleton_box.dart';

void main() {
  group('SkeletonListTile', () {
    testWidgets('기본 아바타 지름은 56(채팅 목록 radius 28)이다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonListTile()),
        ),
      );

      final avatar = tester.widget<SkeletonBox>(find.byType(SkeletonBox).first);
      expect(avatar.width, 56);
      expect(avatar.height, 56);
      expect(avatar.borderRadius, 28);
    });

    testWidgets('avatarSize=70(친구 목록 radius 35)을 전달하면 그대로 반영된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonListTile(avatarSize: 70)),
        ),
      );

      final avatar = tester.widget<SkeletonBox>(find.byType(SkeletonBox).first);
      expect(avatar.width, 70);
      expect(avatar.height, 70);
      expect(avatar.borderRadius, 35);
    });
  });
}
