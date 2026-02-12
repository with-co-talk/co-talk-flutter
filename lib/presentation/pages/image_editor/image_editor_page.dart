import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../../../core/theme/app_colors.dart';

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
    return ProImageEditor.file(
      imageFile,
      configs: ProImageEditorConfigs(
        i18n: const I18n(
          various: I18nVarious(
            loadingDialogMsg: '처리 중...',
            closeEditorWarningTitle: '편집 취소',
            closeEditorWarningMessage: '편집 내용을 취소하시겠습니까?',
            closeEditorWarningConfirmBtn: '취소',
            closeEditorWarningCancelBtn: '계속 편집',
          ),
          paintEditor: I18nPaintingEditor(
            bottomNavigationBarText: '그리기',
            freestyle: '자유',
            arrow: '화살표',
            line: '직선',
            rectangle: '사각형',
            circle: '원',
            dashLine: '점선',
            lineWidth: '두께',
            toggleFill: '채우기',
            undo: '실행 취소',
            redo: '다시 실행',
            done: '완료',
            back: '뒤로',
          ),
          textEditor: I18nTextEditor(
            inputHintText: '텍스트 입력',
            bottomNavigationBarText: '텍스트',
            back: '뒤로',
            done: '완료',
          ),
          cropRotateEditor: I18nCropRotateEditor(
            bottomNavigationBarText: '자르기',
            rotate: '회전',
            flip: '뒤집기',
            ratio: '비율',
            back: '뒤로',
            done: '완료',
            cancel: '취소',
            reset: '초기화',
          ),
          filterEditor: I18nFilterEditor(
            bottomNavigationBarText: '필터',
            back: '뒤로',
            done: '완료',
          ),
          emojiEditor: I18nEmojiEditor(
            bottomNavigationBarText: '이모지',
          ),
          cancel: '취소',
          undo: '실행 취소',
          redo: '다시 실행',
          done: '완료',
          remove: '삭제',
          doneLoadingMsg: '저장 중...',
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
