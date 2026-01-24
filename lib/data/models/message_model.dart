import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

/// 서버에서 반환하는 다양한 날짜 형식을 DateTime으로 변환하는 컨버터
class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic json) => DateParser.parse(json);

  @override
  dynamic toJson(DateTime object) => object.toIso8601String();
}

/// nullable DateTime용 컨버터
class NullableDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) => json == null ? null : DateParser.parse(json);

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}

@JsonSerializable()
class MessageModel {
  final int id;
  @JsonKey(defaultValue: 0)
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
  @DateTimeConverter()
  final DateTime createdAt;
  @NullableDateTimeConverter()
  final DateTime? updatedAt;
  final List<MessageReactionModel>? reactions;
  @JsonKey(defaultValue: 0)
  final int unreadCount;

  const MessageModel({
    required this.id,
    this.chatRoomId = 0,
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
    this.unreadCount = 0,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// roomId를 외부에서 주입할 수 있도록 파라미터 추가
  /// (메시지 조회 시 roomId가 응답에 포함되지 않는 경우를 위함)
  Message toEntity({int? overrideChatRoomId}) {
    return Message(
      id: id,
      chatRoomId: overrideChatRoomId ?? chatRoomId,
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
      replyToMessage: replyToMessage?.toEntity(overrideChatRoomId: overrideChatRoomId),
      forwardedFromMessageId: forwardedFromMessageId,
      isDeleted: isDeleted ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reactions: reactions?.map((r) => r.toEntity()).toList() ?? [],
      unreadCount: unreadCount,
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
  final int chatRoomId;
  final String content;

  const SendMessageRequest({
    // senderId는 JWT 토큰에서 추출하므로 제거
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
  final int? nextCursor;
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
