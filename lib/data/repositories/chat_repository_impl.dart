import 'package:injectable/injectable.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/chat_remote_datasource.dart';
import '../models/message_model.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;

  ChatRepositoryImpl(this._remoteDataSource, this._authLocalDataSource);

  Future<int> _getUserId() async {
    final userId = await _authLocalDataSource.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final userId = await _getUserId();
    final chatRoomModels = await _remoteDataSource.getChatRooms(userId);
    return chatRoomModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatRoom> createDirectChatRoom(int otherUserId) async {
    final userId = await _getUserId();
    final chatRoomModel = await _remoteDataSource.createDirectChatRoom(
      userId,
      otherUserId,
    );
    return chatRoomModel.toEntity();
  }

  @override
  Future<ChatRoom> createGroupChatRoom(String? name, List<int> memberIds) async {
    final userId = await _getUserId();
    final chatRoomModel = await _remoteDataSource.createGroupChatRoom(
      userId,
      name,
      memberIds,
    );
    return chatRoomModel.toEntity();
  }

  @override
  Future<void> leaveChatRoom(int roomId) async {
    final userId = await _getUserId();
    await _remoteDataSource.leaveChatRoom(roomId, userId);
  }

  @override
  Future<void> markAsRead(int roomId) async {
    final userId = await _getUserId();
    await _remoteDataSource.markAsRead(roomId, userId);
  }

  @override
  Future<(List<Message>, int?, bool)> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  }) async {
    final userId = await _getUserId();
    final response = await _remoteDataSource.getMessages(
      roomId,
      userId,
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
    final userId = await _getUserId();
    final messageModel = await _remoteDataSource.sendMessage(
      SendMessageRequest(
        senderId: userId,
        chatRoomId: roomId,
        content: content,
      ),
    );
    return messageModel.toEntity(overrideChatRoomId: roomId);
  }

  @override
  Future<Message> updateMessage(int messageId, String content) async {
    final userId = await _getUserId();
    final messageModel = await _remoteDataSource.updateMessage(
      messageId,
      userId,
      content,
    );
    return messageModel.toEntity();
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    final userId = await _getUserId();
    await _remoteDataSource.deleteMessage(messageId, userId);
  }
}
