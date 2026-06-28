import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/link_preview.dart';
import '../../l10n/app_localizations.dart';

/// 링크 미리보기 카드 위젯.
/// URL의 OG 메타데이터(제목, 설명, 이미지)를 카드 형태로 표시한다.
class LinkPreviewCard extends StatelessWidget {
  /// 미리보기 정보
  final LinkPreview preview;

  /// 내 메시지 여부 (스타일링용)
  final bool isMe;

  /// 최대 너비
  final double maxWidth;

  const LinkPreviewCard({
    super.key,
    required this.preview,
    this.isMe = false,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    // 유효하지 않은 미리보기는 표시하지 않음
    if (!preview.isValid) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openUrl(context),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.12)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.22)
                : context.dividerColor,
          ),
          boxShadow: isMe
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: context.isDarkMode ? 0.0 : 0.06,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 (있는 경우)
            if (preview.imageUrl != null) _buildImage(context),

            // 텍스트 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 도메인 + 파비콘
                  _buildDomain(context),
                  if (preview.title != null) ...[
                    const SizedBox(height: 6),
                    _buildTitle(context),
                  ],
                  if (preview.description != null) ...[
                    const SizedBox(height: 4),
                    _buildDescription(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지를 빌드한다.
  Widget _buildImage(BuildContext context) {
    final placeholderColor = AppColors.primary.withValues(alpha: 0.08);
    return Container(
      height: 120,
      width: double.infinity,
      color: placeholderColor,
      child: Image.network(
        preview.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: placeholderColor,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.primary.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  /// 도메인 정보를 빌드한다.
  Widget _buildDomain(BuildContext context) {
    final domainColor = isMe ? Colors.white70 : context.textSecondaryColor;
    return Row(
      children: [
        // 파비콘
        if (preview.favicon != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              preview.favicon!,
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) => Icon(
                Icons.language,
                size: 16,
                color: domainColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ] else ...[
          Icon(
            Icons.language,
            size: 16,
            color: domainColor,
          ),
          const SizedBox(width: 6),
        ],
        // 도메인명 또는 사이트명
        Expanded(
          child: Text(
            preview.siteName ?? preview.domain ?? '',
            style: TextStyle(
              fontSize: 12,
              color: domainColor,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 제목을 빌드한다.
  Widget _buildTitle(BuildContext context) {
    return Text(
      preview.title!,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isMe ? Colors.white : context.textPrimaryColor,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 설명을 빌드한다.
  Widget _buildDescription(BuildContext context) {
    return Text(
      preview.description!,
      style: TextStyle(
        fontSize: 12,
        color: isMe
            ? Colors.white.withValues(alpha: 0.8)
            : context.textSecondaryColor,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// URL을 외부 브라우저로 연다.
  Future<void> _openUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(preview.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.widgetCannotOpenUrl(preview.url),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.widgetCannotOpenUrl('$e'),
            ),
          ),
        );
      }
    }
  }
}
