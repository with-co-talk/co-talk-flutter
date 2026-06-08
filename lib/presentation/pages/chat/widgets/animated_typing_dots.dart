import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';

/// 타이핑 인디케이터 - 수신 버블 스타일의 3-dot 바운스 애니메이션.
///
/// 각 도트는 [AppMotion] 토큰 기반의 스태거드 루프 애니메이션으로
/// 위아래로 튀는 효과를 연출한다.
class AnimatedTypingDots extends StatefulWidget {
  const AnimatedTypingDots({super.key});

  @override
  State<AnimatedTypingDots> createState() => _AnimatedTypingDotsState();
}

class _AnimatedTypingDotsState extends State<AnimatedTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 전체 사이클: 각 도트가 up/down을 완료하는 총 길이.
  static const Duration _cycleDuration = Duration(milliseconds: 900);

  // 도트 3개 각각의 스태거 오프셋 (0.0 ~ 1.0 상대값)
  static const List<double> _staggerOffsets = [0.0, 0.2, 0.4];

  // 각 도트가 애니메이션에 사용하는 구간 길이 (사이클의 40%)
  static const double _dotInterval = 0.4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _dotAnimation(int index) {
    final start = _staggerOffsets[index];
    final end = (start + _dotInterval).clamp(0.0, 1.0);
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -6.0)
            .chain(CurveTween(curve: AppMotion.emphasized)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -6.0, end: 0.0)
            .chain(CurveTween(curve: AppMotion.decelerate)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
        ? AppColors.otherMessageBubbleDark
        : AppColors.otherMessageBubble;
    final dotColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final offset = _dotAnimation(index).value;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    key: ValueKey('typing_dot_$index'),
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
