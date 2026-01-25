import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_parser.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../base_remote_datasource.dart';
import '../local/auth_local_datasource.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatRoomModel>> getChatRooms();
  Future<ChatRoomModel> createDirectChatRoom(int otherUserId);
  Future<ChatRoomModel> createGroupChatRoom(String? name, List<int> memberIds);
  Future<void> leaveChatRoom(int roomId);
  Future<void> markAsRead(int roomId);
  Future<MessageHistoryResponse> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  });
  Future<MessageModel> sendMessage(SendMessageRequest request);
  Future<MessageModel> updateMessage(int messageId, String content);
  Future<void> deleteMessage(int messageId);
}

@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl extends BaseRemoteDataSource
    implements ChatRemoteDataSource {
  final DioClient _dioClient;
  final AuthLocalDataSource _authLocalDataSource;

  ChatRemoteDataSourceImpl(
    this._dioClient,
    this._authLocalDataSource,
  );

  @override
  Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      final response = await _dioClient.get(
        ApiConstants.chatRooms,
      );

      // BaseRemoteDataSource의 extractListFromResponse 사용
      // API 스펙: 응답 키는 'rooms', 하위 호환을 위해 'chatRooms'도 지원
      final data = extractListFromResponse(
        response.data,
        'rooms',
        fallbackKeys: ['chatRooms'],
      );
      
      return data.map((json) {
        try {
          if (json is! Map<String, dynamic>) {
            throw FormatException('Expected Map<String, dynamic>, got ${json.runtimeType}');
          }
          
          // API 응답 형식은 ChatRoomModel과 호환됨
          // createdAt과 lastMessageAt은 DateParser가 자동으로 처리
          // lastMessage는 String?으로 그대로 사용
          return ChatRoomModel.fromJson(json);
        } catch (e) {
          throw ServerException(
            message: '채팅방 목록 데이터 파싱 중 오류가 발생했습니다: ${e.toString()}. 데이터: $json',
            statusCode: null,
          );
        }
      }).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '채팅방 목록을 불러오는 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  @override
  Future<ChatRoomModel> createDirectChatRoom(int otherUserId) async {
    try {
      final currentUserId = await _authLocalDataSource.getUserId();
      if (currentUserId == null) {
        throw ServerException(
          message: '사용자 인증 정보를 찾을 수 없습니다',
          statusCode: 401,
        );
      }
      
      final response = await _dioClient.post(
        ApiConstants.chatRooms,
        data: CreateChatRoomRequest(
          userId1: currentUserId,
          userId2: otherUserId,
        ).toJson(),
      );
      
      // API 응답 형식: {"roomId":..., "message":"..."}
      // 또는 전체 ChatRoomModel 형식
      final responseData = response.data;
      
      if (responseData is Map) {
        // roomId만 있는 경우 (간단한 응답)
        if (responseData.containsKey('roomId') && !responseData.containsKey('id')) {
          final roomId = responseData['roomId'];
          // 최소한의 ChatRoomModel 생성
          // API 스펙: type은 대문자 ('DIRECT', 'GROUP')
          return ChatRoomModel(
            id: roomId is int ? roomId : int.parse(roomId.toString()),
            type: 'DIRECT',
            createdAt: DateTime.now(),
          );
        }
        // 전체 ChatRoomModel 형식인 경우
        return ChatRoomModel.fromJson(responseData as Map<String, dynamic>);
      }
      
      throw ServerException(
        message: '채팅방 생성 응답 형식이 올바르지 않습니다',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '채팅방 생성 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  @override
  Future<ChatRoomModel> createGroupChatRoom(
    String? name,
    List<int> memberIds,
  ) async {
    try {
      // creatorId는 JWT 토큰에서 추출하므로 제거
      final response = await _dioClient.post(
        '${ApiConstants.chatRooms}/group',
        data: CreateGroupChatRoomRequest(
          name: name,
          memberIds: memberIds,
        ).toJson(),
      );

      // API 응답 형식: {"roomId":..., "message":"..."}
      final responseData = response.data;
      if (responseData is Map) {
        if (responseData.containsKey('roomId') && !responseData.containsKey('id')) {
          final roomId = responseData['roomId'];
          return ChatRoomModel(
            id: roomId is int ? roomId : int.parse(roomId.toString()),
            name: name,
            type: 'GROUP',
            createdAt: DateTime.now(),
          );
        }
        return ChatRoomModel.fromJson(responseData as Map<String, dynamic>);
      }

      throw ServerException(
        message: '그룹 채팅방 생성 응답 형식이 올바르지 않습니다',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '그룹 채팅방 생성 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  @override
  Future<void> leaveChatRoom(int roomId) async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      await _dioClient.post(
        '${ApiConstants.chatRooms}/$roomId/leave',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> markAsRead(int roomId) async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      await _dioClient.post(
        '${ApiConstants.chatRooms}/$roomId/read',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<MessageHistoryResponse> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  }) async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter에서 userId 제거
      final queryParams = <String, dynamic>{};
      if (size != null) queryParams['size'] = size;
      if (beforeMessageId != null) queryParams['beforeMessageId'] = beforeMessageId;

      final response = await _dioClient.get(
        '${ApiConstants.chatMessages}/rooms/$roomId',
        queryParameters: queryParams,
      );
      return MessageHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<MessageModel> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.chatMessages,
        data: request.toJson(),
      );
      
      final responseData = response.data;
      if (responseData is! Map) {
        throw ServerException(
          message: '메시지 전송 응답 형식이 올바르지 않습니다',
          statusCode: null,
        );
      }
      
      // API 응답 형식 변환
      // 응답: {"messageId":..., "content":"...", "type":"TEXT", "createdAt":[2026,1,22,3,4,10,946596000], ...}
      // 기대: {"id":..., "chatRoomId":..., "senderId":..., "content":"...", "createdAt":"2026-01-22T03:04:10.946596Z", ...}
      final convertedData = <String, dynamic>{
        // messageId -> id
        'id': responseData['messageId'] ?? responseData['id'],
        // 요청에서 가져온 정보
        'chatRoomId': request.chatRoomId,
        // senderId는 서버 응답에서 가져오거나 JWT에서 추출
        'senderId': responseData['senderId'] ?? 0,
        'content': responseData['content'] ?? request.content,
        'type': responseData['type'],
        'fileUrl': responseData['fileUrl'],
        'fileName': responseData['fileName'],
        'fileSize': responseData['fileSize'],
        'fileContentType': responseData['contentType'],
        'thumbnailUrl': responseData['thumbnailUrl'],
        'replyToMessageId': responseData['replyToMessageId'],
        'forwardedFromMessageId': responseData['forwardedFromMessageId'],
        'isDeleted': responseData['isDeleted'] ?? false,
        // createdAt 배열을 ISO 8601 문자열로 변환
        'createdAt': DateParser.toIso8601String(DateParser.parse(responseData['createdAt'])),
        'updatedAt': responseData['updatedAt'] != null
            ? DateParser.toIso8601String(DateParser.parse(responseData['updatedAt']))
            : null,
        'senderNickname': responseData['senderNickname'],
        'senderAvatarUrl': responseData['senderAvatarUrl'],
        'reactions': responseData['reactions'],
      };
      
      return MessageModel.fromJson(convertedData);
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: '메시지 전송 중 오류가 발생했습니다: ${e.toString()}',
        statusCode: null,
      );
    }
  }
  

  @override
  Future<MessageModel> updateMessage(
    int messageId,
    String content,
  ) async {
    try {
      // JWT 토큰에서 userId를 추출하므로 body에서 userId 제거
      final response = await _dioClient.put(
        '${ApiConstants.chatMessages}/$messageId',
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    try {
      // JWT 토큰에서 userId를 추출하므로 query parameter 불필요
      await _dioClient.delete(
        '${ApiConstants.chatMessages}/$messageId',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

}
