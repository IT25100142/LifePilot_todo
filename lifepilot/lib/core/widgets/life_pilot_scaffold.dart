import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass.dart';

class LifePilotScaffold extends StatefulWidget {
  const LifePilotScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<LifePilotScaffold> createState() => _LifePilotScaffoldState();
}

class _LifePilotScaffoldState extends State<LifePilotScaffold> {
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant LifePilotScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _previousIndex = oldWidget.navigationShell.currentIndex;
    }
  }

  static const _destinations = [
    _LifePilotDestination(
      'Dashboard',
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    _LifePilotDestination('Todo', Icons.checklist_outlined, Icons.checklist),
    _LifePilotDestination(
      'Habits',
      Icons.repeat_rounded,
      Icons.repeat_on_rounded,
    ),
    _LifePilotDestination('Focus', Icons.timer_outlined, Icons.timer),
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
    // Constrain dock width on wider viewports for centered iPadOS/macOS feel
    final dockMaxWidth = width >= 720 ? 520.0 : double.infinity;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: Stack(
          children: [
            // ── Page Content with AnimatedSwitcher transitions ──
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: SafeArea(
                  child: RepaintBoundary(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        final childKey = child.key as ValueKey<int>?;
                        final isIncoming =
                            childKey?.value ==
                            widget.navigationShell.currentIndex;
                        final isForward =
                            widget.navigationShell.currentIndex >=
                            _previousIndex;

                        final beginOffset = isForward
                            ? (isIncoming
                                  ? const Offset(0.08, 0.0)
                                  : const Offset(-0.08, 0.0))
                            : (isIncoming
                                  ? const Offset(-0.08, 0.0)
                                  : const Offset(0.08, 0.0));

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: beginOffset,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: RepaintBoundary(
                        key: ValueKey<int>(widget.navigationShell.currentIndex),
                        child: widget.navigationShell,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating Glass Dock (universal across all viewports) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: dockMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RepaintBoundary(
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
                                    isSelected:
                                        widget.navigationShell.currentIndex ==
                                        i,
                                    onTap: () => _goBranch(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FloatingDockTab — premium spring-elastic tactile tab with smooth indicators
// ─────────────────────────────────────────────────────────────────────────────

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
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: const _SpringOutCurve(),
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.48);
    final color = widget.isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon with smooth expanding glow indicator ──
              Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding selection glow circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: widget.isSelected ? 48 : 0,
                    height: widget.isSelected ? 48 : 0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? activeColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                    ),
                  ),
                  // Icon itself with smooth cross-fade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.85,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      widget.isSelected ? widget.selectedIcon : widget.icon,
                      key: ValueKey<bool>(widget.isSelected),
                      color: color,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // ── Label with animated color/weight ──
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                style:
                    theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: widget.isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 10,
                    ) ??
                    TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: widget.isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom spring-out curve for elastic snap-back on tap release
// ─────────────────────────────────────────────────────────────────────────────

class _SpringOutCurve extends Curve {
  const _SpringOutCurve();

  @override
  double transformInternal(double t) {
    // Underdamped spring: slight overshoot past 1.0 then settle
    const damping = 5.0;
    const frequency = 3.2;
    final decay = 1.0 - (1.0 * _exp(-damping * t));
    final oscillation = _sin(frequency * t * 3.14159) * (1.0 - t);
    return decay + oscillation * 0.08;
  }

  // Inline math to avoid importing dart:math for two functions
  static double _exp(double x) {
    // Fast approximation sufficient for animation curves
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 12; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static double _sin(double x) {
    // Normalize x to [-π, π] range
    const pi = 3.14159265358979;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;
    // Taylor series approximation
    final x3 = x * x * x;
    final x5 = x3 * x * x;
    final x7 = x5 * x * x;
    return x - x3 / 6 + x5 / 120 - x7 / 5040;
  }
}

class _LifePilotDestination {
  const _LifePilotDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
