import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen image editor page using pro_image_editor.
/// Supports drawing, text, emoji, filters, and cropping.
class ImageEditorPage extends StatelessWidget {
  final File imageFile;

  /// Callback when editing is complete and user wants to send.
  /// If provided, the image will be sent directly without returning to the caller.
  final void Function(File editedFile)? onSend;

  const ImageEditorPage({
    super.key,
    required this.imageFile,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProImageEditor.file(
      imageFile,
      configs: ProImageEditorConfigs(
        i18n: I18n(
          various: I18nVarious(
            loadingDialogMsg: l10n.imageEditorProcessing,
            closeEditorWarningTitle: l10n.imageEditorCloseWarningTitle,
            closeEditorWarningMessage: l10n.imageEditorCloseWarningMessage,
            closeEditorWarningConfirmBtn: l10n.commonCancel,
            closeEditorWarningCancelBtn: l10n.imageEditorContinueEditing,
          ),
          paintEditor: I18nPaintingEditor(
            bottomNavigationBarText: l10n.imageEditorPaint,
            freestyle: l10n.imageEditorFreestyle,
            arrow: l10n.imageEditorArrow,
            line: l10n.imageEditorLine,
            rectangle: l10n.imageEditorRectangle,
            circle: l10n.imageEditorCircle,
            dashLine: l10n.imageEditorDashLine,
            lineWidth: l10n.imageEditorLineWidth,
            toggleFill: l10n.imageEditorToggleFill,
            undo: l10n.imageEditorUndo,
            redo: l10n.imageEditorRedo,
            done: l10n.imageEditorDone,
            back: l10n.imageEditorBack,
          ),
          textEditor: I18nTextEditor(
            inputHintText: l10n.imageEditorTextInputHint,
            bottomNavigationBarText: l10n.imageEditorText,
            back: l10n.imageEditorBack,
            done: l10n.imageEditorDone,
          ),
          cropRotateEditor: I18nCropRotateEditor(
            bottomNavigationBarText: l10n.imageEditorCrop,
            rotate: l10n.imageEditorRotate,
            flip: l10n.imageEditorFlip,
            ratio: l10n.imageEditorRatio,
            back: l10n.imageEditorBack,
            done: l10n.imageEditorDone,
            cancel: l10n.commonCancel,
            reset: l10n.imageEditorReset,
          ),
          filterEditor: I18nFilterEditor(
            bottomNavigationBarText: l10n.imageEditorFilter,
            back: l10n.imageEditorBack,
            done: l10n.imageEditorDone,
          ),
          emojiEditor: I18nEmojiEditor(
            bottomNavigationBarText: l10n.imageEditorEmoji,
          ),
          cancel: l10n.commonCancel,
          undo: l10n.imageEditorUndo,
          redo: l10n.imageEditorRedo,
          done: l10n.imageEditorDone,
          remove: l10n.commonDelete,
          doneLoadingMsg: l10n.imageEditorSaving,
        ),
        imageEditorTheme: ImageEditorTheme(
          helperLine: const HelperLineTheme(
            horizontalColor: AppColors.primary,
            verticalColor: AppColors.primary,
          ),
          paintingEditor: const PaintingEditorTheme(
            appBarBackgroundColor: Colors.black,
            appBarForegroundColor: Colors.white,
            background: Colors.black,
            bottomBarColor: Colors.black,
            bottomBarActiveItemColor: AppColors.primary,
            bottomBarInactiveItemColor: Colors.white70,
          ),
          textEditor: const TextEditorTheme(
            appBarBackgroundColor: Colors.black,
            appBarForegroundColor: Colors.white,
            background: Colors.black54,
          ),
          cropRotateEditor: const CropRotateEditorTheme(
            appBarBackgroundColor: Colors.black,
            appBarForegroundColor: Colors.white,
            background: Colors.black,
            cropCornerColor: AppColors.primary,
          ),
          filterEditor: const FilterEditorTheme(
            appBarBackgroundColor: Colors.black,
            appBarForegroundColor: Colors.white,
            background: Colors.black,
          ),
          emojiEditor: const EmojiEditorTheme(),
          background: Colors.black,
          loadingDialogTheme: LoadingDialogTheme(
            textColor: Colors.white,
          ),
        ),
        paintEditorConfigs: const PaintEditorConfigs(
          hasOptionFreeStyle: true,
          hasOptionArrow: true,
          hasOptionLine: true,
          hasOptionRect: true,
          hasOptionCircle: true,
          hasOptionDashLine: true,
        ),
        cropRotateEditorConfigs: const CropRotateEditorConfigs(
          canRotate: true,
          canFlip: true,
          canChangeAspectRatio: true,
        ),
        filterEditorConfigs: const FilterEditorConfigs(
          showLayers: true,
        ),
        emojiEditorConfigs: const EmojiEditorConfigs(
          enabled: true,
        ),
        stickerEditorConfigs: StickerEditorConfigs(
          enabled: false,
          buildStickers: (setLayer, scrollController) => const SizedBox(),
        ),
      ),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          // Save edited image to temp file
          final tempDir = await getTemporaryDirectory();
          final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
          final editedFile = File('${tempDir.path}/$fileName');
          await editedFile.writeAsBytes(bytes);

          if (context.mounted && onSend != null) {
            onSend!(editedFile);
          }
          // Do NOT pop here — ProImageEditor auto-closes after this callback
          // and triggers onCloseEditor, which handles the navigation pop.
        },
        onCloseEditor: () {
          // ProImageEditor가 자체 pop을 수행한 뒤에도 이 콜백이 호출될 수 있다.
          // 이미 pop된 상태에서 추가 pop을 하면 채팅방까지 pop되므로,
          // 현재 route가 editor route인지 확인 후 pop한다.
          if (context.mounted) {
            // ModalRoute가 아직 현재 route인 경우에만 pop
            final route = ModalRoute.of(context);
            if (route != null && route.isCurrent) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }
}
