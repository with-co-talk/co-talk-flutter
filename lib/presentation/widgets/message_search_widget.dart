import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/message.dart';
import '../blocs/chat/message_search/message_search_bloc.dart';
import '../blocs/chat/message_search/message_search_event.dart';
import '../blocs/chat/message_search/message_search_state.dart';

/// 메시지 검색 위젯
/// 채팅방 내에서 메시지를 검색할 수 있는 UI를 제공합니다.
class MessageSearchWidget extends StatefulWidget {
  final int chatRoomId;
  final void Function(int messageId) onMessageSelected;
  final VoidCallback? onClose;

  const MessageSearchWidget({
    super.key,
    required this.chatRoomId,
    required this.onMessageSelected,
    this.onClose,
  });

  @override
  State<MessageSearchWidget> createState() => _MessageSearchWidgetState();
}

class _MessageSearchWidgetState extends State<MessageSearchWidget> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 위젯이 표시되면 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<MessageSearchBloc>().add(
          MessageSearchQueryChanged(
            query: query,
            chatRoomId: widget.chatRoomId,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MessageSearchBloc>().add(const MessageSearchCleared());
  }

  void _selectMessage(Message message) {
    widget.onMessageSelected(message.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return BlocBuilder<MessageSearchBloc, MessageSearchState>(
      buildWhen: (previous, current) => previous.query != current.query,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '메시지 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<MessageSearchBloc, MessageSearchState>(
      builder: (context, state) {
        // 로딩 상태
        if (state.status == MessageSearchStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 상태
        if (state.status == MessageSearchStatus.failure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                state.errorMessage ?? '검색 중 오류가 발생했습니다',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 검색 결과 없음
        if (state.status == MessageSearchStatus.success && state.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // 초기 상태 (검색 전)
        if (state.status == MessageSearchStatus.initial && !state.hasQuery) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  '검색어를 입력하세요',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // 검색 결과 목록
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: state.results.length,
          itemBuilder: (context, index) {
            final message = state.results[index];
            return _buildSearchResultItem(message, state.query);
          },
        );
      },
    );
  }

  Widget _buildSearchResultItem(Message message, String query) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _selectMessage(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 발신자 이름
                  Text(
                    message.senderNickname ?? '알 수 없음',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // 날짜/시간
                  Text(
                    AppDateUtils.formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 메시지 내용 (하이라이트 적용)
              _buildHighlightedContent(message.content, query),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedContent(String content, String query) {
    if (query.isEmpty) {
      return Text(
        content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      );
    }

    // 검색어를 하이라이트 표시
    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerContent.indexOf(lowerQuery, start);
      if (index == -1) {
        // 남은 텍스트 추가
        if (start < content.length) {
          spans.add(TextSpan(
            text: content.substring(start),
            style: TextStyle(color: AppColors.textPrimary),
          ));
        }
        break;
      }

      // 매칭 전 텍스트
      if (index > start) {
        spans.add(TextSpan(
          text: content.substring(start, index),
          style: TextStyle(color: AppColors.textPrimary),
        ));
      }

      // 매칭된 텍스트 (하이라이트)
      spans.add(TextSpan(
        text: content.substring(index, index + query.length),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 14),
        children: spans,
      ),
    );
  }
}
