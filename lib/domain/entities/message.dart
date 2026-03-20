import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, system }

/// 메시지 전송 상태 (카카오톡 스타일 UI용)
enum MessageSendStatus {
  /// 전송 중 (로딩 표시)
  pending,
  /// 전송 완료 (읽지 않음 개수 표시)
  sent,
  /// 전송 실패 (재전송/삭제 버튼 표시)
  failed,
}

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

  /// 메시지 전송 상태 (낙관적 UI용)
  final MessageSendStatus sendStatus;

  /// 로컬 임시 ID (pending 메시지 매칭용, UUID 형식)
  final String? localId;

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
    this.sendStatus = MessageSendStatus.sent,
    this.localId,
  });

  /// pending 메시지인지 확인
  bool get isPending => sendStatus == MessageSendStatus.pending;

  /// 전송 실패 메시지인지 확인
  bool get isFailed => sendStatus == MessageSendStatus.failed;

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

  /// 답장 프리뷰용 텍스트 (이미지/파일 등 비텍스트 메시지 대응)
  String get replyPreviewText {
    if (isDeleted) return '삭제된 메시지';
    if (content.isNotEmpty) return content;
    switch (type) {
      case MessageType.image:
        return '사진';
      case MessageType.file:
        if (fileContentType?.startsWith('video/') == true) return '동영상';
        return fileName ?? '파일';
      case MessageType.system:
        return '시스템 메시지';
      case MessageType.text:
        return content;
    }
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
    MessageSendStatus? sendStatus,
    String? localId,
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
      sendStatus: sendStatus ?? this.sendStatus,
      localId: localId ?? this.localId,
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
        sendStatus,
        localId,
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
