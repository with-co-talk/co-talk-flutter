import 'package:flutter/material.dart';

class ProfileSubmitHandler {
  /// Validate nickname field
  static String? validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '닉네임을 입력해주세요';
    }
    if (value.trim().length < 2) {
      return '닉네임은 2자 이상이어야 합니다';
    }
    if (value.trim().length > 20) {
      return '닉네임은 20자 이하여야 합니다';
    }
    return null;
  }

  /// Validate status message field (optional field, only length check)
  static String? validateStatusMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Status message is optional
    }
    if (value.trim().length > 60) {
      return '상태메시지는 60자 이하여야 합니다';
    }
    return null;
  }

  /// Check if there are changes compared to original values
  static bool hasChanges({
    required String currentNickname,
    required String currentStatusMessage,
    required String originalNickname,
    required String originalStatusMessage,
  }) {
    return currentNickname.trim() != originalNickname ||
        currentStatusMessage.trim() != originalStatusMessage;
  }

  /// Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show generic snackbar
  static void showSnackbar(
    BuildContext context,
    String message, {
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: behavior,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
