import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// 자동 다운로드 설정에 따라 이미지를 로드하는 위젯
class AutoDownloadImageWidget extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final bool isMe;
  final bool autoDownloadEnabled;
  final VoidCallback onTapFullScreen;
  final Function(BuildContext, String) onLongPress;

  const AutoDownloadImageWidget({
    super.key,
    required this.imageUrl,
    this.heroTag,
    required this.isMe,
    required this.autoDownloadEnabled,
    required this.onTapFullScreen,
    required this.onLongPress,
  });

  @override
  State<AutoDownloadImageWidget> createState() => _AutoDownloadImageWidgetState();
}

class _AutoDownloadImageWidgetState extends State<AutoDownloadImageWidget> {
  late bool _shouldLoad;

  @override
  void initState() {
    super.initState();
    _shouldLoad = widget.autoDownloadEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _shouldLoad = true;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 18),
          ),
          child: Container(
            width: 200,
            height: 150,
            color: context.dividerColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: context.textSecondaryColor,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.chatTapToViewImage,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 버블 썸네일은 화면상 maxWidth(= 화면폭 * 0.65) 로만 표시되므로,
    // 디바이스 픽셀비를 곱한 적정 폭으로 memCacheWidth 를 지정해 서버 원본 해상도가
    // 그대로 디코딩되어 메모리에 상주하는 것을 방지한다. (전체화면 뷰어는 풀해상도 유지)
    final mq = MediaQuery.of(context);
    final thumbCacheWidth =
        (mq.size.width * 0.65 * mq.devicePixelRatio).round();

    final cachedImage = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: thumbCacheWidth,
      placeholder: (context, url) => Container(
        width: 200,
        height: 150,
        color: context.dividerColor,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 200,
        height: 150,
        color: context.dividerColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: context.textSecondaryColor, size: 40),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.chatImageLoadFailed,
              style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
      bottomRight: Radius.circular(widget.isMe ? 4 : 18),
    );

    // ClipRRect를 Hero 자식으로 넣어 Hero 비행 중에도 동일한 클리핑이 유지되도록 함.
    // (ClipRRect를 Hero 바깥에 두면 비행 오버레이에서는 클리핑이 적용되지 않아 시각적 글리치 발생)
    Widget imageChild = ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
          maxHeight: 250,
        ),
        child: cachedImage,
      ),
    );

    return GestureDetector(
      onTap: widget.onTapFullScreen,
      onLongPress: () => widget.onLongPress(context, widget.imageUrl),
      child: widget.heroTag != null
          ? Hero(
              tag: widget.heroTag!,
              // 비행 중에도 버블 측 둥근 모서리가 자연스럽게 유지됨
              flightShuttleBuilder: (_, animation, direction, __, ___) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    // 출발(버블) → 도착(전체화면) 방향에 따라 radius를 보간
                    final t = direction == HeroFlightDirection.push
                        ? animation.value
                        : 1 - animation.value;
                    final radius = BorderRadius.lerp(
                      borderRadius,
                      BorderRadius.zero,
                      t,
                    )!;
                    return ClipRRect(
                      borderRadius: radius,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                          maxHeight: 250,
                        ),
                        child: cachedImage,
                      ),
                    );
                  },
                );
              },
              child: imageChild,
            )
          : imageChild,
    );
  }
}
