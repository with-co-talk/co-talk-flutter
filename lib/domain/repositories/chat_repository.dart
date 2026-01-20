import '../entities/chat_room.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<List<ChatRoom>> getChatRooms();
  Future<ChatRoom> createDirectChatRoom(int otherUserId);
  Future<ChatRoom> createGroupChatRoom(String? name, List<int> memberIds);
  Future<void> leaveChatRoom(int roomId);
  Future<void> markAsRead(int roomId);
  Future<(List<Message>, String?, bool)> getMessages(
    int roomId, {
    int? size,
    String? cursor,
  });
  Future<Message> sendMessage(int roomId, String content);
  Future<Message> updateMessage(int messageId, String content);
  Future<void> deleteMessage(int messageId);
}
