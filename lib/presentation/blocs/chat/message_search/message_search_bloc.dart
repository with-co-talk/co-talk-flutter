import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../domain/repositories/chat_repository.dart';
import 'message_search_event.dart';
import 'message_search_state.dart';

@injectable
class MessageSearchBloc extends Bloc<MessageSearchEvent, MessageSearchState> {
  final ChatRepository _chatRepository;

  static const _debounceDuration = Duration(milliseconds: 300);

  MessageSearchBloc(this._chatRepository) : super(const MessageSearchState()) {
    on<MessageSearchQueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(_debounceDuration)
          .asyncExpand(mapper),
    );
    on<MessageSearchCleared>(_onCleared);
    on<MessageSearchResultSelected>(_onResultSelected);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[MessageSearchBloc] $message');
    }
  }

  Future<void> _onQueryChanged(
    MessageSearchQueryChanged event,
    Emitter<MessageSearchState> emit,
  ) async {
    final query = event.query.trim();

    // 쿼리가 비어있으면 초기화
    if (query.isEmpty) {
      emit(const MessageSearchState());
      return;
    }

    // 쿼리가 너무 짧으면 무시
    if (query.length < 2) {
      emit(state.copyWith(
        query: query,
        chatRoomId: event.chatRoomId,
        results: [],
        status: MessageSearchStatus.initial,
      ));
      return;
    }

    emit(state.copyWith(
      query: query,
      chatRoomId: event.chatRoomId,
      status: MessageSearchStatus.loading,
    ));

    try {
      _log('Searching for: $query, chatRoomId: ${event.chatRoomId}');

      final results = await _chatRepository.searchMessages(
        query,
        chatRoomId: event.chatRoomId,
        limit: 50,
      );

      _log('Found ${results.length} results');

      emit(state.copyWith(
        status: MessageSearchStatus.success,
        results: results,
      ));
    } catch (e, stackTrace) {
      _log('Search error: $e\n$stackTrace');

      emit(state.copyWith(
        status: MessageSearchStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCleared(
    MessageSearchCleared event,
    Emitter<MessageSearchState> emit,
  ) {
    emit(const MessageSearchState());
  }

  void _onResultSelected(
    MessageSearchResultSelected event,
    Emitter<MessageSearchState> emit,
  ) {
    emit(state.copyWith(
      selectedMessageId: event.messageId,
    ));
  }
}
