import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'skeleton_list_tile.dart';

/// 목록 로딩 상태용 시머 스켈레톤.
///
/// [itemCount] 개의 [SkeletonListTile]을 [Shimmer.fromColors] 로 감싸 반환한다.
/// 전체화면 단독 body로 배치되는 것이 주 용도이므로 기본 스크롤을 허용한다.
/// 짧은 단말에서 콘텐츠가 가용 높이를 넘어도 오버플로 없이 스크롤된다.
/// [avatarSize] 는 화면별 실제 아바타 지름과 맞춘다(채팅 56, 친구 70 등).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 8, this.avatarSize = 56});

  final int itemCount;

  /// 각 타일 아바타 원형의 지름(px).
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade500 : Colors.grey.shade100,
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, __) => SkeletonListTile(avatarSize: avatarSize),
      ),
    );
  }
}
