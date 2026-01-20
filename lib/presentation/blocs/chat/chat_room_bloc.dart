import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;

  ChatRoomBloc(this._chatRepository) : super(const ChatRoomState()) {
    on<ChatRoomOpened>(_onOpened);
    on<ChatRoomClosed>(_onClosed);
    on<MessagesLoadMoreRequested>(_onLoadMore);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<MessageDeleted>(_onMessageDeleted);
  }

  Future<void> _onOpened(
    ChatRoomOpened event,
    Emitter<ChatRoomState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      messages: [],
    ));

    try {
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        event.roomId,
        size: AppConstants.messagePageSize,
      );

      await _chatRepository.markAsRead(event.roomId);

      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatRoomStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    emit(const ChatRoomState());
  }

  Future<void> _onLoadMore(
    MessagesLoadMoreRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (!state.hasMore || state.nextCursor == null || state.roomId == null) {
      return;
    }

    try {
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        state.roomId!,
        size: AppConstants.messagePageSize,
        cursor: state.nextCursor,
      );

      emit(state.copyWith(
        messages: [...state.messages, ...messages],
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.roomId == null) return;

    emit(state.copyWith(isSending: true));

    try {
      final message = await _chatRepository.sendMessage(
        state.roomId!,
        event.content,
      );

      emit(state.copyWith(
        isSending: false,
        messages: [message, ...state.messages],
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatRoomState> emit,
  ) {
    if (state.roomId != event.message.chatRoomId) return;

    // Avoid duplicate messages
    if (state.messages.any((m) => m.id == event.message.id)) return;

    emit(state.copyWith(
      messages: [event.message, ...state.messages],
    ));
  }

  Future<void> _onMessageDeleted(
    MessageDeleted event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);

      final updatedMessages = state.messages.map((m) {
        if (m.id == event.messageId) {
          return m.copyWith(isDeleted: true);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
