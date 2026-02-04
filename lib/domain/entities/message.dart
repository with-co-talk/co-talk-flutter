import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, system }

class Message extends Equatable {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String? senderNickname;
  final String? senderAvatarUrl;
  final String content;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileContentType;
  final String? thumbnailUrl;
  final int? replyToMessageId;
  final Message? replyToMessage;
  final int? forwardedFromMessageId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<MessageReaction> reactions;
  final int unreadCount;
  /// 링크 미리보기 (텍스트 메시지에 URL 포함 시 서버가 비동기 수집)
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImageUrl;

  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderNickname,
    this.senderAvatarUrl,
    required this.content,
    this.type = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileContentType,
    this.thumbnailUrl,
    this.replyToMessageId,
    this.replyToMessage,
    this.forwardedFromMessageId,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
    this.reactions = const [],
    this.unreadCount = 0,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImageUrl,
  });

  bool get hasLinkPreview =>
      linkPreviewUrl != null &&
      (linkPreviewTitle != null || linkPreviewDescription != null || linkPreviewImageUrl != null);

  bool get isFile => type == MessageType.file || type == MessageType.image;

  bool get isSystemMessage => type == MessageType.system;

  String get displayContent {
    if (isDeleted) {
      return '삭제된 메시지입니다';
    }
    return content;
  }

  Message copyWith({
    int? id,
    int? chatRoomId,
    int? senderId,
    String? senderNickname,
    String? senderAvatarUrl,
    String? content,
    MessageType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileContentType,
    String? thumbnailUrl,
    int? replyToMessageId,
    Message? replyToMessage,
    int? forwardedFromMessageId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageReaction>? reactions,
    int? unreadCount,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileContentType: fileContentType ?? this.fileContentType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardedFromMessageId: forwardedFromMessageId ?? this.forwardedFromMessageId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reactions: reactions ?? this.reactions,
      unreadCount: unreadCount ?? this.unreadCount,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription ?? this.linkPreviewDescription,
      linkPreviewImageUrl: linkPreviewImageUrl ?? this.linkPreviewImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        senderId,
        senderNickname,
        senderAvatarUrl,
        content,
        type,
        fileUrl,
        fileName,
        fileSize,
        fileContentType,
        thumbnailUrl,
        replyToMessageId,
        replyToMessage,
        forwardedFromMessageId,
        isDeleted,
        createdAt,
        updatedAt,
        reactions,
        unreadCount,
        linkPreviewUrl,
        linkPreviewTitle,
        linkPreviewDescription,
        linkPreviewImageUrl,
      ];
}

class MessageReaction extends Equatable {
  final int id;
  final int messageId;
  final int userId;
  final String? userNickname;
  final String emoji;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    this.userNickname,
    required this.emoji,
  });

  @override
  List<Object?> get props => [id, messageId, userId, userNickname, emoji];
}
