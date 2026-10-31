import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/notifications/reminder_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/screen_header.dart';
import '../bills/data/bills_controller.dart';
import '../gallon/data/gallon_controller.dart';
import '../laundry/data/laundry_controller.dart';
import '../laundry/data/laundry_order.dart';
import '../routine/data/routines_controller.dart';
import '../routine/widgets/due_pill.dart';
import '../supplies/data/supplies_controller.dart';
import '../token/data/token_controller.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final rem = context.watch<ReminderController>();
    final routines = context.watch<RoutinesController>().sorted.take(5).toList();
    final restock = context.watch<SuppliesController>().restockCount;
    final gallonDays = context.watch<GallonController>().daysLeft;
    final pendingLaundry = context.watch<LaundryController>().pending;
    final bills = context.watch<BillsController>().sorted.take(3).toList();
    final tokenDays = context.watch<TokenController>().forecast().daysLeft();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(title: s.t('tab_reminders'), subtitle: s.t('reminders_sub')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(s.t('rem_daily'),
                        style: theme.textTheme.titleMedium),
                    subtitle: Text(s.t('rem_daily_sub')),
                    value: rem.enabled,
                    onChanged: (v) async {
                      final ok = await rem.setEnabled(v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                              SnackBar(content: Text(s.t('rem_denied'))));
                      }
                    },
                  ),
                  ListTile(
                    enabled: rem.enabled,
                    title: Text(s.t('rem_time'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(rem.time.format(context),
                        style: theme.textTheme.titleMedium),
                    onTap: !rem.enabled
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: rem.time);
                            if (picked != null) rem.setTime(picked);
                          },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(s.t('rem_upcoming'), style: theme.textTheme.titleMedium),
          ),
          if (restock > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_basket_rounded,
                      color: AppColors.peachDeep),
                  title: Text(s.t('rem_supplies'),
                      style: theme.textTheme.titleMedium),
                  trailing: Text('$restock', style: theme.textTheme.titleLarge),
                ),
              ),
            ),
          for (final b in bills)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.peachDeep),
                  title: Text(b.name, style: theme.textTheme.titleMedium),
                  trailing: DuePill(days: b.daysUntilDue()),
                ),
              ),
            ),
          for (final o in pendingLaundry)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.local_laundry_service_rounded,
                      color: Color(0xFFA99BD6)),
                  title: Text(o.shop ?? s.t('rem_laundry'),
                      style: theme.textTheme.titleMedium),
                  trailing: (o.status == LaundryStatus.droppedOff &&
                          o.daysUntilDue() != null)
                      ? DuePill(days: o.daysUntilDue()!)
                      : Text(s.t('laundry_st_ready'),
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          if (gallonDays != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF4F93BC)),
                  title: Text(s.t('rem_gallon'),
                      style: theme.textTheme.titleMedium),
                  trailing: DuePill(days: gallonDays),
                ),
              ),
            ),
          if (tokenDays != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.bolt_rounded, color: AppColors.low),
                  title: Text(s.t('rem_token'),
                      style: theme.textTheme.titleMedium),
                  trailing: DuePill(days: tokenDays),
                ),
              ),
            ),
          for (final t in routines)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded,
                      color: AppColors.safe),
                  title: Text(t.displayName(s.lang),
                      style: theme.textTheme.titleMedium),
                  trailing: DuePill(days: t.daysUntilDue()),
                ),
              ),
            ),
          if (routines.isEmpty && restock == 0 && gallonDays == null && tokenDays == null && pendingLaundry.isEmpty && bills.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s.t('rem_none')),
            ),
        ],
      ),
    );
  }
}
