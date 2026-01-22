// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: (json['id'] as num).toInt(),
  chatRoomId: (json['chatRoomId'] as num?)?.toInt() ?? 0,
  senderId: (json['senderId'] as num).toInt(),
  senderNickname: json['senderNickname'] as String?,
  senderAvatarUrl: json['senderAvatarUrl'] as String?,
  content: json['content'] as String,
  type: json['type'] as String?,
  fileUrl: json['fileUrl'] as String?,
  fileName: json['fileName'] as String?,
  fileSize: (json['fileSize'] as num?)?.toInt(),
  fileContentType: json['fileContentType'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  replyToMessageId: (json['replyToMessageId'] as num?)?.toInt(),
  replyToMessage: json['replyToMessage'] == null
      ? null
      : MessageModel.fromJson(json['replyToMessage'] as Map<String, dynamic>),
  forwardedFromMessageId: (json['forwardedFromMessageId'] as num?)?.toInt(),
  isDeleted: json['isDeleted'] as bool?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updatedAt']),
  reactions: (json['reactions'] as List<dynamic>?)
      ?.map((e) => MessageReactionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatRoomId': instance.chatRoomId,
      'senderId': instance.senderId,
      'senderNickname': instance.senderNickname,
      'senderAvatarUrl': instance.senderAvatarUrl,
      'content': instance.content,
      'type': instance.type,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'fileContentType': instance.fileContentType,
      'thumbnailUrl': instance.thumbnailUrl,
      'replyToMessageId': instance.replyToMessageId,
      'replyToMessage': instance.replyToMessage,
      'forwardedFromMessageId': instance.forwardedFromMessageId,
      'isDeleted': instance.isDeleted,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
      'reactions': instance.reactions,
    };

MessageReactionModel _$MessageReactionModelFromJson(
  Map<String, dynamic> json,
) => MessageReactionModel(
  id: (json['id'] as num).toInt(),
  messageId: (json['messageId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  userNickname: json['userNickname'] as String?,
  emoji: json['emoji'] as String,
);

Map<String, dynamic> _$MessageReactionModelToJson(
  MessageReactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'messageId': instance.messageId,
  'userId': instance.userId,
  'userNickname': instance.userNickname,
  'emoji': instance.emoji,
};

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      senderId: (json['senderId'] as num).toInt(),
      chatRoomId: (json['chatRoomId'] as num).toInt(),
      content: json['content'] as String,
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'senderId': instance.senderId,
      'chatRoomId': instance.chatRoomId,
      'content': instance.content,
    };

MessageHistoryResponse _$MessageHistoryResponseFromJson(
  Map<String, dynamic> json,
) => MessageHistoryResponse(
  messages: (json['messages'] as List<dynamic>)
      .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: (json['nextCursor'] as num?)?.toInt(),
  hasMore: json['hasMore'] as bool,
);

Map<String, dynamic> _$MessageHistoryResponseToJson(
  MessageHistoryResponse instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};
