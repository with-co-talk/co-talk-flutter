import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// 채팅/친구 목록 타일 한 줄을 모방한 스켈레톤 위젯.
///
/// 실제 타일과 동일한 패딩(horizontal 16, vertical 12)을 사용하므로
/// 로딩 중 레이아웃 이동 없이 교체할 수 있다.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 아바타 원형
          const SkeletonBox(
            width: 56,
            height: 56,
            borderRadius: 28,
          ),
          const SizedBox(width: 16),
          // 제목 + 부제 라인
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 라인 (넓음)
                const SkeletonBox(height: 14),
                const SizedBox(height: 8),
                // 부제 라인 (좁음)
                const FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
