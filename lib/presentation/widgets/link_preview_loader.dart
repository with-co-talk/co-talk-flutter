import 'package:flutter/material.dart';

import '../../di/injection.dart';
import '../../domain/entities/link_preview.dart';
import '../../domain/repositories/link_preview_repository.dart';
import 'link_preview_card.dart';

/// 링크 미리보기를 로드하고 표시하는 위젯.
/// URL에서 미리보기 정보를 비동기로 로드하여 [LinkPreviewCard]로 표시한다.
class LinkPreviewLoader extends StatefulWidget {
  /// 미리보기를 로드할 URL
  final String url;

  /// 내 메시지 여부 (스타일링용)
  final bool isMe;

  /// 최대 너비
  final double maxWidth;

  const LinkPreviewLoader({
    super.key,
    required this.url,
    this.isMe = false,
    this.maxWidth = 280,
  });

  @override
  State<LinkPreviewLoader> createState() => _LinkPreviewLoaderState();
}

class _LinkPreviewLoaderState extends State<LinkPreviewLoader> {
  LinkPreview? _preview;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final repository = getIt<LinkPreviewRepository>();
      final preview = await repository.getLinkPreview(widget.url);

      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 에러 발생 시 표시하지 않음
    if (_isLoading || _hasError) {
      return const SizedBox.shrink();
    }

    // 미리보기 정보가 없거나 유효하지 않으면 표시하지 않음
    if (_preview == null || !_preview!.isValid) {
      return const SizedBox.shrink();
    }

    return LinkPreviewCard(
      preview: _preview!,
      isMe: widget.isMe,
      maxWidth: widget.maxWidth,
    );
  }
}
