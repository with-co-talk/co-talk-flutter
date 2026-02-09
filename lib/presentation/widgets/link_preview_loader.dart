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

  /// 최대 재시도 횟수
  static const _maxRetries = 2;

  /// 재시도 간격
  static const _retryDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadPreviewWithRetry();
  }

  Future<void> _loadPreviewWithRetry() async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (!mounted) return;

      if (attempt > 0) {
        await Future.delayed(_retryDelay);
        if (!mounted) return;
      }

      try {
        final repository = getIt<LinkPreviewRepository>();
        final preview = await repository.getLinkPreview(widget.url);

        if (mounted && preview.isValid) {
          setState(() {
            _preview = preview;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {
        // 재시도 가능하면 계속
      }
    }

    // 모든 시도 실패
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
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
