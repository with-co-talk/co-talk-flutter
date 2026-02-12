import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/save_image_to_gallery.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/link_preview.dart';
import '../../../../domain/entities/chat_room.dart';
import '../../../blocs/chat/chat_room_bloc.dart';
import '../../../blocs/chat/chat_room_event.dart';
import '../../../blocs/chat/chat_list_bloc.dart';
import '../../../blocs/chat/chat_list_state.dart';
import '../../../blocs/settings/chat_settings_cubit.dart';
import '../../../widgets/link_preview_card.dart';
import '../../../widgets/link_preview_loader.dart';
import '../../../widgets/reaction_display.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'video_player_page.dart';

/// A message bubble widget that displays different types of messages.
/// Handles text, image, and file messages with appropriate styling.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  /// Check if edit time (5 minutes) has expired
  bool get _isEditTimeExpired {
    return DateTime.now().difference(message.createdAt).inMinutes >= 5;
  }

  /// Builds a reply preview shown above the message content
  Widget _buildReplyPreview(BuildContext context) {
    if (message.replyToMessageId == null) return const SizedBox.shrink();

    // Try the embedded replyToMessage first, then look up from BLoC state
    final replyMsg = message.replyToMessage ??
        context.read<ChatRoomBloc>().state.messages
            .where((m) => m.id == message.replyToMessageId)
            .firstOrNull;

    final previewText = replyMsg?.isDeleted == true
        ? '삭제된 메시지'
        : (replyMsg?.content ?? '원본 메시지를 찾을 수 없습니다');
    final senderName = replyMsg?.senderNickname ?? '알 수 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.55,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white.withValues(alpha: 0.5) : AppColors.primary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
            ),
          ),
          Text(
            previewText,
            style: TextStyle(
              fontSize: 12,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : context.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds a "forwarded" indicator shown above the message
  Widget _buildForwardedIndicator(BuildContext context) {
    if (message.forwardedFromMessageId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward,
            size: 12,
            color: isMe ? Colors.white.withValues(alpha: 0.6) : context.textSecondaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '전달됨',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white.withValues(alpha: 0.6) : context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds failed status widget with retry and delete buttons
  Widget _buildFailedStatusWidget(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 전송 실패 아이콘
        Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red[400],
        ),
        const SizedBox(width: 4),
        // 재전송 버튼
        GestureDetector(
          onTap: () {
            if (message.localId != null) {
              context.read<ChatRoomBloc>().add(MessageRetryRequested(message.localId!));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '재전송',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 삭제 버튼
        GestureDetector(
          onTap: () {
            if (message.localId != null) {
              context.read<ChatRoomBloc>().add(PendingMessageDeleteRequested(message.localId!));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '삭제',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns appropriate icon for file type
  IconData _getFileIcon(String? contentType) {
    if (contentType == null) return Icons.insert_drive_file;
    if (contentType.startsWith('image/')) return Icons.image;
    if (contentType.startsWith('video/')) return Icons.videocam;
    if (contentType.startsWith('audio/')) return Icons.audiotrack;
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    }
    if (contentType.contains('sheet') || contentType.contains('excel')) {
      return Icons.table_chart;
    }
    if (contentType.contains('presentation') || contentType.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (contentType.contains('zip') || contentType.contains('rar') || contentType.contains('tar')) {
      return Icons.folder_zip;
    }
    return Icons.insert_drive_file;
  }

  /// Formats file size to human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Builds clickable text spans for URLs in message content
  List<InlineSpan> _buildTextSpans(BuildContext context, String text, Color textColor) {
    final spans = <InlineSpan>[];
    final matches = urlPattern.allMatches(text);

    if (matches.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ));
      return spans;
    }

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.4,
            letterSpacing: 0.1,
          ),
        ));
      }

      final url = match.group(0)!;
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => _openUrl(context, normalizeUrl(url)),
          child: Text(
            url,
            style: TextStyle(
              color: isMe ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
              fontSize: 15,
              height: 1.4,
              letterSpacing: 0.1,
              decoration: TextDecoration.underline,
              decorationColor: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.primary,
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ));
    }

    return spans;
  }

  /// Opens URL in external browser
  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final toOpen = url.contains('://') ? url : normalizeUrl(url);
      final trimmed = toOpen.replaceAll(RegExp(r'[.,;:!?)\]\}>]+$'), '');
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasScheme) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL을 열 수 없습니다: $url')),
          );
        }
        return;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL을 열 수 없습니다: $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL을 열 수 없습니다: $e')),
        );
      }
    }
  }

  /// Shows image options bottom sheet (fullscreen, save to gallery, delete)
  void _showImageOptions(BuildContext context, String imageUrl) {
    final canDelete = isMe && !message.isDeleted && !_isEditTimeExpired;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: const Text('전체 화면 보기'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showFullScreenImage(context, imageUrl);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('갤러리에 저장'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _saveImageToGallery(context, imageUrl);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteConfirmDialog(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows fullscreen image viewer with drag-to-dismiss (KakaoTalk style)
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _DismissibleImageViewer(
            imageUrl: imageUrl,
            onSaveToGallery: kIsWeb ? null : () => _saveImageToGallery(context, imageUrl),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Saves image to gallery (not available on web)
  Future<void> _saveImageToGallery(BuildContext context, String imageUrl) async {
    try {
      await saveImageFromUrlToGallery(imageUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진이 갤러리에 저장되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $message')),
        );
      }
    }
  }

  /// Shows file options bottom sheet (download, delete)
  void _showFileOptions(BuildContext context, String fileUrl, String? fileName) {
    final canDelete = isMe && !message.isDeleted && !_isEditTimeExpired;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('다운로드'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _downloadFile(context, fileUrl, fileName);
                },
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteConfirmDialog(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Downloads file by opening in browser
  Future<void> _downloadFile(BuildContext context, String fileUrl, String? fileName) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('파일을 열 수 없습니다: ${fileName ?? fileUrl}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }


  /// Shows room picker dialog for forwarding a message
  void _showForwardDialog(BuildContext context) {
    final chatListBloc = context.read<ChatListBloc>();
    final chatRoomBloc = context.read<ChatRoomBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: chatListBloc,
        child: _ForwardRoomPickerDialog(
          onRoomSelected: (roomId) {
            chatRoomBloc.add(MessageForwardRequested(
              messageId: message.id,
              targetRoomId: roomId,
            ));
          },
        ),
      ),
    );
  }

  /// Shows edit message dialog
  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메시지 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '메시지를 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                context.read<ChatRoomBloc>().add(MessageUpdateRequested(
                  messageId: message.id,
                  content: newContent,
                ));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  /// Shows delete confirmation dialog
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatRoomBloc>().add(MessageDeleted(message.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// Shows unified emoji + message options bottom sheet
  void _showUnifiedMessageSheet(BuildContext context) {
    if (message.isDeleted) return;

    final canEdit = isMe && !_isEditTimeExpired;
    final canDelete = isMe && !_isEditTimeExpired;
    final quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Quick emoji row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...quickEmojis.map((emoji) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(bottomSheetContext);
                              _addReaction(context, emoji);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        )),
                    // More button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showFullEmojiPicker(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              // Message options
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.primary),
                title: const Text('답장'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<ChatRoomBloc>().add(ReplyToMessageSelected(message));
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.blue),
                title: const Text('전달'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showForwardDialog(context);
                },
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('수정'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showEditDialog(context);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteConfirmDialog(context);
                  },
                ),
              if (!isMe)
                ListTile(
                  leading: const Icon(Icons.report_outlined, color: Colors.orange),
                  title: const Text('신고'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push('/report?type=MESSAGE&targetId=${message.id}');
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Adds a reaction to the message
  void _addReaction(BuildContext context, String emoji) {
    context.read<ChatRoomBloc>().add(ReactionAddRequested(
      messageId: message.id,
      emoji: emoji,
    ));
  }

  /// Toggles reaction (add if not present, remove if already added by current user)
  void _toggleReaction(BuildContext context, String emoji) {
    final currentUserId = context.read<ChatRoomBloc>().state.currentUserId;
    if (currentUserId == null) return;

    final hasMyReaction = message.reactions.any(
      (r) => r.userId == currentUserId && r.emoji == emoji,
    );

    if (hasMyReaction) {
      context.read<ChatRoomBloc>().add(ReactionRemoveRequested(
        messageId: message.id,
        emoji: emoji,
      ));
    } else {
      context.read<ChatRoomBloc>().add(ReactionAddRequested(
        messageId: message.id,
        emoji: emoji,
      ));
    }
  }

  /// Shows full emoji picker in bottom sheet
  void _showFullEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    Navigator.pop(sheetContext);
                    _addReaction(context, emoji.emoji); // Uses outer context correctly
                  },
                  config: const Config(
                    height: 400,
                    emojiViewConfig: EmojiViewConfig(
                      columns: 8,
                      emojiSizeMax: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // System messages are displayed centered
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Time and status widget (카카오톡 스타일)
    Widget timeWidget;

    // 전송 실패 시: 재전송/삭제 버튼
    if (message.isFailed && isMe) {
      timeWidget = _buildFailedStatusWidget(context);
    }
    // 전송 중: 로딩 인디케이터
    else if (message.isPending && isMe) {
      timeWidget = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.primary,
        ),
      );
    }
    // 전송 완료: 읽지 않음 개수 + 시간
    else {
      timeWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.unreadCount > 0 && isMe)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${message.unreadCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ),
          Text(
            AppDateUtils.formatMessageTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 11,
                ),
          ),
        ],
      );
    }

    // Message bubble content
    Widget bubbleWidget;

    // Image message
    if (message.type == MessageType.image && message.fileUrl != null) {
      final imageUrl = message.fileUrl!;
      final chatSettings = context.read<ChatSettingsCubit>().state.settings;
      final autoDownload = chatSettings.autoDownloadImagesOnWifi; // Use wifi setting as the general toggle

      bubbleWidget = _AutoDownloadImageWidget(
        imageUrl: imageUrl,
        isMe: isMe,
        autoDownloadEnabled: autoDownload,
        onTapFullScreen: () => _showFullScreenImage(context, imageUrl),
        onLongPress: _showImageOptions,
      );
    }
    // Video message
    else if (message.fileUrl != null && message.fileContentType?.startsWith('video/') == true) {
      bubbleWidget = GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerPage(
                videoUrl: message.fileUrl!,
                title: message.fileName,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            width: 200,
            height: 150,
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (message.thumbnailUrl != null)
                  Image.network(
                    message.thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // File name and size at the bottom
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          message.fileName ?? '동영상',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // File message
    else if (message.type == MessageType.file && message.fileUrl != null) {
      bubbleWidget = GestureDetector(
        onTap: () => _downloadFile(context, message.fileUrl!, message.fileName),
        onLongPress: () => _showFileOptions(context, message.fileUrl!, message.fileName),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? context.myMessageBubbleColor : context.otherMessageBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(message.fileContentType),
                  color: isMe ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? '파일',
                      style: TextStyle(
                        color: isMe ? Colors.white : context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.fileSize != null)
                          Text(
                            _formatFileSize(message.fileSize!),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : context.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.download,
                          size: 14,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : context.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Text message (default)
    else {
      final textColor = isMe ? Colors.white : context.textPrimaryColor;

      // URL detection (show preview for first URL only)
      final urlMatches = urlPattern.allMatches(message.displayContent);
      final firstUrlRaw = urlMatches.isNotEmpty ? urlMatches.first.group(0) : null;
      final firstUrl = firstUrlRaw != null ? normalizeUrl(firstUrlRaw) : null;

      bubbleWidget = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? context.myMessageBubbleColor : context.otherMessageBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildForwardedIndicator(context),
            _buildReplyPreview(context),
            RichText(
              text: TextSpan(
                children: _buildTextSpans(context, message.displayContent, textColor),
              ),
            ),
            // Link preview
            if (message.hasLinkPreview)
              LinkPreviewCard(
                preview: LinkPreview(
                  url: message.linkPreviewUrl!,
                  title: message.linkPreviewTitle,
                  description: message.linkPreviewDescription,
                  imageUrl: message.linkPreviewImageUrl,
                ),
                isMe: isMe,
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              )
            else if (firstUrl != null)
              LinkPreviewLoader(
                url: firstUrl,
                isMe: isMe,
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: !message.isDeleted ? () => _showUnifiedMessageSheet(context) : null,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Other user's message: avatar + nickname + bubble + time
                if (!isMe) ...[
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profileViewPath(message.senderId)),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: message.senderAvatarUrl != null
                          ? NetworkImage(message.senderAvatarUrl!)
                          : null,
                      child: message.senderAvatarUrl == null
                          ? Text(
                              message.senderNickname?.isNotEmpty == true
                                  ? message.senderNickname![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nickname (tap to go to profile)
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.profileViewPath(message.senderId)),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              message.senderNickname ?? '알 수 없음',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Bubble + time (KakaoTalk style: time on right of bubble)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: bubbleWidget),
                            const SizedBox(width: 6),
                            timeWidget,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                // My message: time + bubble (KakaoTalk style: time on left of bubble)
                if (isMe) ...[
                  timeWidget,
                  const SizedBox(width: 6),
                  Flexible(child: bubbleWidget),
                ],
              ],
            ),
          ),
          // Reaction display
          ReactionDisplay(
            reactions: message.reactions,
            currentUserId: context.read<ChatRoomBloc>().state.currentUserId ?? 0,
            isMe: isMe,
            onReactionTap: (emoji) => _toggleReaction(context, emoji),
          ),
        ],
      ),
    );
  }
}

