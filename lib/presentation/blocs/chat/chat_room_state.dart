import 'package:equatable/equatable.dart';
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
  final bool isReinviting; // 재초대 진행 중 여부
  final bool reinviteSuccess; // 재초대 성공 여부
  final bool isUploadingFile; // 파일 업로드 중 여부
  final double uploadProgress; // 파일 업로드 진행률 (0.0 ~ 1.0)
  final bool isOfflineData; // 오프라인 캐시 데이터 여부
  final Set<String> processedReadEvents; // 처리된 읽음 이벤트 (중복 방지용)

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
    this.isReinviting = false,
    this.reinviteSuccess = false,
    this.isUploadingFile = false,
    this.uploadProgress = 0.0,
    this.isOfflineData = false,
    this.processedReadEvents = const {},
  });

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
    Map<int, String>? typingUsers,
    bool? isReadMarked,
    bool? hasLeft,
    bool? isOtherUserLeft,
    int? otherUserId,
    String? otherUserNickname,
    bool? isReinviting,
    bool? reinviteSuccess,
    bool? isUploadingFile,
    double? uploadProgress,
    bool? isOfflineData,
    Set<String>? processedReadEvents,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      currentUserId: currentUserId ?? this.currentUserId,
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
      typingUsers: typingUsers ?? this.typingUsers,
      isReadMarked: isReadMarked ?? this.isReadMarked,
      hasLeft: hasLeft ?? this.hasLeft,
      isOtherUserLeft: isOtherUserLeft ?? this.isOtherUserLeft,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserNickname: otherUserNickname ?? this.otherUserNickname,
      isReinviting: isReinviting ?? this.isReinviting,
      reinviteSuccess: reinviteSuccess ?? this.reinviteSuccess,
      isUploadingFile: isUploadingFile ?? this.isUploadingFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      processedReadEvents: processedReadEvents ?? this.processedReadEvents,
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
        isReinviting,
        reinviteSuccess,
        isUploadingFile,
        uploadProgress,
        isOfflineData,
        processedReadEvents,
      ];
}
