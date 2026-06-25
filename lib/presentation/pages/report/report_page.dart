import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/report.dart';
import '../../../domain/repositories/report_repository.dart';

/// Report submission page for users and messages.
class ReportPage extends StatefulWidget {
  final ReportType type;
  final int targetId;

  const ReportPage({
    super.key,
    required this.type,
    required this.targetId,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = getIt<ReportRepository>();
      final description = _descriptionController.text.trim();

      if (widget.type == ReportType.user) {
        await repository.reportUser(
          reportedUserId: widget.targetId,
          reason: _selectedReason!,
          description: description.isEmpty ? null : description,
        );
      } else {
        await repository.reportMessage(
          reportedMessageId: widget.targetId,
          reason: _selectedReason!,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportSubmitted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportSubmitFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = widget.type == ReportType.user
        ? l10n.reportTargetUser
        : l10n.reportTargetMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTitle(typeLabel)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportSelectReason,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<ReportReason>(
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      title: Text(reason.displayName),
                      value: reason,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.reportDescriptionLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.reportDescriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason != null && !_isSubmitting
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.reportSubmit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
