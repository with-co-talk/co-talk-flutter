import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'skeleton_list_tile.dart';

/// 목록 로딩 상태용 시머 스켈레톤.
///
/// [itemCount] 개의 [SkeletonListTile]을 [Shimmer.fromColors] 로 감싸 반환한다.
/// 스크롤 불가(NeverScrollableScrollPhysics + shrinkWrap)로 구성되어 있으므로
/// 상위 스크롤 뷰 안이나 단독 body 어디에든 배치할 수 있다.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (_, __) => const SkeletonListTile(),
      ),
    );
  }
}
