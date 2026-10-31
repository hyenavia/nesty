import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../data/routine_task.dart';

/// Next 7 days. A dot marks days with something due; tap a day to see what.
/// Overdue routines are counted on today.
class RoutineWeekStrip extends StatefulWidget {
  const RoutineWeekStrip({super.key, required this.tasks});
  final List<RoutineTask> tasks;

  @override
  State<RoutineWeekStrip> createState() => _RoutineWeekStripState();
}

class _RoutineWeekStripState extends State<RoutineWeekStrip> {
  int _selected = 0;

  String _shortDay(String v) => v.length > 3 ? v.substring(0, 3) : v;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<RoutineTask> _dueOn(int index, DateTime day) => widget.tasks
      .where((t) => index == 0 ? t.daysUntilDue() <= 0 : _sameDay(t.dueDate, day))
      .toList();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(now.year, now.month, now.day + i));
    final selectedTasks = _dueOn(_selected, days[_selected]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == _selected ? AppColors.peach : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.peach.withValues(alpha: 0.8)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _shortDay(DateFormat('E', s.lang).format(days[i])),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.brownSoft),
                          ),
                          const SizedBox(height: 2),
                          Text('${days[i].day}',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dueOn(i, days[i]).isEmpty
                                  ? Colors.transparent
                                  : (i == 0 ? AppColors.out : AppColors.peachDeep),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _selected == 0 ? s.t('today') : fmtDate(days[_selected], s.lang),
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          if (selectedTasks.isEmpty)
            Text(s.t('week_nothing'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.brownSoft))
          else
            for (final t in selectedTasks)
              Text('• ${t.displayName(s.lang)}', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
