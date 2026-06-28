import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/report.dart';
import '../../../domain/repositories/report_repository.dart';
import '../../widgets/gradient_button.dart';

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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(AppLocalizations.of(context)!.reportSubmitted),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content:
                Text(AppLocalizations.of(context)!.reportSubmitFailed('$e')),
            backgroundColor: AppColors.error,
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
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.reportTitle(typeLabel)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              icon: Icons.flag_outlined,
              text: l10n.reportSelectReason,
            ),
            const SizedBox(height: 14),
            ...ReportReason.values.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReasonCard(
                  label: reason.displayName,
                  selected: _selectedReason == reason,
                  onTap: () => setState(() => _selectedReason = reason),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionLabel(
              icon: Icons.edit_note_outlined,
              text: l10n.reportDescriptionLabel,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.reportDescriptionHint,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: _selectedReason != null && !_isSubmitting
                  ? _submit
                  : null,
              isLoading: _isSubmitting,
              label: l10n.reportSubmit,
              icon: Icons.flag_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

/// 아이콘 칩 + 라벨로 구성된 섹션 헤더.
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

/// 선택 시 보라로 강조되는 사유 카드. 라디오 대신 깔끔한 탭 카드.
class _ReasonCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : context.dividerColor.withValues(alpha: 0.7),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected
                    ? AppColors.primary
                    : context.textSecondaryColor.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
