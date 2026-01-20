import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String? senderNickname;
  final String? senderAvatarUrl;
  final String content;
  final String? type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileContentType;
  final String? thumbnailUrl;
  final int? replyToMessageId;
  final MessageModel? replyToMessage;
  final int? forwardedFromMessageId;
  final bool? isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<MessageReactionModel>? reactions;

  const MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderNickname,
    this.senderAvatarUrl,
    required this.content,
    this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileContentType,
    this.thumbnailUrl,
    this.replyToMessageId,
    this.replyToMessage,
    this.forwardedFromMessageId,
    this.isDeleted,
    required this.createdAt,
    this.updatedAt,
    this.reactions,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  Message toEntity() {
    return Message(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderNickname: senderNickname,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      type: _parseMessageType(type),
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileContentType: fileContentType,
      thumbnailUrl: thumbnailUrl,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage?.toEntity(),
      forwardedFromMessageId: forwardedFromMessageId,
      isDeleted: isDeleted ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reactions: reactions?.map((r) => r.toEntity()).toList() ?? [],
    );
  }

  static MessageType _parseMessageType(String? value) {
    switch (value?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

@JsonSerializable()
class MessageReactionModel {
  final int id;
  final int messageId;
  final int userId;
  final String? userNickname;
  final String emoji;

  const MessageReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    this.userNickname,
    required this.emoji,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageReactionModelToJson(this);

  MessageReaction toEntity() {
    return MessageReaction(
      id: id,
      messageId: messageId,
      userId: userId,
      userNickname: userNickname,
      emoji: emoji,
    );
  }
}

@JsonSerializable()
class SendMessageRequest {
  final int senderId;
  final int chatRoomId;
  final String content;

  const SendMessageRequest({
    required this.senderId,
    required this.chatRoomId,
    required this.content,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

@JsonSerializable()
class MessageHistoryResponse {
  final List<MessageModel> messages;
  final String? nextCursor;
  final bool hasMore;

  const MessageHistoryResponse({
    required this.messages,
    this.nextCursor,
    required this.hasMore,
  });

  factory MessageHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageHistoryResponseToJson(this);
}
