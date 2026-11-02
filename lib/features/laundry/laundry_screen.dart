import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../routine/widgets/due_pill.dart';
import 'data/laundry_controller.dart';
import 'data/laundry_order.dart';
import 'widgets/drop_off_dialog.dart';
import 'widgets/photo_actions.dart';

extension LaundryStatusUi on LaundryStatus {
  String get labelKey => switch (this) {
        LaundryStatus.inBasket => 'laundry_st_basket',
        LaundryStatus.droppedOff => 'laundry_st_dropped',
        LaundryStatus.ready => 'laundry_st_ready',
        LaundryStatus.done => 'laundry_st_done',
      };

  String? get actionKey => switch (this) {
        LaundryStatus.inBasket => 'laundry_act_handover',
        LaundryStatus.droppedOff => 'laundry_act_ready',
        LaundryStatus.ready => 'laundry_act_done',
        LaundryStatus.done => null,
      };
}

class LaundryScreen extends StatelessWidget {
  const LaundryScreen({super.key});

  static const _purple = AppColors.lavender;

  void _snack(BuildContext context, String text, {VoidCallback? undo}) {
    final s = context.s;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: undo == null
            ? null
            : SnackBarAction(label: s.t('undo'), onPressed: undo),
      ));
  }

  Future<void> _advance(BuildContext context, LaundryOrder o) async {
    final s = context.s;
    final c = context.read<LaundryController>();
    final before = o;
    LaundryStatus next;

    switch (o.status) {
      case LaundryStatus.inBasket:
        final r = await showDialog<DropOffResult>(
          context: context,
          builder: (_) => DropOffDialog(
              initialShop: o.shop ?? c.lastShop, initialPhoto: o.photo),
        );
        if (r == null) return;
        c.dropOff(
          o.id,
          shop: r.shop,
          weightKg: r.weightKg,
          costRp: r.costRp,
          dueDate: r.dueDate,
          photo: r.photo,
        );
        next = LaundryStatus.droppedOff;
      case LaundryStatus.droppedOff:
        c.setStatus(o.id, LaundryStatus.ready);
        next = LaundryStatus.ready;
      case LaundryStatus.ready:
        c.setStatus(o.id, LaundryStatus.done);
        next = LaundryStatus.done;
      case LaundryStatus.done:
        return;
    }
    if (!context.mounted) return;
    _snack(context, s.t('laundry_moved', {'status': s.t(next.labelKey)}),
        undo: () => c.restore(before));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final c = context.watch<LaundryController>();
    final active = c.active;
    final history = c.history;

    Widget swipeBg() => Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.out.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.t('mod_laundry'))),
      floatingActionButton: FloatingActionButton(
        tooltip: s.t('laundry_new'),
        onPressed: () {
          c.addToBasket();
          _snack(context, s.t('laundry_added'));
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.local_laundry_service_rounded,
                      size: 56, color: _purple),
                  const SizedBox(height: 12),
                  Text(s.t('laundry_empty'), textAlign: TextAlign.center),
                ],
              ),
            ),
          for (final o in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('a-${o.id}'),
                direction: DismissDirection.endToStart,
                background: swipeBg(),
                onDismissed: (_) {
                  c.remove(o.id);
                  _snack(context,
                      s.t('removed', {'name': o.shop ?? s.t('mod_laundry')}),
                      undo: () => c.restore(o));
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.shop ?? s.t('mod_laundry'),
                                      style: theme.textTheme.titleMedium),
                                  Text(
                                    [
                                      fmtDate(o.createdAt, s.lang),
                                      if (o.weightKg != null)
                                        s.t('laundry_kg',
                                            {'kg': fmtKg(o.weightKg!, s.lang)}),
                                      if (o.costRp != null)
                                        'Rp ${fmtMoney(o.costRp!, s.lang)}',
                                    ].join(' · '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.brownSoft),
                                  ),
                                ],
                              ),
                            ),
                            if (o.photo != null) OrderPhoto(name: o.photo!),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          for (var i = 0; i < 4; i++)
                            Expanded(
                              child: Container(
                                height: 6,
                                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: i <= o.status.index
                                      ? AppColors.safe
                                      : AppColors.peach,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.t(o.status.labelKey),
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            if (o.status == LaundryStatus.droppedOff &&
                                o.daysUntilDue() != null)
                              DuePill(days: o.daysUntilDue()!),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _advance(context, o),
                                child: Text(s.t(o.status.actionKey!)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: s.t('laundry_receipt_photo'),
                              icon: const Icon(Icons.photo_camera_outlined),
                              onPressed: () async {
                                final p = await choosePhoto(context);
                                if (p != null) c.setPhoto(o.id, p);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(s.t('laundry_history'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final o in history)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey('h-${o.id}'),
                  direction: DismissDirection.endToStart,
                  background: swipeBg(),
                  onDismissed: (_) {
                    c.remove(o.id);
                    _snack(context,
                        s.t('removed', {'name': o.shop ?? s.t('mod_laundry')}),
                        undo: () => c.restore(o));
                  },
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_rounded,
                          color: AppColors.safe),
                      title: Text(o.shop ?? s.t('mod_laundry'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        fmtDate(o.doneAt ?? o.createdAt, s.lang),
                        if (o.weightKg != null)
                          s.t('laundry_kg', {'kg': fmtKg(o.weightKg!, s.lang)}),
                        if (o.costRp != null)
                          'Rp ${fmtMoney(o.costRp!, s.lang)}',
                      ].join(' · ')),
                      trailing: o.photo == null
                          ? null
                          : OrderPhoto(name: o.photo!, size: 40),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
