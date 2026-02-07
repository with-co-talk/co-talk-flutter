import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_gallery_model.dart';
import '../../../di/injection.dart';
import '../../blocs/chat/media_gallery_bloc.dart';

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
      appBar: AppBar(
        title: const Text('미디어 모아보기'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '사진'),
            Tab(text: '파일'),
            Tab(text: '링크'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(state.errorMessage ?? '미디어를 불러올 수 없습니다'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<MediaGalleryBloc>();
                    bloc.add(MediaGalleryLoadRequested(
                      roomId: state.roomId!,
                      type: type,
                    ));
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _showFullScreenImage(context, item),
          child: CachedNetworkImage(
            imageUrl: item.thumbnailUrl ?? item.fileUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, MediaGalleryItem item) {
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
      separatorBuilder: (_, __) => const Divider(height: 1),
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

  Widget _buildFileItem(BuildContext context, MediaGalleryItem item) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final sizeString = _formatFileSize(item.fileSize ?? 0);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insert_drive_file, color: AppColors.primary),
      ),
      title: Text(
        item.fileName ?? '파일',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$sizeString • ${dateFormat.format(item.createdAt)}',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () => _openUrl(item.fileUrl),
    );
  }

  Widget _buildLinkItem(BuildContext context, MediaGalleryItem item) {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: item.linkPreviewImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.linkPreviewImageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[200],
                  child: const Icon(Icons.link, color: Colors.grey),
                ),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.blue),
            ),
      title: Text(
        item.linkPreviewTitle ?? item.linkPreviewUrl ?? '링크',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.linkPreviewDescription != null)
            Text(
              item.linkPreviewDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          Text(
            dateFormat.format(item.createdAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
      onTap: () => _openUrl(item.linkPreviewUrl),
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
