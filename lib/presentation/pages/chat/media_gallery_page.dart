import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_gallery_model.dart';
import '../../../di/injection.dart';
import '../../blocs/chat/media_gallery_bloc.dart';
import '../../widgets/empty_state_view.dart';
import 'widgets/video_player_page.dart';

/// Media gallery page showing photos, files, and links from a chat room.
class MediaGalleryPage extends StatefulWidget {
  final int roomId;

  const MediaGalleryPage({super.key, required this.roomId});

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '미디어 모아보기',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '사진'),
            Tab(text: '파일'),
            Tab(text: '링크'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondaryColor,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: context.dividerColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MediaTab(roomId: widget.roomId, type: MediaType.photo),
          _MediaTab(roomId: widget.roomId, type: MediaType.file),
          _MediaTab(roomId: widget.roomId, type: MediaType.link),
        ],
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  final int roomId;
  final MediaType type;

  const _MediaTab({required this.roomId, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MediaGalleryBloc>()
        ..add(MediaGalleryLoadRequested(roomId: roomId, type: type)),
      child: _MediaTabContent(type: type),
    );
  }
}

class _MediaTabContent extends StatelessWidget {
  final MediaType type;

  const _MediaTabContent({required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaGalleryBloc, MediaGalleryState>(
      builder: (context, state) {
        if (state.status == MediaGalleryStatus.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == MediaGalleryStatus.failure) {
          return EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: '미디어를 불러올 수 없어요',
            subtitle: state.errorMessage ?? '잠시 후 다시 시도해 주세요',
            action: OutlinedButton.icon(
              onPressed: () {
                final bloc = context.read<MediaGalleryBloc>();
                bloc.add(MediaGalleryLoadRequested(
                  roomId: state.roomId!,
                  type: type,
                ));
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('다시 시도'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        }

        if (state.items.isEmpty) {
          return EmptyStateView(
            icon: _getEmptyIcon(),
            title: _getEmptyMessage(),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
              context
                  .read<MediaGalleryBloc>()
                  .add(const MediaGalleryLoadMoreRequested());
            }
            return false;
          },
          child: type == MediaType.photo
              ? _buildPhotoGrid(state.items)
              : _buildListView(state.items),
        );
      },
    );
  }

  IconData _getEmptyIcon() {
    switch (type) {
      case MediaType.photo:
        return Icons.photo_library_outlined;
      case MediaType.file:
        return Icons.folder_outlined;
      case MediaType.link:
        return Icons.link_off;
    }
  }

  String _getEmptyMessage() {
    switch (type) {
      case MediaType.photo:
        return '사진이 없습니다';
      case MediaType.file:
        return '파일이 없습니다';
      case MediaType.link:
        return '링크가 없습니다';
    }
  }

  Widget _buildPhotoGrid(List<MediaGalleryItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _showFullScreenImage(context, item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item.thumbnailUrl ?? item.fileUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: context.dividerColor,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: context.dividerColor,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, MediaGalleryItem item) {
    // Check if it's a video
    if (item.contentType?.startsWith('video/') == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerPage(
            videoUrl: item.fileUrl ?? '',
            title: item.fileName,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: item.fileUrl ?? '',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<MediaGalleryItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        if (type == MediaType.file) {
          return _buildFileItem(context, item);
        } else {
          return _buildLinkItem(context, item);
        }
      },
    );
  }

  /// 공통 카드 셸 — 부드러운 라운드/보더로 미디어 행을 감싼다.
  Widget _mediaCard({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.dividerColor, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, MediaGalleryItem item) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final sizeString = _formatFileSize(item.fileSize ?? 0);

    return _mediaCard(
      context: context,
      onTap: () => _openUrl(item.fileUrl),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.fileName ?? '파일',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sizeString • ${dateFormat.format(item.createdAt)}',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.download_rounded,
            size: 20,
            color: context.textSecondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, MediaGalleryItem item) {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return _mediaCard(
      context: context,
      onTap: () => _openUrl(item.linkPreviewUrl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item.linkPreviewImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.linkPreviewImageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: context.dividerColor,
                      child: Icon(Icons.link_rounded,
                          color: context.textSecondaryColor),
                    ),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.primary),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.linkPreviewTitle ?? item.linkPreviewUrl ?? '링크',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.linkPreviewDescription != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.linkPreviewDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(item.createdAt),
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
