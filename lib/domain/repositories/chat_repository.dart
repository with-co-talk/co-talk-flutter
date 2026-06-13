import 'dart:io';

import '../entities/chat_room.dart';
import '../entities/message.dart';

/// 파일 업로드 결과
class FileUploadResult {
  /// 업로드된 객체의 불투명 식별자(저장 객체 키).
  ///
  /// 서버가 내려주면 파일 메시지 전송 시 URL 대신 이 값을 보낸다(서버가 메타 재구성).
  /// 구버전 서버에서는 null일 수 있다.
  final String? objectId;
  final String fileUrl;
  final String fileName;
  final String contentType;
  final int fileSize;
  final bool isImage;

  const FileUploadResult({
    this.objectId,
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

  /// 그룹 채팅방 이미지를 변경합니다.
  Future<void> updateChatRoomImage(int roomId, String imageUrl);

  /// 파일을 서버에 업로드합니다.
  Future<FileUploadResult> uploadFile(File file);

  /// 파일/이미지 메시지를 전송합니다.
  /// senderId는 서버에서 JWT 토큰으로부터 추출합니다.
  ///
  /// [objectId]가 주어지면 서버가 그 불투명 식별자로 URL/메타를 재구성한다(권장).
  /// [fileUrl]은 하위호환(구버전 서버)을 위해 함께 전송된다.
  Future<Message> sendFileMessage({
    required int roomId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? thumbnailUrl,
    String? objectId,
    String? thumbnailObjectId,
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
