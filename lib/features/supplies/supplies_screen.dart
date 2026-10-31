import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/screen_header.dart';
import 'data/supplies_controller.dart';
import 'data/supply_item.dart';
import 'widgets/add_item_dialog.dart';
import 'widgets/supply_ui.dart';

class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  int _tab = 0; // 0 = Stock, 1 = Shopping list
  SupplyCategory? _filter; // null = All

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = context.watch<SuppliesController>();
    final stock = controller.items
        .where((i) => _filter == null || i.category == _filter)
        .toList();

    return Scaffold(
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              tooltip: s.t('add_item'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddItemDialog(initialCategory: _filter),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.t('tab_supplies'),
              subtitle: s.t('supplies_sub'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 0, label: Text(s.t('seg_stock'))),
                    ButtonSegment(
                      value: 1,
                      label: Text(
                          '${s.t('seg_shopping')} (${controller.restockCount})'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (v) => setState(() => _tab = v.first),
                ),
              ),
            ),
            if (_tab == 0) _CategoryFilter(
              selected: _filter,
              onChanged: (c) => setState(() => _filter = c),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 0
                  ? _StockList(items: stock)
                  : _ShoppingList(items: controller.shoppingList),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});
  final SupplyCategory? selected;
  final ValueChanged<SupplyCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          ChoiceChip(
            label: Text(s.t('cat_all')),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final c in SupplyCategory.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(s.t(c.labelKey)),
              selected: selected == c,
              onSelected: (_) => onChanged(c),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Stock tab

class _StockList extends StatelessWidget {
  const _StockList({required this.items});
  final List<SupplyItem> items;

  void _openStatusSheet(BuildContext context, SupplyItem item) {
    final controller = context.read<SuppliesController>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final s = ctx.s;
        final theme = Theme.of(ctx);
        // Watch so the sheet reflects +/- taps straight away.
        final live = ctx
            .watch<SuppliesController>()
            .items
            .firstWhere((e) => e.id == item.id, orElse: () => item);
        final q = live.quantity;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(live.displayName(s.lang), style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(s.t('set_status'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.brownSoft)),
                const SizedBox(height: 8),
                for (final st in SupplyStatus.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 9, backgroundColor: st.color),
                    title: Text(s.t(st.labelKey),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: st == live.status
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      controller.setStatus(live.id, st);
                      Navigator.pop(ctx);
                    },
                  ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(s.t('qty_label'),
                          style: theme.textTheme.titleMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: q == null || q == 0
                          ? null
                          : () => controller.setQuantity(live.id, q - 1),
                    ),
                    SizedBox(
                      width: 96,
                      child: Text(
                        q == null
                            ? s.t('qty_untracked')
                            : s.t('qty_pcs', {'n': '$q'}),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () =>
                          controller.setQuantity(live.id, (q ?? 0) + 1),
                    ),
                  ],
                ),
                if (q != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => controller.setQuantity(live.id, null),
                      child: Text(s.t('qty_stop')),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = context.read<SuppliesController>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item.displayName(s.lang);

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.out.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            controller.remove(item.id);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(s.t('removed', {'name': name})),
                action: SnackBarAction(
                  label: s.t('undo'),
                  onPressed: () => controller.restore(item),
                ),
              ));
          },
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openStatusSheet(context, item),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.peach.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.category.icon,
                          color: AppColors.brown, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            item.quantity == null
                                ? s.t(item.category.labelKey)
                                : '${s.t(item.category.labelKey)} · ${s.t('qty_pcs', {'n': '${item.quantity}'})}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.brownSoft),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(status: item.status),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ Shopping tab

class _ShoppingList extends StatelessWidget {
  const _ShoppingList({required this.items});
  final List<SupplyItem> items;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final controller = context.read<SuppliesController>();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotBadge(size: 88),
              const SizedBox(height: 16),
              Text(s.t('shop_empty_t'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                s.t('shop_empty_b'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.brownSoft),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(s.t('shop_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.brownSoft)),
        const SizedBox(height: 12),
        for (final item in items) ...[
          Card(
            child: CheckboxListTile(
              value: false,
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              activeColor: AppColors.safe,
              checkColor: AppColors.brown,
              title: Text(item.displayName(s.lang),
                  style: theme.textTheme.titleMedium),
              subtitle: Text(
                s.t(item.category.labelKey),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.brownSoft),
              ),
              secondary: StatusPill(status: item.status),
              onChanged: (_) {
                final previous = item.status;
                controller.setStatus(item.id, SupplyStatus.safe);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(s.t(
                        'bought', {'name': item.displayName(s.lang)})),
                    action: SnackBarAction(
                      label: s.t('undo'),
                      onPressed: () => controller.setStatus(item.id, previous),
                    ),
                  ));
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
