import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../laundry/data/laundry_controller.dart';
import '../../token/data/token_controller.dart';
import '../data/bills_controller.dart';
import '../data/monthly_expense.dart';

class MonthlyExpenseSheet extends StatefulWidget {
  const MonthlyExpenseSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const MonthlyExpenseSheet(),
      );

  @override
  State<MonthlyExpenseSheet> createState() => _MonthlyExpenseSheetState();
}

class _MonthlyExpenseSheetState extends State<MonthlyExpenseSheet> {
  ExpensePeriodMode _mode = ExpensePeriodMode.monthly;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month);
  }

  void _prev() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_mode == ExpensePeriodMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      } else {
        _currentDate = _currentDate.subtract(const Duration(days: 7));
      }
    });
  }

  void _next() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_mode == ExpensePeriodMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
      } else {
        _currentDate = _currentDate.add(const Duration(days: 7));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);

    final bills = context.watch<BillsController>().items;
    final tokens = context.watch<TokenController>().purchases;
    final laundry = context.watch<LaundryController>().orders;

    final ExpenseSummary summary = _mode == ExpensePeriodMode.monthly
        ? MonthlyExpenseCalculator.calculate(
            year: _currentDate.year,
            month: _currentDate.month,
            bills: bills,
            tokenPurchases: tokens,
            laundryOrders: laundry,
          )
        : MonthlyExpenseCalculator.calculateWeekly(
            weekStart: _currentDate,
            bills: bills,
            tokenPurchases: tokens,
            laundryOrders: laundry,
          );

    final periodLabel = _mode == ExpensePeriodMode.monthly
        ? DateFormat('MMMM yyyy', s.lang).format(_currentDate)
        : '${fmtDate(_currentDate, s.lang)} - ${fmtDate(_currentDate.add(const Duration(days: 6)), s.lang)}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Period Mode Segmented Selector (Monthly vs Weekly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SegmentedButton<ExpensePeriodMode>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: AppColors.peach.withValues(alpha: 0.7),
                selectedForegroundColor: AppColors.brown,
              ),
              segments: [
                ButtonSegment(
                  value: ExpensePeriodMode.monthly,
                  label: Text(s.t('period_monthly')),
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ExpensePeriodMode.weekly,
                  label: Text(s.t('period_weekly')),
                  icon: const Icon(Icons.date_range_outlined, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) {
                HapticFeedback.lightImpact();
                setState(() {
                  _mode = set.first;
                  final now = DateTime.now();
                  _currentDate = _mode == ExpensePeriodMode.monthly
                      ? DateTime(now.year, now.month)
                      : MonthlyExpenseCalculator.startOfWeek(now);
                });
              },
            ),
          ),

          const SizedBox(height: 4),

          // Navigation switcher (Prev / Next)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prev,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        s.t('expense_overview'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.brownSoft,
                        ),
                      ),
                      Text(
                        periodLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _next,
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Content body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Grand Total Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.peach.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.peachDeep.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.t('expense_total'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.brownSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${fmtMoney(summary.grandTotalRp, s.lang)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brown,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category breakdown row
                      Row(
                        children: [
                          _CategoryBadge(
                            icon: Icons.receipt_long_rounded,
                            label: s.t('expense_bills'),
                            amountRp: summary.totalBillsRp,
                            lang: s.lang,
                          ),
                          const SizedBox(width: 8),
                          _CategoryBadge(
                            icon: Icons.bolt_rounded,
                            label: s.t('expense_tokens'),
                            amountRp: summary.totalTokensRp,
                            lang: s.lang,
                          ),
                          const SizedBox(width: 8),
                          _CategoryBadge(
                            icon: Icons.local_laundry_service_rounded,
                            label: s.t('expense_laundry'),
                            amountRp: summary.totalLaundryRp,
                            lang: s.lang,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Breakdown section title & actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.t('expense_breakdown'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(s.t('expense_copy_summary')),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: summary.toSummaryText()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(s.t('expense_copied'))),
                              );
                            }
                          },
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.table_view_rounded, size: 16),
                          label: Text(s.t('expense_export_csv')),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: summary.toCsv()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'CSV ${s.t('expense_copied')}')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (summary.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        s.t('expense_no_data'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.brownSoft,
                        ),
                      ),
                    ),
                  )
                else
                  for (final item in summary.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              _itemIcon(item.category),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      [
                                        fmtDate(item.date, s.lang),
                                        if (item.subtitle != null)
                                          item.subtitle!,
                                      ].join(' · '),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppColors.brownSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${fmtMoney(item.amountRp, s.lang)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemIcon(String category) {
    final IconData icon;
    final Color color;

    switch (category.toLowerCase()) {
      case 'bills':
        icon = Icons.receipt_long_rounded;
        color = AppColors.peachDeep;
      case 'token':
        icon = Icons.bolt_rounded;
        color = AppColors.low;
      case 'laundry':
        icon = Icons.local_laundry_service_rounded;
        color = AppColors.mint;
      default:
        icon = Icons.payments_outlined;
        color = AppColors.brownSoft;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.icon,
    required this.label,
    required this.amountRp,
    required this.lang,
  });

  final IconData icon;
  final String label;
  final int amountRp;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.brownSoft),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.brownSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${fmtMoney(amountRp, lang)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.brown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
