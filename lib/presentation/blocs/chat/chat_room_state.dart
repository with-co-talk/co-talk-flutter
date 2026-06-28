import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/message.dart';

enum ChatRoomStatus { initial, loading, success, failure }

class ChatRoomState extends Equatable {
  final ChatRoomStatus status;
  final int? roomId;
  final int? currentUserId;
  final List<Message> messages;
  final int? nextCursor;
  final bool hasMore;
  final bool isSending;
  final String? errorMessage;
  final Map<int, String> typingUsers; // userId -> nickname
  final bool isReadMarked; // 읽음 처리 완료 여부
  final bool hasLeft; // 채팅방 나가기 완료 여부
  final bool isOtherUserLeft; // 상대방이 채팅방을 나갔는지 여부
  final int? otherUserId; // 1:1 채팅에서 상대방 ID
  final String? otherUserNickname; // 1:1 채팅에서 상대방 닉네임
  final String? roomName; // 채팅방 이름 (그룹 채팅)
  final ChatRoomType? roomType; // 채팅방 타입 (direct, group, self)
  final bool isReinviting; // 재초대 진행 중 여부
  final bool reinviteSuccess; // 재초대 성공 여부
  final bool isUploadingFile; // 파일 업로드 중 여부
  final double uploadProgress; // 파일 업로드 진행률 (0.0 ~ 1.0)
  final bool isOfflineData; // 오프라인 캐시 데이터 여부
  final Set<String> processedReadEvents; // 처리된 읽음 이벤트 (중복 방지용)
  final bool isLoadingMore; // 추가 메시지 로딩 중 여부 (중복 요청 방지용)
  final bool showScrollToBottomFab;
  final int unreadWhileScrolled;
  final Set<int> blockedUserIds; // 차단된 사용자 ID 목록 (메시지 필터링용)
  final Message? replyToMessage; // 답장 대상 메시지
  final bool isForwarding; // 메시지 전달 진행 중 여부
  final bool forwardSuccess; // 메시지 전달 성공 여부
  final bool showTypingIndicator; // 입력중 표시 설정

  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.roomId,
    this.currentUserId,
    this.messages = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isSending = false,
    this.errorMessage,
    this.typingUsers = const {},
    this.isReadMarked = false,
    this.hasLeft = false,
    this.isOtherUserLeft = false,
    this.otherUserId,
    this.otherUserNickname,
    this.roomName,
    this.roomType,
    this.isReinviting = false,
    this.reinviteSuccess = false,
    this.isUploadingFile = false,
    this.uploadProgress = 0.0,
    this.isOfflineData = false,
    this.processedReadEvents = const {},
    this.isLoadingMore = false,
    this.showScrollToBottomFab = false,
    this.unreadWhileScrolled = 0,
    this.blockedUserIds = const {},
    this.replyToMessage,
    this.isForwarding = false,
    this.forwardSuccess = false,
    this.showTypingIndicator = false,
  });

  /// 채팅방 AppBar에 표시할 제목
  String get displayTitle {
    if (roomType == ChatRoomType.self) return '나와의 채팅';
    if (roomType == ChatRoomType.direct && otherUserNickname != null) {
      return otherUserNickname!;
    }
    if (roomName != null && roomName!.isNotEmpty) return roomName!;
    return '채팅';
  }

  /// 누군가 타이핑 중인지 여부
  bool get isAnyoneTyping => typingUsers.isNotEmpty;

  /// 타이핑 인디케이터 텍스트
  String get typingIndicatorText {
    if (typingUsers.isEmpty) return '';
    if (typingUsers.length == 1) {
      return '${typingUsers.values.first}님이 입력 중...';
    }
    return '${typingUsers.length}명이 입력 중...';
  }

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    int? roomId,
    int? currentUserId,
    List<Message>? messages,
    int? nextCursor,
    bool? hasMore,
    bool? isSending,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearNextCursor = false,
    Map<int, String>? typingUsers,
    bool? isReadMarked,
    bool? hasLeft,
    bool? isOtherUserLeft,
    int? otherUserId,
    String? otherUserNickname,
    String? roomName,
    ChatRoomType? roomType,
    bool? isReinviting,
    bool? reinviteSuccess,
    bool? isUploadingFile,
    double? uploadProgress,
    bool? isOfflineData,
    Set<String>? processedReadEvents,
    bool? isLoadingMore,
    bool? showScrollToBottomFab,
    int? unreadWhileScrolled,
    Set<int>? blockedUserIds,
    Message? replyToMessage,
    bool clearReplyToMessage = false,
    bool? isForwarding,
    bool? forwardSuccess,
    bool? showTypingIndicator,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      currentUserId: currentUserId ?? this.currentUserId,
      messages: messages ?? this.messages,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      typingUsers: typingUsers ?? this.typingUsers,
      isReadMarked: isReadMarked ?? this.isReadMarked,
      hasLeft: hasLeft ?? this.hasLeft,
      isOtherUserLeft: isOtherUserLeft ?? this.isOtherUserLeft,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserNickname: otherUserNickname ?? this.otherUserNickname,
      roomName: roomName ?? this.roomName,
      roomType: roomType ?? this.roomType,
      isReinviting: isReinviting ?? this.isReinviting,
      reinviteSuccess: reinviteSuccess ?? this.reinviteSuccess,
      isUploadingFile: isUploadingFile ?? this.isUploadingFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      processedReadEvents: processedReadEvents ?? this.processedReadEvents,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      showScrollToBottomFab: showScrollToBottomFab ?? this.showScrollToBottomFab,
      unreadWhileScrolled: unreadWhileScrolled ?? this.unreadWhileScrolled,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      replyToMessage: clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      isForwarding: isForwarding ?? this.isForwarding,
      forwardSuccess: forwardSuccess ?? this.forwardSuccess,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roomId,
        currentUserId,
        messages,
        nextCursor,
        hasMore,
        isSending,
        errorMessage,
        typingUsers,
        isReadMarked,
        hasLeft,
        isOtherUserLeft,
        otherUserId,
        otherUserNickname,
        roomName,
        roomType,
        isReinviting,
        reinviteSuccess,
        isUploadingFile,
        uploadProgress,
        isOfflineData,
        processedReadEvents,
        isLoadingMore,
        showScrollToBottomFab,
        unreadWhileScrolled,
        blockedUserIds,
        replyToMessage,
        isForwarding,
        forwardSuccess,
        showTypingIndicator,
      ];
}
