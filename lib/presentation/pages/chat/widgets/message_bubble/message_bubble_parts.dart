import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../domain/entities/message.dart';
import '../../../../blocs/chat/chat_room_bloc.dart';
import '../../../../blocs/chat/chat_room_event.dart';
import 'message_file_format.dart';
import '../video_player_page.dart';

/// Centered system message (e.g. join/leave notices).
class SystemMessageBubble extends StatelessWidget {
  final Message message;

  const SystemMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
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
}

/// Failed-send status row with retry and delete buttons.
class FailedStatusWidget extends StatelessWidget {
  final Message message;

  const FailedStatusWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              AppLocalizations.of(context)!.chatResend,
              style: const TextStyle(
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
              AppLocalizations.of(context)!.commonDelete,
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
}

/// "Forwarded" indicator shown above a forwarded message.
class ForwardedIndicator extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ForwardedIndicator({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
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
            AppLocalizations.of(context)!.chatForwarded,
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
}

/// Reply/quote preview shown above the message content.
class ReplyPreview extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ReplyPreview({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (message.replyToMessageId == null) return const SizedBox.shrink();

    // Try the embedded replyToMessage first, then look up from BLoC state
    final replyMsg = message.replyToMessage ??
        context.read<ChatRoomBloc>().state.messages
            .where((m) => m.id == message.replyToMessageId)
            .firstOrNull;

    final l10n = AppLocalizations.of(context)!;
    final previewText = replyMsg?.isDeleted == true
        ? l10n.chatDeletedMessage
        : (replyMsg?.content ?? l10n.chatOriginalMessageNotFound);
    final senderName = replyMsg?.senderNickname ?? l10n.chatUnknownSender;

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
}

/// Video message bubble with thumbnail + play overlay.
class VideoBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const VideoBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                        message.fileName ?? AppLocalizations.of(context)!.chatVideo,
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
}

/// File message bubble (icon + name + size).
class FileBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                fileIconForContentType(message.fileContentType),
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
                    message.fileName ?? AppLocalizations.of(context)!.chatFileFallback,
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
                          formatFileSize(message.fileSize!),
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
}
