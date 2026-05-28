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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return LifePilotScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTodoKey,
            routes: [
              GoRoute(
                path: '/todo',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TodoScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHabitsKey,
            routes: [
              GoRoute(
                path: '/habits',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HabitsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFocusKey,
            routes: [
              GoRoute(
                path: '/focus',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FocusScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCalendarKey,
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CalendarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFinanceKey,
            routes: [
              GoRoute(
                path: '/finance',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FinanceScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
