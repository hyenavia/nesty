import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

String dayUnit(AppStrings s, int n) => s.t(n == 1 ? 'unit_day' : 'unit_days');

/// "Overdue by 2 days" / "Due today" / "In 5 days".
class DuePill extends StatelessWidget {
  const DuePill({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final color = days < 0
        ? AppColors.out
        : (days <= 1 ? AppColors.low : AppColors.safe);
    final label = days < 0
        ? s.t('due_overdue', {'n': '${-days}', 'unit': dayUnit(s, -days)})
        : days == 0
            ? s.t('due_today')
            : s.t('due_in', {'n': '$days', 'unit': dayUnit(s, days)});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

/// Plain-text version of [DuePill]'s label.
String dueText(AppStrings s, int days) => days < 0
    ? s.t('due_overdue', {'n': '${-days}', 'unit': dayUnit(s, -days)})
    : days == 0
        ? s.t('due_today')
        : s.t('due_in', {'n': '$days', 'unit': dayUnit(s, days)});
