import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass.dart';

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
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: LiquidBackground(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  // Reserve space for the floating dock so content is not obscured
                  padding: const EdgeInsets.only(bottom: 96),
                  child: SafeArea(child: navigationShell),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Hero(
                    tag: 'navigation-dock',
                    child: GlassPanel(
                      radius: 32,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (int i = 0; i < _destinations.length; i++)
                            Expanded(
                              child: FloatingDockTab(
                                icon: _destinations[i].icon,
                                selectedIcon: _destinations[i].selectedIcon,
                                label: _destinations[i].label,
                                isSelected: navigationShell.currentIndex == i,
                                onTap: () => _goBranch(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: SafeArea(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: GlassPanel(
                  radius: 34,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: NavigationRail(
                    extended: isExpanded,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: isExpanded
                          ? const _BrandHeader()
                          : const GlassIcon(icon: Icons.flight_takeoff_rounded),
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
                ),
              ),
              Expanded(child: navigationShell),
            ],
          ),
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

class FloatingDockTab extends StatefulWidget {
  const FloatingDockTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<FloatingDockTab> createState() => _FloatingDockTabState();
}

class _FloatingDockTabState extends State<FloatingDockTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.54);
    final color = widget.isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: widget.isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
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
          GlassIcon(
            icon: Icons.flight_takeoff_rounded,
            color: theme.colorScheme.primary,
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
