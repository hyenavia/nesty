import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/modules/module_controller.dart';
import '../../core/notifications/reminder_controller.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  static const _count = 4;

  final Set<String> _selectedModules = Set.from(ModuleController.allModules);
  bool _enableReminders = true;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final modules = context.read<ModuleController>();
    final reminders = context.read<ReminderController>();
    final auth = context.read<AuthController>();
    final onboarding = context.read<OnboardingController>();

    await modules.setAll(_selectedModules);
    if (_enableReminders) {
      await reminders.setEnabled(true);
    }
    await auth.continueAsGuest();
    if (mounted) {
      onboarding.complete();
    }
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = context.read<LocaleController>();
    final last = _page == _count - 1;

    final art = <Widget>[
      const _ArtMascot(badge: Icons.checklist_rounded),
      const _ArtTiles(),
      const _ArtMascot(hearts: true),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  for (final code in ['en', 'id'])
                    TextButton(
                      onPressed: () => locale.setLanguage(code),
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(
                           fontWeight:
                              s.lang == code ? FontWeight.w900 : FontWeight.w500,
                          decoration:
                              s.lang == code ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: _finish,
                      child: Text(s.t('skip'),
                          style: const TextStyle(color: AppColors.brownSoft)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  if (i == 3) {
                    return _buildSetupPage(context);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 280, child: Center(child: art[i])),
                        const SizedBox(height: 28),
                        Text(s.t('onb${i + 1}_t'),
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text(
                          s.t('onb${i + 1}_b'),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: AppColors.brownSoft, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.peachDeep : AppColors.peach,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        last ? AppColors.safe : AppColors.peachDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(last ? s.t('setup_finish_btn') : s.t('next'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPage(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);

    final modules = [
      (ModuleController.moduleToken, Icons.bolt_rounded, AppColors.low, s.t('module_token')),
      (ModuleController.moduleGallon, Icons.water_drop_rounded, AppColors.water, s.t('module_gallon')),
      (ModuleController.moduleLaundry, Icons.local_laundry_service_rounded, AppColors.lavender, s.t('module_laundry')),
      (ModuleController.moduleSupplies, Icons.shopping_basket_rounded, AppColors.peachDeep, s.t('module_supplies')),
      (ModuleController.moduleBills, Icons.receipt_long_rounded, AppColors.peachDeep, s.t('module_bills')),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Text(
          s.t('setup_title'),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          s.t('setup_desc'),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.brownSoft),
        ),
        const SizedBox(height: 16),
        for (final m in modules) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              value: _selectedModules.contains(m.$1),
              activeColor: AppColors.peachDeep,
              title: Text(m.$4, style: const TextStyle(fontWeight: FontWeight.w700)),
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: m.$3.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(m.$2, color: AppColors.brown, size: 22),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedModules.add(m.$1);
                  } else {
                    _selectedModules.remove(m.$1);
                  }
                });
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          color: AppColors.peach.withValues(alpha: 0.35),
          child: SwitchListTile(
            value: _enableReminders,
            activeTrackColor: AppColors.peachDeep,
            title: Text(
              s.t('setup_reminders_title'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              s.t('setup_reminders_desc'),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
            ),
            onChanged: (val) => setState(() => _enableReminders = val),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Mascot, optionally with a checklist badge (page 1) or hearts (page 3).
class _ArtMascot extends StatelessWidget {
  const _ArtMascot({this.badge, this.hearts = false});
  final IconData? badge;
  final bool hearts;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Image.asset('assets/images/mascot.png', width: 250),
        if (badge != null)
          Positioned(
            right: 0,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(badge, size: 38, color: AppColors.brown),
            ),
          ),
        if (hearts) ...[
          const Positioned(
              right: 14,
              top: 10,
              child: Icon(Icons.favorite_rounded,
                  size: 26, color: AppColors.peachDeep)),
          Positioned(
              left: 8,
              bottom: 24,
              child: Icon(Icons.favorite_rounded,
                  size: 18, color: AppColors.peachDeep.withValues(alpha: 0.6))),
        ],
      ],
    );
  }
}

/// Page 2: the things Nesty keeps track of.
class _ArtTiles extends StatelessWidget {
  const _ArtTiles();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color color) => Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 54, color: color),
        );

    return SizedBox(
      width: 250,
      height: 250,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          tile(Icons.lightbulb_rounded, AppColors.low),
          tile(Icons.water_drop_rounded, AppColors.waterDeep),
          tile(Icons.local_laundry_service_rounded, AppColors.lavenderDeep),
          tile(Icons.shopping_basket_rounded, AppColors.peachDeep),
        ],
      ),
    );
  }
}
