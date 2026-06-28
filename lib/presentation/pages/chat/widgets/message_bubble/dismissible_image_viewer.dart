import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../l10n/app_localizations.dart';

/// 드래그로 닫을 수 있는 전체화면 이미지 뷰어 (카카오톡 스타일)
class DismissibleImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final VoidCallback? onSaveToGallery;

  const DismissibleImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.onSaveToGallery,
  });

  @override
  State<DismissibleImageViewer> createState() => _DismissibleImageViewerState();
}

class _DismissibleImageViewerState extends State<DismissibleImageViewer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragVelocity = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // InteractiveViewer 줌 상태 추적용 컨트롤러.
  // scale > 1.0 일 때만 panEnabled = true 로 설정해 드래그-투-디스미스와 충돌 방지.
  final TransformationController _transformationController =
      TransformationController();
  bool _panEnabled = false;

  static const double _dismissThreshold = 100;
  static const double _velocityThreshold = 500;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // panEnabled 분기에 필요한 건 (scale > 1.0) boolean 전환 시점뿐이므로,
    // scale 값 자체가 아니라 boolean 이 직전 값과 달라질 때만 setState 하여
    // 줌 중 build/CachedNetworkImage 의 불필요한 리빌드를 줄인다.
    final panEnabled =
        _transformationController.value.getMaxScaleOnAxis() > 1.0;
    if (panEnabled != _panEnabled) {
      setState(() {
        _panEnabled = panEnabled;
      });
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragVelocity = details.velocity.pixelsPerSecond.dy;

    final shouldDismiss = _dragOffset.abs() > _dismissThreshold ||
        _dragVelocity.abs() > _velocityThreshold;

    if (shouldDismiss) {
      Navigator.of(context).pop();
    } else {
      // Snap back to center
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

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: opacity)),
        elevation: 0,
        actions: [
          if (widget.onSaveToGallery != null)
            IconButton(
              icon: Icon(Icons.download_rounded,
                  color: Colors.white.withValues(alpha: opacity)),
              tooltip: AppLocalizations.of(context)!.chatSaveToGallery,
              onPressed: widget.onSaveToGallery,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: scale,
                child: InteractiveViewer(
                  // scale == 1.0 일 때 pan 을 비활성화하여 드래그-투-디스미스 제스처가 동작하도록 함.
                  // zoom 상태에서는 pan 활성화하여 정상 이동 가능.
                  panEnabled: _panEnabled,
                  transformationController: _transformationController,
                  onInteractionUpdate: _onInteractionUpdate,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Builder(
                    builder: (context) {
                      final image = CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
                        ),
                      );
                      if (widget.heroTag != null) {
                        return Hero(tag: widget.heroTag!, child: image);
                      }
                      return image;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
