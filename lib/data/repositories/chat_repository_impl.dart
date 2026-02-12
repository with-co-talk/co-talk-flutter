import 'dart:io';

import 'package:injectable/injectable.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../datasources/remote/chat_remote_datasource.dart';
import '../models/message_model.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;

  ChatRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      // Fetch from server
      final chatRoomModels = await _remoteDataSource.getChatRooms();
      final chatRooms = chatRoomModels.map((m) => m.toEntity()).toList();

      // Save to local cache (fire-and-forget)
      _localDataSource.saveChatRooms(chatRooms).catchError((_) {});

      return chatRooms;
    } catch (e) {
      // Fallback to cached data on network failure
      try {
        final cachedRooms = await _localDataSource.getChatRooms();
        if (cachedRooms.isNotEmpty) return cachedRooms;
      } catch (_) {
        // Ignore cache errors and rethrow original error
      }
      rethrow;
    }
  }

  @override
  Future<ChatRoom> getChatRoom(int roomId) async {
    final chatRoomModel = await _remoteDataSource.getChatRoom(roomId);
    final chatRoom = chatRoomModel.toEntity();

    // Save to local cache
    await _localDataSource.saveChatRoom(chatRoom);

    return chatRoom;
  }

  @override
  Future<ChatRoom> createDirectChatRoom(int otherUserId) async {
    final chatRoomModel = await _remoteDataSource.createDirectChatRoom(
      otherUserId,
    );
    final chatRoom = chatRoomModel.toEntity();

    // Save to local cache
    await _localDataSource.saveChatRoom(chatRoom);

    return chatRoom;
  }

  @override
  Future<ChatRoom> createGroupChatRoom(String? name, List<int> memberIds) async {
    final chatRoomModel = await _remoteDataSource.createGroupChatRoom(
      name,
      memberIds,
    );
    final chatRoom = chatRoomModel.toEntity();

    // Save to local cache
    await _localDataSource.saveChatRoom(chatRoom);

    return chatRoom;
  }

  @override
  Future<void> leaveChatRoom(int roomId) async {
    await _remoteDataSource.leaveChatRoom(roomId);

    // Remove from local cache
    await _localDataSource.deleteChatRoom(roomId);
  }

  @override
  Future<void> markAsRead(int roomId) async {
    await _remoteDataSource.markAsRead(roomId);

    // Reset unread count in local cache
    await _localDataSource.resetUnreadCount(roomId);
  }

  @override
  Future<(List<Message>, int?, bool)> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  }) async {
    // Fetch from server
    final response = await _remoteDataSource.getMessages(
      roomId,
      size: size,
      beforeMessageId: beforeMessageId,
    );

    final messages = response.messages
        .map((m) => m.toEntity(overrideChatRoomId: roomId))
        .toList();

    // Save to local cache
    await _localDataSource.saveMessages(messages);

    return (
      messages,
      response.nextCursor,
      response.hasMore,
    );
  }

  @override
  Future<Message> sendMessage(int roomId, String content) async {
    final messageModel = await _remoteDataSource.sendMessage(
      SendMessageRequest(
        chatRoomId: roomId,
        content: content,
      ),
    );

    final message = messageModel.toEntity(overrideChatRoomId: roomId);

    // Save to local cache
    await _localDataSource.saveMessage(message);

    // Update last message in chat room
    await _localDataSource.updateLastMessage(
      roomId: roomId,
      lastMessage: content,
      lastMessageType: 'TEXT',
      lastMessageAt: message.createdAt,
    );

    return message;
  }

  @override
  Future<Message> updateMessage(int messageId, String content) async {
    final messageModel = await _remoteDataSource.updateMessage(
      messageId,
      content,
    );

    final message = messageModel.toEntity();

    // Don't save the slim UpdateMessageResponse to local cache — it lacks
    // senderId, createdAt, etc. The BLoC updates the in-memory cache directly.

    return message;
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await _remoteDataSource.deleteMessage(messageId);

    // Mark as deleted in local cache (soft delete)
    await _localDataSource.markMessageAsDeleted(messageId);
  }

  @override
  Future<void> reinviteUser(int roomId, int inviteeId) async {
    await _remoteDataSource.reinviteUser(roomId, inviteeId);

    // Update other user left status in local cache
    await _localDataSource.updateOtherUserLeftStatus(roomId, false);
  }

  @override
  Future<Message> replyToMessage(int messageId, String content) async {
    final messageModel = await _remoteDataSource.replyToMessage(messageId, content);
    final message = messageModel.toEntity();
    await _localDataSource.saveMessage(message);
    return message;
  }

  @override
  Future<Message> forwardMessage(int messageId, int targetChatRoomId) async {
    final messageModel = await _remoteDataSource.forwardMessage(messageId, targetChatRoomId);
    final message = messageModel.toEntity();
    await _localDataSource.saveMessage(message);
    return message;
  }

  @override
  Future<void> updateChatRoomImage(int roomId, String imageUrl) async {
    await _remoteDataSource.updateChatRoomImage(roomId, imageUrl);
  }

  @override
  Future<FileUploadResult> uploadFile(File file) async {
    final response = await _remoteDataSource.uploadFile(file);
    return FileUploadResult(
      fileUrl: response.fileUrl,
      fileName: response.fileName,
      contentType: response.contentType,
      fileSize: response.fileSize,
      isImage: response.isImage,
    );
  }

  @override
  Future<Message> sendFileMessage({
    required int roomId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
  }) async {
    final messageModel = await _remoteDataSource.sendFileMessage(
      SendFileMessageRequest(
        chatRoomId: roomId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
        thumbnailUrl: thumbnailUrl,
      ),
    );

    final message = messageModel.toEntity(overrideChatRoomId: roomId);

    // Save to local cache
    await _localDataSource.saveMessage(message);

    // Update last message in chat room
    final isImage = contentType.startsWith('image/');
    await _localDataSource.updateLastMessage(
      roomId: roomId,
      lastMessage: fileName,
      lastMessageType: isImage ? 'IMAGE' : 'FILE',
      lastMessageAt: message.createdAt,
    );

    return message;
  }

  // Local-first methods

  @override
  Future<List<Message>> getLocalMessages(
    int roomId, {
    int? limit,
    int? beforeMessageId,
  }) async {
    return _localDataSource.getMessages(
      roomId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  @override
  Future<List<Message>> searchMessages(
    String query, {
    int? chatRoomId,
    int limit = 50,
  }) async {
    return _localDataSource.searchMessages(
      query,
      chatRoomId: chatRoomId,
      limit: limit,
    );
  }

  @override
  Future<void> saveMessageLocally(Message message) async {
    await _localDataSource.saveMessage(message);

    // Update last message in chat room cache
    String? messageType;
    switch (message.type) {
      case MessageType.image:
        messageType = 'IMAGE';
        break;
      case MessageType.file:
        messageType = 'FILE';
        break;
      case MessageType.system:
        messageType = 'SYSTEM';
        break;
      default:
        messageType = 'TEXT';
    }

    await _localDataSource.updateLastMessage(
      roomId: message.chatRoomId,
      lastMessage: message.content,
      lastMessageType: messageType,
      lastMessageAt: message.createdAt,
    );
  }

  @override
  Future<List<ChatRoom>> getLocalChatRooms() async {
    return _localDataSource.getChatRooms();
  }

  @override
  Future<void> clearLocalData() async {
    await _localDataSource.clearAllData();
  }
}