/// 자동 다운로드 설정에 따라 이미지를 로드하는 위젯
class _AutoDownloadImageWidget extends StatefulWidget {
  final String imageUrl;
  final bool isMe;
  final bool autoDownloadEnabled;
  final VoidCallback onTapFullScreen;
  final Function(BuildContext, String) onLongPress;

  const _AutoDownloadImageWidget({
    required this.imageUrl,
    required this.isMe,
    required this.autoDownloadEnabled,
    required this.onTapFullScreen,
    required this.onLongPress,
  });

  @override
  State<_AutoDownloadImageWidget> createState() => _AutoDownloadImageWidgetState();
}

class _AutoDownloadImageWidgetState extends State<_AutoDownloadImageWidget> {
  late bool _shouldLoad;

  @override
  void initState() {
    super.initState();
    _shouldLoad = widget.autoDownloadEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _shouldLoad = true;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 18),
          ),
          child: Container(
            width: 200,
            height: 150,
            color: context.dividerColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: context.textSecondaryColor,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  '탭하여 이미지 보기',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTapFullScreen,
      onLongPress: () => widget.onLongPress(context, widget.imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
            maxHeight: 250,
          ),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 150,
              color: context.dividerColor,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 150,
              color: context.dividerColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: context.textSecondaryColor, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 드래그로 닫을 수 있는 전체화면 이미지 뷰어 (카카오톡 스타일)
class _DismissibleImageViewer extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onSaveToGallery;

  const _DismissibleImageViewer({
    required this.imageUrl,
    this.onSaveToGallery,
  });

  @override
  State<_DismissibleImageViewer> createState() => _DismissibleImageViewerState();
}

