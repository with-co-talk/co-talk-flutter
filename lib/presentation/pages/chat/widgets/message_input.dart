import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/message.dart';
import '../../../blocs/chat/chat_room_bloc.dart';
import '../../../blocs/chat/chat_room_event.dart';
import '../../../blocs/chat/chat_room_state.dart';
import '../../image_editor/image_editor_page.dart';

/// Message input widget with attachment options and file upload support.
class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onChanged;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onChanged,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPasteHandling = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    // 키보드가 올라오면 이모지 피커 닫기
    if (widget.focusNode.hasFocus && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // 이모지 피커 닫기 → 키보드 열기
      setState(() {
        _showEmojiPicker = false;
      });
      widget.focusNode.requestFocus();
    } else {
      // 키보드 닫기 → 이모지 피커 열기
      widget.focusNode.unfocus();
      setState(() {
        _showEmojiPicker = true;
      });
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    final newText = text.substring(0, cursorPos) + emoji.emoji + text.substring(cursorPos);
    final newCursorPos = cursorPos + emoji.emoji.length;
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    widget.onChanged?.call();
  }

  void _onBackspacePressed() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos > 0) {
      final newText = text.substring(0, cursorPos - 1) + text.substring(cursorPos);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos - 1),
      );
    }
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  void _handleSend() {
    if (_hasText) {
      widget.onSend();
      // 전송 후 이모지 피커 닫기
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    }
  }

  /// Handles clipboard paste for images
  Future<bool> _handlePaste() async {
    if (_isPasteHandling) return false;
    _isPasteHandling = true;

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        _isPasteHandling = false;
        return false;
      }

      final reader = await clipboard.read();

      // Check for PNG image
      if (reader.canProvide(Formats.png)) {
        final completer = Completer<Uint8List?>();
        reader.getFile(Formats.png, (file) async {
          try {
            final stream = file.getStream();
            final chunks = <int>[];
            await for (final chunk in stream) {
              chunks.addAll(chunk);
            }
            completer.complete(Uint8List.fromList(chunks));
          } catch (e) {
            completer.complete(null);
          }
        }, onError: (e) {
          completer.complete(null);
        });

        final data = await completer.future;
        if (data != null && data.isNotEmpty && mounted) {
          await _saveAndUploadImage(data, 'png');
          _isPasteHandling = false;
          return true;
        }
      }

      // Check for JPEG image
      if (reader.canProvide(Formats.jpeg)) {
        final completer = Completer<Uint8List?>();
        reader.getFile(Formats.jpeg, (file) async {
          try {
            final stream = file.getStream();
            final chunks = <int>[];
            await for (final chunk in stream) {
              chunks.addAll(chunk);
            }
            completer.complete(Uint8List.fromList(chunks));
          } catch (e) {
            completer.complete(null);
          }
        }, onError: (e) {
          completer.complete(null);
        });

        final data = await completer.future;
        if (data != null && data.isNotEmpty && mounted) {
          await _saveAndUploadImage(data, 'jpg');
          _isPasteHandling = false;
          return true;
        }
      }

      _isPasteHandling = false;
      return false;
    } catch (e) {
      debugPrint('[MessageInput] Paste handling error: $e');
      _isPasteHandling = false;
      return false;
    }
  }

  /// Saves image data to temp file and uploads
  Future<void> _saveAndUploadImage(Uint8List data, String extension) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'paste_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(data);

      if (mounted) {
        context.read<ChatRoomBloc>().add(FileAttachmentRequested(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 붙여넣기 실패: $e')),
        );
      }
    }
  }

  /// Handles keyboard events (Ctrl+V / Cmd+V detection)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlOrMeta = HardwareKeyboard.instance.isControlPressed ||
                              HardwareKeyboard.instance.isMetaPressed;

      if (isControlOrMeta && event.logicalKey == LogicalKeyboardKey.keyV) {
        _handlePaste().then((handled) {
          if (handled) {
            debugPrint('[MessageInput] Image pasted and sent successfully');
          }
        });
      }
    }
    return KeyEventResult.ignored;
  }

  /// Shows attachment options bottom sheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('갤러리에서 선택'),
                subtitle: const Text('사진 또는 동영상을 선택합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('카메라'),
                subtitle: const Text('사진을 촬영합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.orange),
                ),
                title: const Text('파일'),
                subtitle: const Text('문서, PDF 등의 파일을 선택합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks and optionally edits image before sending
  Future<void> _pickImageAndSend(String sourcePath) async {
    if (!mounted) return;

    if (sourcePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 경로를 사용할 수 없습니다. 파일 선택을 이용해 주세요.')),
        );
      }
      return;
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 이미지 파일을 찾을 수 없습니다.')),
        );
      }
      return;
    }

    // Open image editor with direct send callback
    await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => ImageEditorPage(
          imageFile: sourceFile,
          onSend: (editedFile) {
            if (mounted) {
              context.read<ChatRoomBloc>().add(FileAttachmentRequested(editedFile.path));
            }
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Picks image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;

      final path = image.path;
      if (path.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.')),
          );
        }
        return;
      }
      await _pickImageAndSend(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 선택할 수 없습니다: $e')),
        );
      }
    }
  }

  /// Captures image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;

      final path = image.path;
      if (path.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('촬영한 이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.')),
          );
        }
        return;
      }
      await _pickImageAndSend(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라를 사용할 수 없습니다: $e')),
        );
      }
    }
  }

  /// Picks file from file picker
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          context.read<ChatRoomBloc>().add(FileAttachmentRequested(filePath));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일을 선택할 수 없습니다: $e')),
        );
      }
    }
  }

  /// 이모지 피커가 모바일에서만 표시되는지 확인
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      buildWhen: (previous, current) =>
          previous.isOtherUserLeft != current.isOtherUserLeft ||
          previous.otherUserNickname != current.otherUserNickname ||
          previous.isUploadingFile != current.isUploadingFile,
      builder: (context, state) {
        // File uploading state
        if (state.isUploadingFile) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '파일 업로드 중...',
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Other user left - show reinvite UI
        if (state.isOtherUserLeft) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: context.textSecondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${state.otherUserNickname ?? "상대방"}님이 채팅방을 나갔습니다',
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.isReinviting
                            ? null
                            : () {
                                final otherUserId = state.otherUserId;
                                if (otherUserId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('상대방 정보를 찾을 수 없습니다'),
                                    ),
                                  );
                                  return;
                                }
                                context.read<ChatRoomBloc>().add(
                                      ReinviteUserRequested(inviteeId: otherUserId),
                                    );
                              },
                        icon: state.isReinviting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(state.isReinviting ? '초대 중...' : '다시 초대하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

        // Normal input
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply preview bar
                if (widget.replyToMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                        bottom: BorderSide(color: context.dividerColor, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.replyToMessage!.senderNickname ?? '알 수 없음',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.replyToMessage!.type == MessageType.image)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.image, size: 14, color: context.textSecondaryColor),
                                    )
                                  else if (widget.replyToMessage!.fileContentType?.startsWith('video/') == true)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.videocam, size: 14, color: context.textSecondaryColor),
                                    )
                                  else if (widget.replyToMessage!.type == MessageType.file)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.attach_file, size: 14, color: context.textSecondaryColor),
                                    ),
                                  Flexible(
                                    child: Text(
                                      widget.replyToMessage!.replyPreviewText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecondaryColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onCancelReply,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  // 이모지 버튼 (모바일만)
                  if (_isMobile)
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard_outlined
                            : Icons.emoji_emotions_outlined,
                        color: _showEmojiPicker
                            ? AppColors.primary
                            : context.textSecondaryColor,
                      ),
                      onPressed: _toggleEmojiPicker,
                      tooltip: _showEmojiPicker ? '키보드' : '이모지',
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: _showAttachmentOptions,
                    tooltip: '첨부',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Focus(
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요',
                            hintStyle: TextStyle(
                              color: context.textSecondaryColor.withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: context.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(
                                color: context.dividerColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                          maxLength: AppConstants.maxMessageLength,
                          buildCounter: (context, {required currentLength, required isFocused, required maxLength}) {
                            if (!isFocused || currentLength < (maxLength! * 0.8)) return null;
                            return Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                fontSize: 12,
                                color: currentLength >= maxLength ? Colors.red : context.textSecondaryColor,
                              ),
                            );
                          },
                          textInputAction: TextInputAction.send,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) {
                            widget.onChanged?.call();
                          },
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<ChatRoomBloc, ChatRoomState>(
                    builder: (context, state) {
                      final canSend = _hasText && !state.isSending;
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: canSend
                              ? AppColors.primary
                              : context.textSecondaryColor.withValues(alpha: 0.3),
                        ),
                        child: IconButton(
                          icon: state.isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: canSend ? _handleSend : null,
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      );
                    },
                  ),
                    ],
                  ),
                ),
                // 이모지 피커
                if (_showEmojiPicker)
                  SizedBox(
                    height: 260,
                    child: EmojiPicker(
                      onEmojiSelected: _onEmojiSelected,
                      onBackspacePressed: _onBackspacePressed,
                      config: Config(
                        emojiViewConfig: EmojiViewConfig(
                          columns: 8,
                          emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          indicatorColor: AppColors.primary,
                          iconColorSelected: AppColors.primary,
                        ),
                        bottomActionBarConfig: const BottomActionBarConfig(
                          enabled: false,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          hintText: '이모지 검색',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
