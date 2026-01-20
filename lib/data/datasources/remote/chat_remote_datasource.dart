import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatRoomModel>> getChatRooms(int userId);
  Future<ChatRoomModel> createDirectChatRoom(int userId1, int userId2);
  Future<ChatRoomModel> createGroupChatRoom(String? name, List<int> memberIds);
  Future<void> leaveChatRoom(int roomId, int userId);
  Future<void> markAsRead(int roomId, int userId);
  Future<MessageHistoryResponse> getMessages(
    int roomId,
    int userId, {
    int? size,
    String? cursor,
  });
  Future<MessageModel> sendMessage(SendMessageRequest request);
  Future<MessageModel> updateMessage(int messageId, int userId, String content);
  Future<void> deleteMessage(int messageId, int userId);
}

@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final DioClient _dioClient;

  ChatRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<ChatRoomModel>> getChatRooms(int userId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.chatRooms,
        queryParameters: {'userId': userId},
      );
      final data = response.data['chatRooms'] as List;
      return data.map((json) => ChatRoomModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ChatRoomModel> createDirectChatRoom(int userId1, int userId2) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.chatRooms,
        data: CreateChatRoomRequest(userId1: userId1, userId2: userId2).toJson(),
      );
      return ChatRoomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ChatRoomModel> createGroupChatRoom(
    String? name,
    List<int> memberIds,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.chatRooms}/group',
        data: CreateGroupChatRoomRequest(name: name, memberIds: memberIds).toJson(),
      );
      return ChatRoomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> leaveChatRoom(int roomId, int userId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.chatRooms}/$roomId/leave',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> markAsRead(int roomId, int userId) async {
    try {
      await _dioClient.post(
        '${ApiConstants.chatRooms}/$roomId/read',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<MessageHistoryResponse> getMessages(
    int roomId,
    int userId, {
    int? size,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{'userId': userId};
      if (size != null) queryParams['size'] = size;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dioClient.get(
        '${ApiConstants.chatMessages}/rooms/$roomId',
        queryParameters: queryParams,
      );
      return MessageHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<MessageModel> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.chatMessages,
        data: request.toJson(),
      );
      return MessageModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<MessageModel> updateMessage(
    int messageId,
    int userId,
    String content,
  ) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.chatMessages}/$messageId',
        data: {'userId': userId, 'content': content},
      );
      return MessageModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteMessage(int messageId, int userId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.chatMessages}/$messageId',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      return ServerException(
        message: e.response!.data?['message'] ?? 'Unknown error',
        statusCode: e.response!.statusCode,
      );
    }
    return const NetworkException(message: '네트워크 오류가 발생했습니다');
  }
}
