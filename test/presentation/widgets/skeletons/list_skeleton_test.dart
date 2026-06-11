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

      // 다크 모드에서 shimmer 대비가 충분한지 검증:
      // baseColor(shade800)와 highlightColor(shade500)가 명확히 다른 색인지 확인.
      // Shimmer.fromColors 의 gradient 구조: [base, base, highlight, base, base]
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      final gradient = shimmer.gradient as LinearGradient;
      final colors = gradient.colors;
      final baseColor = colors[0];      // index 0: base
      final highlightColor = colors[2]; // index 2: highlight
      // shade800 ≈ 0xFF424242, shade500 ≈ 0xFF9E9E9E — red 채널 차이 > 50
      final baseRed = (baseColor.r * 255.0).round().clamp(0, 255);
      final highlightRed = (highlightColor.r * 255.0).round().clamp(0, 255);
      expect(
        (highlightRed - baseRed).abs(),
        greaterThan(50),
        reason: '다크 모드에서 base/highlight 색상 차이가 충분해야 shimmer 스윕이 보임',
      );
    });

    testWidgets('화면이 짧아 콘텐츠가 넘쳐도 오버플로 없이 스크롤 가능하다',
        (WidgetTester tester) async {
      // 매우 짧은 화면(높이 200px)에 itemCount=8(~640px)을 배치해도
      // RenderFlex 오버플로가 발생하지 않아야 한다.
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListSkeleton(),
          ),
        ),
      );

      // 오버플로가 발생하면 pump 단계에서 exception이 기록된다.
      expect(tester.takeException(), isNull);

      // 스크롤 가능해야 하므로 ListView는 NeverScrollableScrollPhysics가 아니어야 한다.
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isNot(isA<NeverScrollableScrollPhysics>()));
    });
  });
}
