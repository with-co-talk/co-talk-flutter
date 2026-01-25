import 'package:injectable/injectable.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';
import '../models/message_model.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    final chatRoomModels = await _remoteDataSource.getChatRooms();
    return chatRoomModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatRoom> createDirectChatRoom(int otherUserId) async {
    // userId는 JWT 토큰에서 추출하므로 파라미터 불필요
    final chatRoomModel = await _remoteDataSource.createDirectChatRoom(
      otherUserId,
    );
    return chatRoomModel.toEntity();
  }

  @override
  Future<ChatRoom> createGroupChatRoom(String? name, List<int> memberIds) async {
    // creatorId는 JWT 토큰에서 추출하므로 파라미터 불필요
    final chatRoomModel = await _remoteDataSource.createGroupChatRoom(
      name,
      memberIds,
    );
    return chatRoomModel.toEntity();
  }

  @override
  Future<void> leaveChatRoom(int roomId) async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    await _remoteDataSource.leaveChatRoom(roomId);
  }

  @override
  Future<void> markAsRead(int roomId) async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    await _remoteDataSource.markAsRead(roomId);
  }

  @override
  Future<(List<Message>, int?, bool)> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  }) async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    final response = await _remoteDataSource.getMessages(
      roomId,
      size: size,
      beforeMessageId: beforeMessageId,
    );
    return (
      response.messages.map((m) => m.toEntity(overrideChatRoomId: roomId)).toList(),
      response.nextCursor,
      response.hasMore,
    );
  }

  @override
  Future<Message> sendMessage(int roomId, String content) async {
    // senderId는 JWT 토큰에서 추출하므로 파라미터 불필요
    final messageModel = await _remoteDataSource.sendMessage(
      SendMessageRequest(
        chatRoomId: roomId,
        content: content,
      ),
    );
    return messageModel.toEntity(overrideChatRoomId: roomId);
  }

  @override
  Future<Message> updateMessage(int messageId, String content) async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    final messageModel = await _remoteDataSource.updateMessage(
      messageId,
      content,
    );
    return messageModel.toEntity();
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    // JWT 토큰에서 userId를 추출하므로 파라미터 불필요
    await _remoteDataSource.deleteMessage(messageId);
  }
}
