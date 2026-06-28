import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/save_image_to_gallery.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/link_preview.dart';
import '../../../blocs/chat/chat_room_bloc.dart';
import '../../../blocs/chat/chat_room_event.dart';
import '../../../blocs/chat/chat_list_bloc.dart';
import '../../../blocs/settings/chat_settings_cubit.dart';
import '../../../widgets/link_preview_card.dart';
import '../../../widgets/link_preview_loader.dart';
import '../../../widgets/reaction_display.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'message_bubble/auto_download_image_widget.dart';
import 'message_bubble/dismissible_image_viewer.dart';
import 'message_bubble/forward_room_picker_dialog.dart';
import 'message_bubble/message_bubble_parts.dart';

/// A message bubble widget that displays different types of messages.
/// Handles text, image, and file messages with appropriate styling.
///
/// This is a thin dispatcher: per-content-type rendering lives in the
/// `message_bubble/` folder (text/image/video/file/reply/forwarded/system/
/// failed-status widgets), while the long-press action sheets and edit/delete/
/// forward dialogs — which depend on this bubble's [message]/[isMe] and dispatch
/// [ChatRoomBloc] events — remain here.
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
            SnackBar(content: Text(AppLocalizations.of(context)!.chatCannotOpenUrl(url))),
          );
        }
        return;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.chatCannotOpenUrl(url))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatCannotOpenUrl('$e'))),
        );
      }
    }
  }

  /// Shows image options bottom sheet (fullscreen, save to gallery, delete)
  void _showImageOptions(BuildContext context, String imageUrl, {String? heroTag}) {
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
                title: Text(AppLocalizations.of(context)!.chatViewFullScreen),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showFullScreenImage(context, imageUrl, heroTag: heroTag);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(AppLocalizations.of(context)!.chatSaveToGallery),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _saveImageToGallery(context, imageUrl);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.commonDelete, style: const TextStyle(color: Colors.red)),
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
  void _showFullScreenImage(BuildContext context, String imageUrl, {String? heroTag}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DismissibleImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.chatImageSavedToGallery)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatSaveFailed(message))),
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
                title: Text(AppLocalizations.of(context)!.chatDownload),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _downloadFile(context, fileUrl, fileName);
                },
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.commonDelete, style: const TextStyle(color: Colors.red)),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.chatCannotOpenFile(fileName ?? fileUrl))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatDownloadFailed('$e'))),
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
        child: ForwardRoomPickerDialog(
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
        title: Text(AppLocalizations.of(context)!.chatEditMessageTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.chatMessageInputHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
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
            child: Text(AppLocalizations.of(context)!.commonEdit),
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
        title: Text(AppLocalizations.of(context)!.chatDeleteMessageTitle),
        content: Text(AppLocalizations.of(context)!.chatDeleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatRoomBloc>().add(MessageDeleted(message.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }

  /// Shows unified emoji + message options bottom sheet
  void _showUnifiedMessageSheet(BuildContext context) {
    if (message.isDeleted) return;
    AppHaptics.medium();

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
                title: Text(AppLocalizations.of(context)!.chatReply),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<ChatRoomBloc>().add(ReplyToMessageSelected(message));
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.chatForward),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showForwardDialog(context);
                },
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: Text(AppLocalizations.of(context)!.commonEdit),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showEditDialog(context);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.commonDelete, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteConfirmDialog(context);
                  },
                ),
              if (!isMe)
                ListTile(
                  leading: const Icon(Icons.report_outlined, color: Colors.orange),
                  title: Text(AppLocalizations.of(context)!.chatReport),
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

  /// Builds the time + send-status widget shown beside the bubble.
  Widget _buildTimeWidget(BuildContext context) {
    // 전송 실패 시: 재전송/삭제 버튼
    if (message.isFailed && isMe) {
      return FailedStatusWidget(message: message);
    }
    // 전송 중: 로딩 인디케이터
    if (message.isPending && isMe) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.primary,
        ),
      );
    }
    // 전송 완료: 읽지 않음 개수 + 시간
    return Row(
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

  /// Builds the content bubble for the message based on its type.
  Widget _buildBubble(BuildContext context) {
    // Image message
    if (message.type == MessageType.image && message.fileUrl != null) {
      final imageUrl = message.fileUrl!;
      // Hero 태그는 출처(chat 버블 이미지)를 prefix 로 명시해 추후 충돌 추적을 쉽게 한다.
      // TODO(hero-tag): 답장 미리보기 썸네일이나 갤러리 Hero를 추가할 경우
      // 동일 route 안에서 'chat_image_<id>' 태그가 충돌할 수 있음 →
      // 용도별로 네임스페이스를 분리해야 함 (예: 'chat_thumb_<id>', 'gallery_<id>' 등).
      // 디버그 빌드에서 잘못된 id(중복 유발 가능)를 일찍 잡기 위한 가드.
      assert(
        message.id != 0,
        'Hero 태그 생성에 유효한 message.id 가 필요합니다 (중복 태그 방지).',
      );
      final heroTag = 'chat_image_${message.id}';
      final chatSettings = context.read<ChatSettingsCubit>().state.settings;
      final autoDownload = chatSettings.autoDownloadImagesOnWifi; // Use wifi setting as the general toggle

      return AutoDownloadImageWidget(
        imageUrl: imageUrl,
        heroTag: heroTag,
        isMe: isMe,
        autoDownloadEnabled: autoDownload,
        onTapFullScreen: () => _showFullScreenImage(context, imageUrl, heroTag: heroTag),
        onLongPress: (ctx, url) => _showImageOptions(ctx, url, heroTag: heroTag),
      );
    }
    // Video message
    if (message.fileUrl != null && message.fileContentType?.startsWith('video/') == true) {
      return VideoBubble(message: message, isMe: isMe);
    }
    // File message
    if (message.type == MessageType.file && message.fileUrl != null) {
      return FileBubble(
        message: message,
        isMe: isMe,
        onTap: () => _downloadFile(context, message.fileUrl!, message.fileName),
        onLongPress: () => _showFileOptions(context, message.fileUrl!, message.fileName),
      );
    }
    // Text message (default)
    final textColor = isMe ? Colors.white : context.textPrimaryColor;

    // URL detection (show preview for first URL only)
    final urlMatches = urlPattern.allMatches(message.displayContent);
    final firstUrlRaw = urlMatches.isNotEmpty ? urlMatches.first.group(0) : null;
    final firstUrl = firstUrlRaw != null ? normalizeUrl(firstUrlRaw) : null;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // 내 말풍선은 Warm Sand 브랜드 그라데이션, 상대 말풍선은 단색.
        color: isMe ? null : context.otherMessageBubbleColor,
        gradient: isMe
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.myMessageBubbleGradient,
              )
            : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ForwardedIndicator(message: message, isMe: isMe),
          ReplyPreview(message: message, isMe: isMe),
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

  @override
  Widget build(BuildContext context) {
    // System messages are displayed centered
    if (message.isSystemMessage) {
      return SystemMessageBubble(message: message);
    }

    // Time and status widget (카카오톡 스타일)
    final Widget timeWidget = _buildTimeWidget(context);

    // Message bubble content
    final Widget bubbleWidget = _buildBubble(context);

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
                          ? CachedNetworkImageProvider(
                              message.senderAvatarUrl!,
                              maxWidth: 200,
                            )
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
                              message.senderNickname ?? AppLocalizations.of(context)!.chatUnknownSender,
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
