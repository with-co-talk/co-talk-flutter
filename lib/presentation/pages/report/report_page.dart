import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
          const SnackBar(
            content: Text('신고가 접수되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수에 실패했습니다: $e'),
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
    final typeLabel = widget.type == ReportType.user ? '사용자' : '메시지';

    return Scaffold(
      appBar: AppBar(
        title: Text('$typeLabel 신고'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 사유를 선택해주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
              title: Text(reason.displayName),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 24),
            const Text(
              '상세 설명 (선택)',
              style: TextStyle(
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
                hintText: '추가 설명을 입력해주세요',
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
                    : const Text(
                        '신고하기',
                        style: TextStyle(
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
