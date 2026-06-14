import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/datasources/remote/chat_remote_datasource.dart';
import '../../../data/models/media_gallery_model.dart';

// Events
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

// State
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

// Bloc
@injectable
class MediaGalleryBloc extends Bloc<MediaGalleryEvent, MediaGalleryState> {
  final ChatRemoteDataSource _chatRemoteDataSource;

  /// Guards against concurrent load-more fetches. The `status == loading`
  /// guard is insufficient because load-more does not flip status to loading,
  /// so rapid scrolling could fire two LoadMore events that fetch the same
  /// page and append duplicates. This in-flight flag drops the second event.
  bool _isLoadingMore = false;

  MediaGalleryBloc(this._chatRemoteDataSource) : super(const MediaGalleryState()) {
    on<MediaGalleryLoadRequested>(_onLoadRequested);
    on<MediaGalleryLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onLoadRequested(
    MediaGalleryLoadRequested event,
    Emitter<MediaGalleryState> emit,
  ) async {
    emit(state.copyWith(
      status: MediaGalleryStatus.loading,
      roomId: event.roomId,
      currentType: event.type,
      items: [],
      currentPage: 0,
    ));

    try {
      final response = await _chatRemoteDataSource.getMediaGallery(
        event.roomId,
        event.type,
      );

      emit(state.copyWith(
        status: MediaGalleryStatus.success,
        items: response.items,
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MediaGalleryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    MediaGalleryLoadMoreRequested event,
    Emitter<MediaGalleryState> emit,
  ) async {
    if (_isLoadingMore) return;
    if (!state.hasMore || state.status == MediaGalleryStatus.loading) return;
    if (state.roomId == null || state.currentType == null) return;

    _isLoadingMore = true;
    final nextPage = state.currentPage + 1;

    try {
      final response = await _chatRemoteDataSource.getMediaGallery(
        state.roomId!,
        state.currentType!,
        page: nextPage,
      );

      // Deduplicate by messageId so an overlapping page (or a duplicate
      // fetch that slipped through) never renders the same item twice.
      final existingIds = state.items.map((e) => e.messageId).toSet();
      final newItems = response.items
          .where((item) => existingIds.add(item.messageId))
          .toList();

      emit(state.copyWith(
        items: [...state.items, ...newItems],
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      _isLoadingMore = false;
    }
  }
}
