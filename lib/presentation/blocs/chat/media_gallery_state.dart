import 'package:equatable/equatable.dart';
import '../../../data/models/media_gallery_model.dart';

enum MediaGalleryStatus { initial, loading, success, failure }

class MediaGalleryState extends Equatable {
  final MediaGalleryStatus status;
  final List<MediaGalleryItem> items;
  final int? nextCursor;
  final bool hasMore;
  final int currentPage;
  final MediaType? currentType;
  final int? roomId;
  final String? errorMessage;

  const MediaGalleryState({
    this.status = MediaGalleryStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.currentPage = 0,
    this.currentType,
    this.roomId,
    this.errorMessage,
  });

  MediaGalleryState copyWith({
    MediaGalleryStatus? status,
    List<MediaGalleryItem>? items,
    int? nextCursor,
    bool? hasMore,
    int? currentPage,
    MediaType? currentType,
    int? roomId,
    String? errorMessage,
  }) {
    return MediaGalleryState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentType: currentType ?? this.currentType,
      roomId: roomId ?? this.roomId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, nextCursor, hasMore, currentPage, currentType, roomId, errorMessage];
}
