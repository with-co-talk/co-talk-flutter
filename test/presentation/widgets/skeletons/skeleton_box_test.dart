import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/widgets/skeletons/skeleton_box.dart';

void main() {
  group('SkeletonBox', () {
    testWidgets('불투명 회색 배경색을 사용한다(반투명 black12 아님)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonBox()),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      // 주석이 단언하는 "불투명 회색"과 일치해야 한다.
      expect(decoration.color, Colors.grey.shade300);
      expect(decoration.color!.a, 1.0);
    });
  });
}
