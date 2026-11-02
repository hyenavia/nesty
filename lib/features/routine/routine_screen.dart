import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/screen_header.dart';
import 'data/routines_controller.dart';
import 'widgets/add_routine_dialog.dart';
import 'widgets/due_pill.dart';
import 'widgets/routine_week_strip.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final controller = context.watch<RoutinesController>();
    final tasks = controller.sorted;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: s.t('add_routine'),
        onPressed: () => showDialog<void>(
            context: context, builder: (_) => const AddRoutineDialog()),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.t('tab_routine'), subtitle: s.t('routine_sub')),
            RoutineWeekStrip(tasks: tasks),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  final name = task.displayName(s.lang);
                  return Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.out.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    onDismissed: (_) {
                      controller.remove(task.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(s.t('removed', {'name': name})),
                          action: SnackBarAction(
                            label: s.t('undo'),
                            onPressed: () => controller.restore(task),
                          ),
                        ));
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.mint.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.cleaning_services_rounded,
                                  color: AppColors.brown, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: theme.textTheme.titleMedium),
                                  Text(
                                    [
                                      s.t('routine_every', {
                                        'n': '${task.intervalDays}',
                                        'unit': dayUnit(s, task.intervalDays),
                                      }),
                                      if (task.completedCount > 0)
                                        s.t('routine_done_count',
                                            {'n': '${task.completedCount}'}),
                                    ].join(' · '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.brownSoft),
                                  ),
                                  const SizedBox(height: 6),
                                  DuePill(days: task.daysUntilDue()),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: s.t('mark_done'),
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              iconSize: 30,
                              color: AppColors.safe,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                final previous = controller.markDone(task.id);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content:
                                        Text(s.t('done_msg', {'name': name})),
                                    action: SnackBarAction(
                                      label: s.t('undo'),
                                      onPressed: () =>
                                          controller.setLastDone(task.id, previous),
                                    ),
                                  ));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
