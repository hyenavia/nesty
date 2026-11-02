import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../routine/widgets/due_pill.dart';
import 'data/bills_controller.dart';
import 'widgets/add_bill_dialog.dart';
import 'widgets/monthly_expense_sheet.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  void _snack(BuildContext context, String text, VoidCallback undo) {
    final s = context.s;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: SnackBarAction(label: s.t('undo'), onPressed: undo),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final c = context.watch<BillsController>();
    final bills = c.sorted;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('mod_bills')),
        actions: [
          IconButton(
            tooltip: s.t('expense_overview'),
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => MonthlyExpenseSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: s.t('bill_add'),
        onPressed: () => showDialog<void>(
            context: context, builder: (_) => const AddBillDialog()),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: bills.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 56, color: AppColors.peachDeep),
                    const SizedBox(height: 12),
                    Text(s.t('bills_empty'), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: bills.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Card(
                    elevation: 0,
                    color: AppColors.peach.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.peachDeep.withValues(alpha: 0.2),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => MonthlyExpenseSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                color: AppColors.brown, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.t('expense_overview'),
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    s.t('expense_total'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.brownSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: AppColors.brownSoft),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final b = bills[i - 1];
                return Dismissible(
                  key: ValueKey(b.id),
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
                    c.remove(b.id);
                    _snack(context, s.t('removed', {'name': b.name}),
                        () => c.restore(b));
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.peach.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: AppColors.brown, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name, style: theme.textTheme.titleMedium),
                                Text(
                                  [
                                    s.t('bill_every', {'d': '${b.dayOfMonth}'}),
                                    if (b.amountRp != null)
                                      'Rp ${fmtMoney(b.amountRp!, s.lang)}',
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.brownSoft),
                                ),
                                if (b.splitWays > 1 && b.myShare != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s.t('bill_split_badge', {
                                      'n': '${b.splitWays}',
                                      'share': fmtMoney(b.myShare!, s.lang),
                                    }),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.mint,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                DuePill(days: b.daysUntilDue()),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              final before = c.markPaid(b.id);
                              if (before != null) {
                                _snack(
                                    context,
                                    s.t('bill_paid_msg', {'name': b.name}),
                                    () => c.restore(before));
                              }
                            },
                            child: Text(s.t('bill_mark_paid')),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
