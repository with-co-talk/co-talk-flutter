import 'package:flutter/material.dart';

/// 시머 스켈레톤의 기본 빌딩 블록.
///
/// [Shimmer] 위젯 아래에 배치하면 Shimmer가 색상을 덮어씌우므로
/// [color] 는 단순 불투명 회색계열을 사용한다.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
