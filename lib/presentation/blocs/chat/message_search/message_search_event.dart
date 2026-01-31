import 'package:equatable/equatable.dart';

abstract class MessageSearchEvent extends Equatable {
  const MessageSearchEvent();

  @override
  List<Object?> get props => [];
}

/// 검색 쿼리 변경 이벤트
class MessageSearchQueryChanged extends MessageSearchEvent {
  final String query;
  final int? chatRoomId;

  const MessageSearchQueryChanged({
    required this.query,
    this.chatRoomId,
  });

  @override
  List<Object?> get props => [query, chatRoomId];
}

/// 검색 초기화 이벤트
class MessageSearchCleared extends MessageSearchEvent {
  const MessageSearchCleared();
}

/// 검색 결과에서 메시지 선택 이벤트
class MessageSearchResultSelected extends MessageSearchEvent {
  final int messageId;
  final int chatRoomId;

  const MessageSearchResultSelected({
    required this.messageId,
    required this.chatRoomId,
  });

  @override
  List<Object?> get props => [messageId, chatRoomId];
}
