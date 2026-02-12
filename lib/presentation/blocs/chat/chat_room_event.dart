import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomOpened extends ChatRoomEvent {
  final int roomId;

  const ChatRoomOpened(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class ChatRoomClosed extends ChatRoomEvent {
  const ChatRoomClosed();
}

/// 앱/창이 비활성화되어 채팅방을 "보고 있지 않음" 상태로 전환
class ChatRoomBackgrounded extends ChatRoomEvent {
  const ChatRoomBackgrounded();
}

/// 앱/창이 다시 활성화되어 채팅방을 "보고 있음" 상태로 전환
class ChatRoomForegrounded extends ChatRoomEvent {
  const ChatRoomForegrounded();
}

class MessagesLoadMoreRequested extends ChatRoomEvent {
  const MessagesLoadMoreRequested();
}

class MessageSent extends ChatRoomEvent {
  final String content;

  const MessageSent(this.content);

  @override
  List<Object?> get props => [content];
}

class MessageReceived extends ChatRoomEvent {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageDeleted extends ChatRoomEvent {
  final int messageId;

  const MessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// 다른 사용자에 의해 메시지가 삭제됨 (WebSocket 수신)
class MessageDeletedByOther extends ChatRoomEvent {
  final int messageId;

  const MessageDeletedByOther(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// 다른 사용자에 의해 메시지가 수정됨 (WebSocket 수신)
class MessageUpdatedByOther extends ChatRoomEvent {
  final int messageId;
  final String newContent;

  const MessageUpdatedByOther({
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object?> get props => [messageId, newContent];
}

/// 링크 미리보기 업데이트됨 (WebSocket 수신)
class LinkPreviewUpdated extends ChatRoomEvent {
  final int messageId;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImageUrl;

  const LinkPreviewUpdated({
    required this.messageId,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImageUrl,
  });

  @override
  List<Object?> get props => [messageId, linkPreviewUrl, linkPreviewTitle, linkPreviewDescription, linkPreviewImageUrl];
}

/// 읽음 상태 업데이트 이벤트
class MessagesReadUpdated extends ChatRoomEvent {
  final int userId;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;

  const MessagesReadUpdated({
    required this.userId,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  @override
  List<Object?> get props => [userId, lastReadMessageId, lastReadAt];
}

/// 타이핑 상태 변경 이벤트 (WebSocket 수신)
class TypingStatusChanged extends ChatRoomEvent {
  final int userId;
  final String? userNickname;
  final bool isTyping;

  const TypingStatusChanged({
    required this.userId,
    this.userNickname,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, userNickname, isTyping];
}

/// 사용자가 타이핑 시작 이벤트
class UserStartedTyping extends ChatRoomEvent {
  const UserStartedTyping();
}

/// 사용자가 타이핑 중단 이벤트
class UserStoppedTyping extends ChatRoomEvent {
  const UserStoppedTyping();
}

/// 메시지 수정 요청 이벤트
class MessageUpdateRequested extends ChatRoomEvent {
  final int messageId;
  final String content;

  const MessageUpdateRequested({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [messageId, content];
}

/// 채팅방 나가기 요청 이벤트
class ChatRoomLeaveRequested extends ChatRoomEvent {
  const ChatRoomLeaveRequested();
}

/// 1:1 채팅방에서 나간 상대방 재초대 요청 이벤트
class ReinviteUserRequested extends ChatRoomEvent {
  final int inviteeId;

  const ReinviteUserRequested({required this.inviteeId});

  @override
  List<Object?> get props => [inviteeId];
}

/// 1:1 채팅방에서 상대방이 나감/참여함 상태 변경 이벤트 (WebSocket 수신)
class OtherUserLeftStatusChanged extends ChatRoomEvent {
  final bool isOtherUserLeft;
  final int? relatedUserId;
  final String? relatedUserNickname;

  const OtherUserLeftStatusChanged({
    required this.isOtherUserLeft,
    this.relatedUserId,
    this.relatedUserNickname,
  });

  @override
  List<Object?> get props => [isOtherUserLeft, relatedUserId, relatedUserNickname];
}

/// 파일/이미지 첨부 요청 이벤트
class FileAttachmentRequested extends ChatRoomEvent {
  final String filePath;

  const FileAttachmentRequested(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// 전송 실패 메시지 재전송 요청 이벤트
class MessageRetryRequested extends ChatRoomEvent {
  final String localId;

  const MessageRetryRequested(this.localId);

  @override
  List<Object?> get props => [localId];
}

/// 전송 실패 메시지 삭제 요청 이벤트
class PendingMessageDeleteRequested extends ChatRoomEvent {
  final String localId;

  const PendingMessageDeleteRequested(this.localId);

  @override
  List<Object?> get props => [localId];
}

/// 메시지 전송 결과 이벤트 (내부 사용)
///
/// fire-and-forget 전송 후 BLoC 이벤트 큐를 통해 결과를 처리.
class MessageSendCompleted extends ChatRoomEvent {
  final String localId;
  final bool success;
  final String? error;

  const MessageSendCompleted({
    required this.localId,
    required this.success,
    this.error,
  });

  @override
  List<Object?> get props => [localId, success, error];
}

/// Pending 메시지 타임아웃 체크 이벤트 (내부 사용)
class PendingMessagesTimeoutChecked extends ChatRoomEvent {
  const PendingMessagesTimeoutChecked();
}

/// 같은 채팅방의 푸시알림 클릭 시 갭 복구 요청 이벤트
class ChatRoomRefreshRequested extends ChatRoomEvent {
  const ChatRoomRefreshRequested();
}

/// 리액션 추가 요청
class ReactionAddRequested extends ChatRoomEvent {
  final int messageId;
  final String emoji;

  const ReactionAddRequested({required this.messageId, required this.emoji});

  @override
  List<Object?> get props => [messageId, emoji];
}

/// 리액션 제거 요청
class ReactionRemoveRequested extends ChatRoomEvent {
  final int messageId;
  final String emoji;

  const ReactionRemoveRequested({required this.messageId, required this.emoji});

  @override
  List<Object?> get props => [messageId, emoji];
}

/// 리액션 이벤트 수신 (WebSocket)
class ReactionEventReceived extends ChatRoomEvent {
  final int messageId;
  final int userId;
  final String? userNickname;
  final String emoji;
  final bool isAdd; // true = added, false = removed
  final int? reactionId;

  const ReactionEventReceived({
    required this.messageId,
    required this.userId,
    this.userNickname,
    required this.emoji,
    required this.isAdd,
    this.reactionId,
  });

  @override
  List<Object?> get props => [messageId, userId, userNickname, emoji, isAdd, reactionId];
}

/// 답장 대상 메시지 선택
class ReplyToMessageSelected extends ChatRoomEvent {
  final Message message;
  const ReplyToMessageSelected(this.message);

  @override
  List<Object?> get props => [message];
}

/// 답장 취소
class ReplyCancelled extends ChatRoomEvent {
  const ReplyCancelled();
}

/// 메시지 전달 요청
class MessageForwardRequested extends ChatRoomEvent {
  final int messageId;
  final int targetRoomId;
  const MessageForwardRequested({required this.messageId, required this.targetRoomId});

  @override
  List<Object?> get props => [messageId, targetRoomId];
}
