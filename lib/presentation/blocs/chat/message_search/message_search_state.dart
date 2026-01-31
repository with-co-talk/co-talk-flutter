import 'package:equatable/equatable.dart';

import '../../../../domain/entities/message.dart';

enum MessageSearchStatus { initial, loading, success, failure }

class MessageSearchState extends Equatable {
  final MessageSearchStatus status;
  final String query;
  final int? chatRoomId;
  final List<Message> results;
  final String? errorMessage;
  final int? selectedMessageId;

  const MessageSearchState({
    this.status = MessageSearchStatus.initial,
    this.query = '',
    this.chatRoomId,
    this.results = const [],
    this.errorMessage,
    this.selectedMessageId,
  });

  /// 검색 결과가 있는지 여부
  bool get hasResults => results.isNotEmpty;

  /// 검색 중인지 여부
  bool get isSearching => status == MessageSearchStatus.loading;

  /// 검색 쿼리가 있는지 여부
  bool get hasQuery => query.trim().isNotEmpty;

  MessageSearchState copyWith({
    MessageSearchStatus? status,
    String? query,
    int? chatRoomId,
    List<Message>? results,
    String? errorMessage,
    int? selectedMessageId,
  }) {
    return MessageSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedMessageId: selectedMessageId ?? this.selectedMessageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        query,
        chatRoomId,
        results,
        errorMessage,
        selectedMessageId,
      ];
}
