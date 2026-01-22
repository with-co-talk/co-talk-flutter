import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/websocket_service.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;

  StreamSubscription<WebSocketChatMessage>? _messageSubscription;

  ChatRoomBloc(this._chatRepository, this._webSocketService)
      : super(const ChatRoomState()) {
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
    // ignore: avoid_print
    print('[ChatRoomBloc] _onOpened called with roomId: ${event.roomId}');

    emit(state.copyWith(
      status: ChatRoomStatus.loading,
      roomId: event.roomId,
      messages: [],
    ));

    try {
      // ignore: avoid_print
      print('[ChatRoomBloc] Fetching messages...');
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        event.roomId,
        size: AppConstants.messagePageSize,
      );
      // ignore: avoid_print
      print('[ChatRoomBloc] Fetched ${messages.length} messages');

      await _chatRepository.markAsRead(event.roomId);

      // WebSocket 구독 시작
      // ignore: avoid_print
      print('[ChatRoomBloc] Calling _subscribeToWebSocket...');
      _subscribeToWebSocket(event.roomId);

      emit(state.copyWith(
        status: ChatRoomStatus.success,
        messages: messages,
        nextCursor: nextCursor,
        hasMore: hasMore,
      ));
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Error in _onOpened: $e');
      // ignore: avoid_print
      print('[ChatRoomBloc] Stack trace: $stackTrace');
      emit(state.copyWith(
        status: ChatRoomStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _subscribeToWebSocket(int roomId) {
    // ignore: avoid_print
    print('[ChatRoomBloc] _subscribeToWebSocket called with roomId: $roomId');

    // 기존 구독 해제
    _messageSubscription?.cancel();

    // WebSocket 채팅방 구독
    _webSocketService.subscribeToChatRoom(roomId);

    // 메시지 수신 리스너
    _messageSubscription = _webSocketService.messages.listen((wsMessage) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Received wsMessage: id=${wsMessage.messageId}, roomId=${wsMessage.chatRoomId}, content=${wsMessage.content}');
      // ignore: avoid_print
      print('[ChatRoomBloc] Current roomId: $roomId, wsMessage.chatRoomId: ${wsMessage.chatRoomId}');
      if (wsMessage.chatRoomId == roomId) {
        // ignore: avoid_print
        print('[ChatRoomBloc] Adding MessageReceived event');
        add(MessageReceived(_convertToMessage(wsMessage)));
      } else {
        // ignore: avoid_print
        print('[ChatRoomBloc] Ignoring message for different room');
      }
    });
  }

  Message _convertToMessage(WebSocketChatMessage wsMessage) {
    return Message(
      id: wsMessage.messageId,
      chatRoomId: wsMessage.chatRoomId,
      senderId: wsMessage.senderId ?? 0,
      content: wsMessage.content,
      type: _parseMessageType(wsMessage.type),
      createdAt: wsMessage.createdAt,
      fileUrl: wsMessage.fileUrl,
      fileName: wsMessage.fileName,
      fileSize: wsMessage.fileSize,
      fileContentType: wsMessage.fileContentType,
      thumbnailUrl: wsMessage.thumbnailUrl,
    );
  }

  MessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  void _onClosed(
    ChatRoomClosed event,
    Emitter<ChatRoomState> emit,
  ) {
    // WebSocket 구독 해제
    if (state.roomId != null) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    _messageSubscription?.cancel();
    _messageSubscription = null;

    emit(const ChatRoomState());
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    if (state.roomId != null) {
      _webSocketService.unsubscribeFromChatRoom(state.roomId!);
    }
    return super.close();
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
        beforeMessageId: state.nextCursor,
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
    // ignore: avoid_print
    print('[ChatRoomBloc] _onMessageReceived called');
    // ignore: avoid_print
    print('[ChatRoomBloc] state.roomId: ${state.roomId}, event.message.chatRoomId: ${event.message.chatRoomId}');

    if (state.roomId != event.message.chatRoomId) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Room ID mismatch, ignoring');
      return;
    }

    // Avoid duplicate messages
    if (state.messages.any((m) => m.id == event.message.id)) {
      // ignore: avoid_print
      print('[ChatRoomBloc] Duplicate message, ignoring');
      return;
    }

    // ignore: avoid_print
    print('[ChatRoomBloc] Adding message to state: ${event.message.content}');
    emit(state.copyWith(
      messages: [event.message, ...state.messages],
    ));
    // ignore: avoid_print
    print('[ChatRoomBloc] State updated, total messages: ${state.messages.length + 1}');
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
