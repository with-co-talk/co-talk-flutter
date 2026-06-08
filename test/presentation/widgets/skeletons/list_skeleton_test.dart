import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:co_talk_flutter/presentation/widgets/skeletons/list_skeleton.dart';
import 'package:co_talk_flutter/presentation/widgets/skeletons/skeleton_list_tile.dart';

void main() {
  group('ListSkeleton', () {
    testWidgets('기본 itemCount=8 로 Shimmer와 SkeletonListTile 8개를 렌더링한다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListSkeleton(),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonListTile), findsNWidgets(8));
    });

    testWidgets('itemCount=5 로 SkeletonListTile 5개를 렌더링한다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListSkeleton(itemCount: 5),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonListTile), findsNWidgets(5));
    });

    testWidgets('다크 모드에서도 Shimmer와 SkeletonListTile을 렌더링한다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: ListSkeleton(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonListTile), findsNWidgets(3));
    });
  });
}
