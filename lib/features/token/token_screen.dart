import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/numbers_dialog.dart';
import '../supplies/widgets/supply_ui.dart';
import 'data/token_controller.dart';
import 'data/token_models.dart';

class TokenScreen extends StatelessWidget {
  const TokenScreen({super.key});

  Future<void> _addReading(BuildContext context) async {
    final s = context.s;
    final c = context.read<TokenController>();
    final v = await showNumbersDialog(
      context,
      title: s.t('add_reading'),
      fields: [FieldSpec(label: s.t('meter_kwh'), allowZero: true)],
    );
    if (v != null && v[0] != null) c.addReading(v[0]!);
  }

  Future<void> _logTopUp(BuildContext context) async {
    final s = context.s;
    final c = context.read<TokenController>();
    final v = await showNumbersDialog(
      context,
      title: s.t('log_topup'),
      fields: [
        FieldSpec(label: s.t('amount_rp'), integer: true),
        FieldSpec(
            label: s.t('kwh_received'), helper: s.t('kwh_helper'), required: false),
      ],
    );
    if (v != null && v[0] != null) c.addPurchase(v[0]!.toInt(), v[1]);
  }

  Future<void> _editTariff(BuildContext context) async {
    final s = context.s;
    final c = context.read<TokenController>();
    final v = await showNumbersDialog(
      context,
      title: s.t('tariff_title'),
      hint: s.t('tariff_sub'),
      fields: [
        FieldSpec(
          label: s.t('tariff_title'),
          required: false,
          initial: c.tariff?.toStringAsFixed(c.tariff! % 1 == 0 ? 0 : 2),
        ),
      ],
    );
    if (v != null) c.setTariff(v[0]);
  }

  void _undoBar(BuildContext context, String text, VoidCallback undo) {
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
    final c = context.watch<TokenController>();
    final f = c.forecast();
    final days = f.daysLeft();

    // Merge readings and top-ups into one newest-first history.
    final entries = <_Entry>[
      for (final r in c.readings)
        _Entry(
          at: r.at,
          icon: Icons.speed_rounded,
          title: s.t('reading_row', {'kwh': fmtKwh(r.kwh, s.lang)}),
          onRemove: () {
            c.removeReading(r);
            _undoBar(context, s.t('removed', {'name': s.t('add_reading')}),
                () => c.restoreReading(r));
          },
        ),
      for (final p in c.purchases)
        _Entry(
          at: p.at,
          icon: Icons.bolt_rounded,
          title: s.t('topup_row', {'amount': fmtMoney(p.amountRp, s.lang)}),
          subtitle: p.kwh == null
              ? null
              : s.t(p.kwhEstimated ? 'kwh_row_est' : 'kwh_row',
                  {'kwh': fmtKwh(p.kwh!, s.lang)}),
          onRemove: () {
            c.removePurchase(p);
            _undoBar(context, s.t('removed', {'name': s.t('log_topup')}),
                () => c.restorePurchase(p));
          },
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      appBar: AppBar(title: Text(s.t('mod_token'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ---- Forecast
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.peach.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 30, color: AppColors.peachDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        days == null ? s.t('token_setup') : daysLeftText(s, days),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (days != null)
                      StatusPill(status: statusForDays(days, lowAt: 3)),
                  ],
                ),
                const SizedBox(height: 10),
                if (f.runOutDate != null)
                  Text(s.t('token_runout',
                      {'date': fmtDate(f.runOutDate!, s.lang)})),
                if (f.remainingKwh != null)
                  Text(s.t('token_remaining',
                      {'kwh': fmtKwh(f.remainingKwh!, s.lang)})),
                if (f.ratePerDay != null)
                  Text(s.t('token_rate',
                      {'kwh': fmtKwh(f.ratePerDay!, s.lang)})),
                if (f.hint != TokenHint.none) ...[
                  const SizedBox(height: 6),
                  Text(s.t('hint_${f.hint.name}'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addReading(context),
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(s.t('add_reading')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _logTopUp(context),
                  icon: const Icon(Icons.bolt_rounded),
                  label: Text(s.t('log_topup')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.t('token_flow_hint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.brownSoft)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(s.t('tariff_title'),
                  style: theme.textTheme.titleMedium),
              subtitle: Text(c.tariff == null
                  ? s.t('tariff_none')
                  : 'Rp ${fmtMoney(c.tariff!, s.lang)} / kWh'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editTariff(context),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.t('history'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (entries.isEmpty) Text(s.t('history_empty')),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey('${e.icon.codePoint}-${e.at.microsecondsSinceEpoch}'),
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
                onDismissed: (_) => e.onRemove(),
                child: Card(
                  child: ListTile(
                    leading: Icon(e.icon, color: AppColors.peachDeep),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      fmtDate(e.at, s.lang),
                      if (e.subtitle != null) e.subtitle!,
                    ].join(' · ')),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.at,
    required this.icon,
    required this.title,
    required this.onRemove,
    this.subtitle,
  });
  final DateTime at;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onRemove;
}
