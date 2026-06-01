import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/life_pilot_scaffold.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/finance/finance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/todo/todo_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';

final pendingQuickActionProvider = StateProvider<QuickAction?>((ref) => null);

enum QuickAction { task, event, transaction }

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>();
final _shellNavigatorTodoKey = GlobalKey<NavigatorState>();
final _shellNavigatorHabitsKey = GlobalKey<NavigatorState>();
final _shellNavigatorFocusKey = GlobalKey<NavigatorState>();
final _shellNavigatorCalendarKey = GlobalKey<NavigatorState>();
final _shellNavigatorFinanceKey = GlobalKey<NavigatorState>();
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen(authSessionProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: RouterRefreshListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isSessionUnlocked = ref.read(authSessionProvider);
      final goingToLogin = state.matchedLocation == '/login';

      final isLocked = !isSessionUnlocked && !authState.isFirstTimeLaunch;

      if ((isLocked || authState.isFirstTimeLaunch) && !goingToLogin) {
        return '/login';
      }
      if (!isLocked && !authState.isFirstTimeLaunch && goingToLogin) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            OrganicPhysicsTransitionPage(child: const LoginScreen()),
      ),
      StatefulShellRoute(
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => OrganicPhysicsTransitionPage(
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTodoKey,
            routes: [
              GoRoute(
                path: '/todo',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const TodoScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHabitsKey,
            routes: [
              GoRoute(
                path: '/habits',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const HabitsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFocusKey,
            routes: [
              GoRoute(
                path: '/focus',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const FocusScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCalendarKey,
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const CalendarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFinanceKey,
            routes: [
              GoRoute(
                path: '/finance',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const FinanceScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    OrganicPhysicsTransitionPage(child: const SettingsScreen()),
              ),
            ],
          ),
        ],
        navigatorContainerBuilder: (context, navigationShell, children) {
          return KineticsBranchContainer(
            navigationShell: navigationShell,
            children: children,
          );
        },
        builder: (context, state, navigationShell) {
          return LifePilotScaffold(navigationShell: navigationShell);
        },
      ),
    ],
  );
});

class OrganicPhysicsTransitionPage<T> extends CustomTransitionPage<T> {
  OrganicPhysicsTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curveAnimation = CurvedAnimation(
             parent: animation,
             curve: const Cubic(0.2, 0.9, 0.1, 1.05), // Organic spring curve
             reverseCurve: Curves.easeIn,
           );

           final slideAnimation = Tween<Offset>(
             begin: const Offset(0.0, 0.08),
             end: Offset.zero,
           ).animate(curveAnimation);

           final scaleAnimation = Tween<double>(
             begin: 0.96,
             end: 1.0,
           ).animate(curveAnimation);

           return FadeTransition(
             opacity: animation,
             child: SlideTransition(
               position: slideAnimation,
               child: ScaleTransition(scale: scaleAnimation, child: child),
             ),
           );
         },
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 250),
       );
}

class KineticsBranchContainer extends StatefulWidget {
  const KineticsBranchContainer({
    required this.navigationShell,
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<KineticsBranchContainer> createState() =>
      _KineticsBranchContainerState();
}

class _KineticsBranchContainerState extends State<KineticsBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
    _previousIndex = _currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(covariant KineticsBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        const curve = Cubic(0.2, 0.9, 0.1, 1.05);
        final curvedVal = curve.transform(t);

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isCurrent = index == _currentIndex;
            final isPrevious = index == _previousIndex;

            if (!isCurrent && !isPrevious) {
              return Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }

            double opacity;
            double scale;
            double translationX;

            if (isCurrent) {
              opacity = curvedVal;
              scale = 0.95 + 0.05 * curvedVal;
              final direction = _currentIndex > _previousIndex ? 1.0 : -1.0;
              translationX = 30.0 * (1.0 - curvedVal) * direction;
            } else {
              opacity = 1.0 - curvedVal;
              scale = 1.0 - 0.03 * curvedVal;
              final direction = _currentIndex > _previousIndex ? -1.0 : 1.0;
              translationX = 20.0 * curvedVal * direction;
            }

            return Offstage(
              offstage: false,
              child: TickerMode(
                enabled: true,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(translationX, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: widget.children[index],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
