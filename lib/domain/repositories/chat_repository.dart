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
}
