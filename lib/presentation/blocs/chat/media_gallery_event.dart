import 'package:equatable/equatable.dart';
import '../../../data/models/media_gallery_model.dart';

abstract class MediaGalleryEvent extends Equatable {
  const MediaGalleryEvent();

  @override
  List<Object?> get props => [];
}

class MediaGalleryLoadRequested extends MediaGalleryEvent {
  final int roomId;
  final MediaType type;

  const MediaGalleryLoadRequested({required this.roomId, required this.type});

  @override
  List<Object?> get props => [roomId, type];
}

class MediaGalleryLoadMoreRequested extends MediaGalleryEvent {
  const MediaGalleryLoadMoreRequested();
}
