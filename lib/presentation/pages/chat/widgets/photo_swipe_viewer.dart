import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// PageView 기반 전체화면 이미지 스와이프 뷰어
///
/// 채팅방 이미지 또는 미디어 갤러리에서 좌우 스와이프로 사진 탐색 가능.
/// 세로 드래그로 닫기, 핀치 줌 지원.
class PhotoSwipeViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  /// 인덱스별 갤러리 저장 콜백. null이면 저장 버튼 숨김.
  final VoidCallback? Function(int index)? onSaveToGallery;

  const PhotoSwipeViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.onSaveToGallery,
  });

  @override
  State<PhotoSwipeViewer> createState() => _PhotoSwipeViewerState();
}

class _PhotoSwipeViewerState extends State<PhotoSwipeViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // Drag-to-dismiss
  double _dragOffset = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Zoom state tracking
  final Map<int, TransformationController> _transformControllers = {};
  bool _isZoomed = false;

  static const double _dismissThreshold = 100;
  static const double _velocityThreshold = 500;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getTransformController(int index) {
    if (!_transformControllers.containsKey(index)) {
      final controller = TransformationController();
      controller.addListener(() {
        final scale = controller.value.getMaxScaleOnAxis();
        final zoomed = scale > 1.05;
        if (zoomed != _isZoomed) {
          setState(() {
            _isZoomed = zoomed;
          });
        }
      });
      _transformControllers[index] = controller;
    }
    return _transformControllers[index]!;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;

    final shouldDismiss = _dragOffset.abs() > _dismissThreshold ||
        velocity.abs() > _velocityThreshold;

    if (shouldDismiss) {
      Navigator.of(context).pop();
    } else {
      _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
    final scale = (1 - (_dragOffset.abs() / 1000)).clamp(0.8, 1.0);
    final saveCallback = widget.onSaveToGallery?.call(_currentIndex);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: opacity)),
        elevation: 0,
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: opacity),
                  fontSize: 16,
                ),
              )
            : null,
        centerTitle: true,
        actions: [
          if (saveCallback != null)
            IconButton(
              icon: Icon(Icons.download_rounded,
                  color: Colors.white.withValues(alpha: opacity)),
              tooltip: '갤러리에 저장',
              onPressed: saveCallback,
            ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Transform.scale(
              scale: scale,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    // 이전 페이지 줌 리셋
                    for (final entry in _transformControllers.entries) {
                      if (entry.key != index) {
                        entry.value.value = Matrix4.identity();
                      }
                    }
                    _isZoomed = false;
                  });
                },
                itemBuilder: (context, index) {
                  final transformController = _getTransformController(index);
                  return InteractiveViewer(
                    transformationController: transformController,
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    onInteractionEnd: (details) {
                      final currentScale =
                          transformController.value.getMaxScaleOnAxis();
                      if (currentScale <= 1.05) {
                        transformController.value = Matrix4.identity();
                      }
                    },
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white54, size: 80),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
