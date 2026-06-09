import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// 위젯이 처음 마운트될 때 한 번만 슬라이드+페이드 진입 애니메이션을 재생한다.
///
/// [animate] 가 false 이면 애니메이션 없이 [child] 를 그대로 반환한다
/// (초기 로드 메시지처럼 "이미 보인 것"에 적용).
class EntryAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final bool animate;

  const EntryAnimation({
    required this.child,
    this.duration = AppMotion.normal,
    this.beginOffset = const Offset(0, 0.12),
    this.animate = true,
    super.key,
  });

  @override
  State<EntryAnimation> createState() => _EntryAnimationState();
}

class _EntryAnimationState extends State<EntryAnimation>
    with SingleTickerProviderStateMixin {
  // Nullable to avoid LateInitializationError when animate:false.
  // Only assigned in initState when animate is true.
  AnimationController? _controller;
  Animation<double>? _opacity;
  Animation<Offset>? _slide;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;

    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: AppMotion.standard),
    );

    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: AppMotion.standard),
    );

    _controller = controller;
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _opacity;
    final slide = _slide;
    if (!widget.animate || opacity == null || slide == null) {
      return widget.child;
    }

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: widget.child,
      ),
    );
  }
}
