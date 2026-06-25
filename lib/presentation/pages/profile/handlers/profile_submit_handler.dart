import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileSubmitHandler {
  /// Validate nickname field
  static String? validateNickname(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.profileNicknameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.profileNicknameTooShort;
    }
    if (value.trim().length > 20) {
      return l10n.profileNicknameTooLong;
    }
    return null;
  }

  /// Validate status message field (optional field, only length check)
  static String? validateStatusMessage(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Status message is optional
    }
    if (value.trim().length > 60) {
      return AppLocalizations.of(context)!.profileStatusMessageTooLong;
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
