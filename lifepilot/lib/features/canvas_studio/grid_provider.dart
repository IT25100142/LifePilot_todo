import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DashboardLayoutDensity { zen, executive }

class DashboardGridLayoutState {
  final Map<String, bool> visibleCards;
  final DashboardLayoutDensity layoutDensity;

  const DashboardGridLayoutState({
    this.visibleCards = const {
      'runway': true,
      'tasks': true,
      'habits': true,
      'focus': true,
    },
    this.layoutDensity = DashboardLayoutDensity.zen,
  });

  DashboardGridLayoutState copyWith({
    Map<String, bool>? visibleCards,
    DashboardLayoutDensity? layoutDensity,
  }) {
    return DashboardGridLayoutState(
      visibleCards: visibleCards ?? this.visibleCards,
      layoutDensity: layoutDensity ?? this.layoutDensity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardGridLayoutState &&
          runtimeType == other.runtimeType &&
          layoutDensity == other.layoutDensity &&
          _mapEquals(visibleCards, other.visibleCards);

  @override
  int get hashCode => visibleCards.hashCode ^ layoutDensity.hashCode;

  bool _mapEquals(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class GridNotifier extends Notifier<DashboardGridLayoutState> {
  late final SharedPreferences _prefs;

  @override
  DashboardGridLayoutState build() {
    _init();
    return const DashboardGridLayoutState();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      final runway = _prefs.getBool('lifepilot_card_visible_runway');
      final tasks = _prefs.getBool('lifepilot_card_visible_tasks');
      final habits = _prefs.getBool('lifepilot_card_visible_habits');
      final focus = _prefs.getBool('lifepilot_card_visible_focus');
      final densityStr = _prefs.getString('lifepilot_layout_density');

      final visibleCards = Map<String, bool>.from(state.visibleCards);
      if (runway != null) visibleCards['runway'] = runway;
      if (tasks != null) visibleCards['tasks'] = tasks;
      if (habits != null) visibleCards['habits'] = habits;
      if (focus != null) visibleCards['focus'] = focus;

      DashboardLayoutDensity density = state.layoutDensity;
      if (densityStr != null) {
        density = DashboardLayoutDensity.values.firstWhere(
          (e) => e.name == densityStr,
          orElse: () => DashboardLayoutDensity.zen,
        );
      }

      if (runway != null ||
          tasks != null ||
          habits != null ||
          focus != null ||
          densityStr != null) {
        state = DashboardGridLayoutState(
          visibleCards: visibleCards,
          layoutDensity: density,
        );
      }
    } catch (_) {
      // SharedPreferences fails in test/mock environments gracefully
    }
  }

  Future<void> setCardVisible(String cardKey, bool visible) async {
    final updatedMap = Map<String, bool>.from(state.visibleCards);
    updatedMap[cardKey] = visible;
    state = state.copyWith(visibleCards: updatedMap);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setBool('lifepilot_card_visible_$cardKey', visible);
    } catch (_) {}
  }

  Future<void> setLayoutDensity(DashboardLayoutDensity density) async {
    state = state.copyWith(layoutDensity: density);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('lifepilot_layout_density', density.name);
    } catch (_) {}
  }
}

final gridProvider = NotifierProvider<GridNotifier, DashboardGridLayoutState>(
  GridNotifier.new,
);
