import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/modules/module_controller.dart';
import '../../core/notifications/reminder_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_screen.dart';
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
import '../supplies/data/supply_item.dart';
import '../token/data/token_controller.dart';
import '../token/token_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenSupplies});
  final VoidCallback onOpenSupplies;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _dismissedGettingStarted = false;
  bool _dismissedBackupBanner = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final modules = context.watch<ModuleController>();
    final hasToken = modules.isEnabled(ModuleController.moduleToken);
    final hasGallon = modules.isEnabled(ModuleController.moduleGallon);
    final hasLaundry = modules.isEnabled(ModuleController.moduleLaundry);
    final hasSupplies = modules.isEnabled(ModuleController.moduleSupplies);
    final hasBills = modules.isEnabled(ModuleController.moduleBills);

    final tokenCtrl = context.watch<TokenController>();
    final gallonCtrl = context.watch<GallonController>();
    final suppliesCtrl = context.watch<SuppliesController>();
    final laundryCtrl = context.watch<LaundryController>();
    final billsCtrl = context.watch<BillsController>();
    final reminderCtrl = context.watch<ReminderController>();

    final restock = suppliesCtrl.restockCount;
    final routinesDue = context.watch<RoutinesController>().dueCount;
    final gallonDays = gallonCtrl.daysLeft;
    final tokenDays = tokenCtrl.forecast().daysLeft();
    final billsDue = billsCtrl.dueSoonCount;
    final nextBill = billsCtrl.sorted.isEmpty ? null : billsCtrl.sorted.first;
    final pickup = laundryCtrl.pickupCount;
    final profile = context.watch<ProfileController>();
    final auth = context.watch<AuthController>();

    final name = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : (auth.username?.trim().isNotEmpty == true ? auth.username!.trim() : 'Nesty');

    final laundryInfo = laundryCtrl.readyCount > 0
        ? s.t('laundry_ready_n', {'n': '${laundryCtrl.readyCount}'})
        : laundryCtrl.activeCount > 0
            ? s.t('laundry_in_progress_n', {'n': '${laundryCtrl.activeCount}'})
            : s.t('laundry_none');

    final suppliesInfo = restock > 0
        ? s.t('restock_n', {'n': '$restock'})
        : s.t('all_stocked');
    final gallonInfo =
        gallonDays == null ? s.t('gallon_setup') : daysLeftText(s, gallonDays);
    final tokenInfo =
        tokenDays == null ? s.t('token_setup') : daysLeftText(s, tokenDays);

    // "Today" card: only items that need attention from enabled modules
    final alerts = <String>[
      if (hasSupplies && restock > 0) suppliesInfo,
      if (routinesDue > 0) s.t('routine_due_n', {'n': '$routinesDue'}),
      if (hasBills && billsDue > 0) s.t('bills_due_n', {'n': '$billsDue'}),
      if (hasLaundry && pickup > 0)
        '${s.t('mod_laundry')}: ${s.t('laundry_pickup_n', {'n': '$pickup'})}',
      if (hasGallon && gallonDays != null && gallonDays <= 1)
        '${s.t('mod_gallon')}: $gallonInfo',
      if (hasToken && tokenDays != null && tokenDays <= 3)
        '${s.t('mod_token')}: $tokenInfo',
    ];

    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    // Dynamic Module Cards
    final cards = <Widget>[
      if (hasToken)
        _ModuleCard(
          icon: Icons.bolt_rounded,
          color: AppColors.low,
          title: s.t('mod_token'),
          subtitle: tokenInfo,
          onTap: () => open(const TokenScreen()),
        ),
      if (hasGallon)
        _ModuleCard(
          icon: Icons.water_drop_rounded,
          color: AppColors.water,
          title: s.t('mod_gallon'),
          subtitle: gallonInfo,
          onTap: () => open(const GallonScreen()),
        ),
      if (hasLaundry)
        _ModuleCard(
          icon: Icons.local_laundry_service_rounded,
          color: AppColors.lavender,
          title: s.t('mod_laundry'),
          subtitle: laundryInfo,
          onTap: () => open(const LaundryScreen()),
        ),
      if (hasSupplies)
        _ModuleCard(
          icon: Icons.shopping_basket_rounded,
          color: AppColors.peachDeep,
          title: s.t('mod_supplies'),
          subtitle: suppliesInfo,
          onTap: widget.onOpenSupplies,
        ),
    ];

    // Getting Started steps
    final steps = <_GettingStartedItem>[
      if (hasToken)
        _GettingStartedItem(
          title: s.t('step_token'),
          icon: Icons.bolt_rounded,
          isDone: tokenCtrl.readings.isNotEmpty,
          onTap: () => open(const TokenScreen()),
        ),
      if (hasGallon)
        _GettingStartedItem(
          title: s.t('step_gallon'),
          icon: Icons.water_drop_rounded,
          isDone: gallonCtrl.starts.isNotEmpty,
          onTap: () => open(const GallonScreen()),
        ),
      if (hasSupplies)
        _GettingStartedItem(
          title: s.t('step_supplies'),
          icon: Icons.shopping_basket_rounded,
          isDone: suppliesCtrl.items.any((e) => e.status != SupplyStatus.safe),
          onTap: widget.onOpenSupplies,
        ),
      if (!reminderCtrl.enabled)
        _GettingStartedItem(
          title: s.t('step_reminder'),
          icon: Icons.notifications_active_rounded,
          isDone: reminderCtrl.enabled,
          onTap: () => reminderCtrl.setEnabled(true),
        ),
    ];
    final doneCount = steps.where((e) => e.isDone).length;
    final showGettingStarted = !_dismissedGettingStarted && steps.isNotEmpty && doneCount < steps.length;

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

          // Getting Started Card (for new users)
          if (showGettingStarted) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.peach.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.peachDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.t('getting_started_title'),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                s.t('getting_started_sub', {
                                  'done': '$doneCount',
                                  'total': '${steps.length}',
                                }),
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.brownSoft),
                          onPressed: () => setState(() => _dismissedGettingStarted = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: steps.isEmpty ? 0 : doneCount / steps.length,
                        backgroundColor: AppColors.peach.withValues(alpha: 0.4),
                        color: AppColors.safe,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final step in steps)
                      InkWell(
                        onTap: step.onTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                step.isDone
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: step.isDone ? AppColors.safe : AppColors.brownSoft,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: step.isDone ? TextDecoration.lineThrough : null,
                                    color: step.isDone ? AppColors.brownSoft : theme.colorScheme.onSurface,
                                    fontWeight: step.isDone ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.brownSoft),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Guest Backup Reminder Banner
          if (auth.isGuest && !_dismissedBackupBanner) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.low.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_queue_rounded, color: AppColors.peachDeep, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.t('guest_backup_title'),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.t('guest_backup_desc'),
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonal(
                            onPressed: () => open(const AuthScreen()),
                            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                            child: Text(s.t('guest_backup_btn')),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.brownSoft),
                      onPressed: () => setState(() => _dismissedBackupBanner = true),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          if (cards.isNotEmpty)
            GridView.count(
              crossAxisCount: cards.length == 1 ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cards.length == 1 ? 2.6 : 1.25,
              children: cards,
            ),
          if (hasBills) ...[
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
        ],
      ),
    );
  }
}

class _GettingStartedItem {
  const _GettingStartedItem({
    required this.title,
    required this.icon,
    required this.isDone,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isDone;
  final VoidCallback onTap;
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
