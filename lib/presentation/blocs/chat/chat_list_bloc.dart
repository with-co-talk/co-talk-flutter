import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

@injectable
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;

  ChatListBloc(this._chatRepository) : super(const ChatListState()) {
    on<ChatListLoadRequested>(_onLoadRequested);
    on<ChatListRefreshRequested>(_onRefreshRequested);
    on<ChatRoomCreated>(_onChatRoomCreated);
    on<GroupChatRoomCreated>(_onGroupChatRoomCreated);
  }

  Future<void> _onLoadRequested(
    ChatListLoadRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));

    try {
      final chatRooms = await _chatRepository.getChatRooms();
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: chatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    ChatListRefreshRequested event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final chatRooms = await _chatRepository.getChatRooms();
      emit(state.copyWith(
        status: ChatListStatus.success,
        chatRooms: chatRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onChatRoomCreated(
    ChatRoomCreated event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      await _chatRepository.createDirectChatRoom(event.otherUserId);
      add(const ChatListRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGroupChatRoomCreated(
    GroupChatRoomCreated event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      await _chatRepository.createGroupChatRoom(event.name, event.memberIds);
      add(const ChatListRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
