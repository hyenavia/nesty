import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import '../bills/bills_screen.dart';
import '../bills/data/bills_controller.dart';
import '../gallon/data/gallon_controller.dart';
import '../gallon/gallon_screen.dart';
import '../laundry/data/laundry_controller.dart';
import '../laundry/laundry_screen.dart';
import '../profile/profile_controller.dart';
import '../routine/data/routines_controller.dart';
import '../routine/widgets/due_pill.dart' show dueText;
import '../supplies/data/supplies_controller.dart';
import '../token/data/token_controller.dart';
import '../token/token_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenSupplies});
  final VoidCallback onOpenSupplies;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final restock = context.watch<SuppliesController>().restockCount;
    final routinesDue = context.watch<RoutinesController>().dueCount;
    final gallonDays = context.watch<GallonController>().daysLeft;
    final tokenDays = context.watch<TokenController>().forecast().daysLeft();
    final bills = context.watch<BillsController>();
    final billsDue = bills.dueSoonCount;
    final nextBill = bills.sorted.isEmpty ? null : bills.sorted.first;
    final laundry = context.watch<LaundryController>();
    final pickup = laundry.pickupCount;
    final profile = context.watch<ProfileController>();
    final auth = context.watch<AuthController>();

    final name = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : (auth.username?.trim().isNotEmpty == true ? auth.username!.trim() : 'Nesty');

    final laundryInfo = laundry.readyCount > 0
        ? s.t('laundry_ready_n', {'n': '${laundry.readyCount}'})
        : laundry.activeCount > 0
            ? s.t('laundry_in_progress_n', {'n': '${laundry.activeCount}'})
            : s.t('laundry_none');

    final suppliesInfo = restock > 0
        ? s.t('restock_n', {'n': '$restock'})
        : s.t('all_stocked');
    final gallonInfo =
        gallonDays == null ? s.t('gallon_setup') : daysLeftText(s, gallonDays);
    final tokenInfo =
        tokenDays == null ? s.t('token_setup') : daysLeftText(s, tokenDays);

    // "Today" card: only items that need attention
    final alerts = <String>[
      if (restock > 0) suppliesInfo,
      if (routinesDue > 0) s.t('routine_due_n', {'n': '$routinesDue'}),
      if (billsDue > 0) s.t('bills_due_n', {'n': '$billsDue'}),
      if (pickup > 0)
        '${s.t('mod_laundry')}: ${s.t('laundry_pickup_n', {'n': '$pickup'})}',
      if (gallonDays != null && gallonDays <= 1)
        '${s.t('mod_gallon')}: $gallonInfo',
      if (tokenDays != null && tokenDays <= 3)
        '${s.t('mod_token')}: $tokenInfo',
    ];

    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              const MascotBadge(size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('hi', {'name': name}),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      s.t('home_sub'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.brownSoft),
                    ),
                  ],
                ),
              ),
              const UserAvatar(size: 44),
            ],
          ),
          const SizedBox(height: 20),
          // "Today" summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.peach.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_sunny_rounded, color: AppColors.peachDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('today'), style: theme.textTheme.titleMedium),
                      if (alerts.isEmpty)
                        Text(s.t('today_clear'), style: theme.textTheme.bodyMedium)
                      else
                        for (final a in alerts)
                          Text(a, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _ModuleCard(
                icon: Icons.bolt_rounded,
                color: AppColors.low,
                title: s.t('mod_token'),
                subtitle: tokenInfo,
                onTap: () => open(const TokenScreen()),
              ),
              _ModuleCard(
                icon: Icons.water_drop_rounded,
                color: AppColors.water,
                title: s.t('mod_gallon'),
                subtitle: gallonInfo,
                onTap: () => open(const GallonScreen()),
              ),
              _ModuleCard(
                icon: Icons.local_laundry_service_rounded,
                color: AppColors.lavender,
                title: s.t('mod_laundry'),
                subtitle: laundryInfo,
                onTap: () => open(const LaundryScreen()),
              ),
              _ModuleCard(
                icon: Icons.shopping_basket_rounded,
                color: AppColors.peachDeep,
                title: s.t('mod_supplies'),
                subtitle: suppliesInfo,
                onTap: onOpenSupplies,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.peachDeep),
              title: Text(s.t('mod_bills'), style: theme.textTheme.titleMedium),
              subtitle: Text(nextBill == null
                  ? s.t('bills_none')
                  : '${nextBill.name} · ${dueText(s, nextBill.daysUntilDue())}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => open(const BillsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.brownSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
