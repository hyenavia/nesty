import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/routine/routine_screen.dart';
import '../features/supplies/supplies_screen.dart';

/// Bottom navigation with 5 tabs: Home, Routine, Supplies, Reminders, Profile.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _suppliesTab = 2;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenSupplies: () => setState(() => _index = _suppliesTab)),
          const RoutineScreen(),
          const SuppliesScreen(),
          const RemindersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: s.t('tab_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            selectedIcon: const Icon(Icons.event_available_rounded),
            label: s.t('tab_routine'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: s.t('tab_supplies'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none_rounded),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: s.t('tab_reminders'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: s.t('tab_profile'),
          ),
        ],
      ),
    );
  }
}
