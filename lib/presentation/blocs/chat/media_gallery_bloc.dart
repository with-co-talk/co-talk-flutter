import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../data/datasources/remote/chat_remote_datasource.dart';
import 'media_gallery_event.dart';
import 'media_gallery_state.dart';

export 'media_gallery_event.dart';
export 'media_gallery_state.dart';

@injectable
class MediaGalleryBloc extends Bloc<MediaGalleryEvent, MediaGalleryState> {
  final ChatRemoteDataSource _chatRemoteDataSource;

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
        errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    MediaGalleryLoadMoreRequested event,
    Emitter<MediaGalleryState> emit,
  ) async {
    if (!state.hasMore || state.status == MediaGalleryStatus.loading) return;
    if (state.roomId == null || state.currentType == null) return;

    final nextPage = state.currentPage + 1;

    try {
      final response = await _chatRemoteDataSource.getMediaGallery(
        state.roomId!,
        state.currentType!,
        page: nextPage,
      );

      emit(state.copyWith(
        items: [...state.items, ...response.items],
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ErrorMessageMapper.toUserFriendlyMessage(e)));
    }
  }
}
