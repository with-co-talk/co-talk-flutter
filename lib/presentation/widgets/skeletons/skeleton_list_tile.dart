import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// 채팅/친구 목록 타일 한 줄을 모방한 스켈레톤 위젯.
///
/// 실제 타일과 동일한 패딩(horizontal 16, vertical 12)을 사용한다.
/// 아바타 지름은 화면마다 다르므로([avatarSize]) 실제 타일과 맞추면
/// 로딩→콘텐츠 전환 시 레이아웃 이동을 없앨 수 있다.
/// (예: 채팅 목록 `CircleAvatar(radius: 28)` → 56, 친구 목록 `radius: 35` → 70)
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.avatarSize = 56});

  /// 아바타 원형의 지름(px). 실제 화면의 `CircleAvatar` 지름과 맞춘다.
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 아바타 원형
          SkeletonBox(
            width: avatarSize,
            height: avatarSize,
            borderRadius: avatarSize / 2,
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
