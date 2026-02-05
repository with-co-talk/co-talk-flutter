import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

/// Date separator widget displayed between messages on different days.
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppDateUtils.formatFullDate(date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
