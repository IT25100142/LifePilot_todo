import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LifePilotScaffold extends StatelessWidget {
  const LifePilotScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _LifePilotDestination(
      'Dashboard',
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    _LifePilotDestination('Todo', Icons.checklist_outlined, Icons.checklist),
    _LifePilotDestination(
      'Calendar',
      Icons.calendar_month_outlined,
      Icons.calendar_month,
    ),
    _LifePilotDestination(
      'Finance',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
    ),
    _LifePilotDestination('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 720;
    final isExpanded = width >= 1100;

    if (isCompact) {
      return Scaffold(
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final item in _destinations)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: isExpanded,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: isExpanded
                    ? const _BrandHeader()
                    : const Icon(Icons.flight_takeoff_rounded, size: 30),
              ),
              destinations: [
                for (final item in _destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.flight_takeoff_rounded),
          ),
          const SizedBox(width: 12),
          Text(
            'LifePilot',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifePilotDestination {
  const _LifePilotDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
