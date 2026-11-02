import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../routine/widgets/due_pill.dart' show dayUnit;
import '../supplies/widgets/supply_ui.dart';
import 'data/gallon_controller.dart';

class GallonScreen extends StatelessWidget {
  const GallonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final c = context.watch<GallonController>();
    final left = c.daysLeft;
    final day = c.dayNumber;
    final history = c.starts.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.t('mod_gallon'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ---- Current gallon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7FB5D6).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_rounded,
                        size: 30, color: Color(0xFF4F93BC)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        left == null ? s.t('gallon_setup') : daysLeftText(s, left),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (left != null)
                      StatusPill(status: statusForDays(left, lowAt: 1)),
                  ],
                ),
                if (day != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (day / c.avgDays).clamp(0.0, 1.0).toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.surface,
                      color: const Color(0xFF4F93BC),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s.t('gallon_day',
                      {'n': '$day', 'total': '${c.avgDays}'})),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(s.t('gallon_empty_state')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ---- The one-tap button
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              final c = context.read<GallonController>();
              final added = DateTime.now();
              c.newGallon(added);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(s.t('gallon_added')),
                  action: SnackBarAction(
                    label: s.t('undo'),
                    onPressed: () => c.remove(added),
                  ),
                ));
            },
            icon: const Icon(Icons.add_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(s.t('gallon_new'),
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.learnedCount == 0
                ? s.t('gallon_avg_default',
                    {'n': '${c.defaultDays}', 'unit': dayUnit(s, c.defaultDays)})
                : s.t('gallon_avg_learned', {
                    'n': '${c.avgDays}',
                    'unit': dayUnit(s, c.avgDays),
                    'count': '${c.learnedCount + 1}',
                  }),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(s.t('gallon_default_days'),
                  style: theme.textTheme.titleMedium),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: c.defaultDays > 1
                        ? () => c.setDefaultDays(c.defaultDays - 1)
                        : null,
                  ),
                  Text('${c.defaultDays}', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: () => c.setDefaultDays(c.defaultDays + 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.t('history'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (history.isEmpty) Text(s.t('history_empty')),
          for (final start in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey(start.microsecondsSinceEpoch),
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
                  c.remove(start);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(
                          s.t('removed', {'name': fmtDate(start, s.lang)})),
                      action: SnackBarAction(
                        label: s.t('undo'),
                        onPressed: () => c.newGallon(start),
                      ),
                    ));
                },
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.water_drop_outlined,
                        color: Color(0xFF4F93BC)),
                    title: Text(fmtDate(start, s.lang),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(() {
                      final d = c.lastedDays(start);
                      return d == null
                          ? s.t('gallon_current')
                          : s.t('gallon_lasted',
                              {'n': '$d', 'unit': dayUnit(s, d)});
                    }()),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
