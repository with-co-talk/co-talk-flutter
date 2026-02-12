import 'dart:io';

import '../entities/chat_room.dart';
import '../entities/message.dart';

/// 파일 업로드 결과
class FileUploadResult {
  final String fileUrl;
  final String fileName;
  final String contentType;
  final int fileSize;
  final bool isImage;

  const FileUploadResult({
    required this.fileUrl,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.isImage,
  });
}

abstract class ChatRepository {
  Future<List<ChatRoom>> getChatRooms();
  Future<ChatRoom> getChatRoom(int roomId);
  Future<ChatRoom> createDirectChatRoom(int otherUserId);
  Future<ChatRoom> createGroupChatRoom(String? name, List<int> memberIds);
  Future<void> leaveChatRoom(int roomId);
  Future<void> markAsRead(int roomId);
  Future<(List<Message>, int?, bool)> getMessages(
    int roomId, {
    int? size,
    int? beforeMessageId,
  });
  Future<Message> sendMessage(int roomId, String content);
  Future<Message> updateMessage(int messageId, String content);
  Future<void> deleteMessage(int messageId);
  Future<void> reinviteUser(int roomId, int inviteeId);
  Future<Message> replyToMessage(int messageId, String content);
  Future<Message> forwardMessage(int messageId, int targetChatRoomId);

  /// 파일을 서버에 업로드합니다.
  Future<FileUploadResult> uploadFile(File file);

  /// 파일/이미지 메시지를 전송합니다.
  /// senderId는 서버에서 JWT 토큰으로부터 추출합니다.
  Future<Message> sendFileMessage({
    required int roomId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
  });

  // Local-first methods

  /// 로컬 캐시에서 메시지를 가져옵니다.
  Future<List<Message>> getLocalMessages(
    int roomId, {
    int? limit,
    int? beforeMessageId,
  });

  /// 메시지를 검색합니다 (FTS5 전문 검색).
  Future<List<Message>> searchMessages(
    String query, {
    int? chatRoomId,
    int limit = 50,
  });

  /// 로컬에 메시지를 저장합니다 (WebSocket 메시지 수신 시).
  Future<void> saveMessageLocally(Message message);

  /// 로컬 캐시에서 채팅방 목록을 가져옵니다.
  Future<List<ChatRoom>> getLocalChatRooms();

  /// 로컬 데이터를 모두 삭제합니다 (로그아웃 시).
  Future<void> clearLocalData();
}