class _DismissibleImageViewerState extends State<_DismissibleImageViewer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragVelocity = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _dismissThreshold = 100;
  static const double _velocityThreshold = 500;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragVelocity = details.velocity.pixelsPerSecond.dy;

    final shouldDismiss = _dragOffset.abs() > _dismissThreshold ||
        _dragVelocity.abs() > _velocityThreshold;

    if (shouldDismiss) {
      Navigator.of(context).pop();
    } else {
      // Snap back to center
      _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
    final scale = (1 - (_dragOffset.abs() / 1000)).clamp(0.8, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: opacity)),
        elevation: 0,
        actions: [
          if (widget.onSaveToGallery != null)
            IconButton(
              icon: Icon(Icons.download_rounded,
                  color: Colors.white.withValues(alpha: opacity)),
              tooltip: '갤러리에 저장',
              onPressed: widget.onSaveToGallery,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: scale,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for selecting a chat room to forward a message to.
class _ForwardRoomPickerDialog extends StatefulWidget {
  final ValueChanged<int> onRoomSelected;

  const _ForwardRoomPickerDialog({required this.onRoomSelected});

  @override
  State<_ForwardRoomPickerDialog> createState() => _ForwardRoomPickerDialogState();
}

class _ForwardRoomPickerDialogState extends State<_ForwardRoomPickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('채팅방 선택'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: '채팅방 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ChatListBloc, ChatListState>(
                builder: (context, state) {
                  final rooms = state.chatRooms.where((room) {
                    if (_searchQuery.isEmpty) return true;
                    final name = room.displayName.toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (rooms.isEmpty) {
                    return const Center(child: Text('채팅방이 없습니다'));
                  }

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            room.type == ChatRoomType.group
                                ? Icons.group
                                : Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          room.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onRoomSelected(room.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
