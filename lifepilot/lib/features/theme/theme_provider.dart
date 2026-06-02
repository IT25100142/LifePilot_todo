import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LifePilotPaletteProfile { champagne, cobalt, emerald, crimson }

class MeshPaletteColors {
  const MeshPaletteColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
}

// Map each enum variant to 3 distinct Color tokens matching our luxury spec.
const Map<LifePilotPaletteProfile, MeshPaletteColors> meshPaletteConfig = {
  LifePilotPaletteProfile.champagne: MeshPaletteColors(
    primary: Color(0xFFD6BD92), // Soft Champagne Gold
    secondary: Color(0xFFC8A97A), // Slate Charcoal / Deep Dark Teal
    tertiary: Color(0xFF9E8B63), // Muted Gold/Indigo
  ),
  LifePilotPaletteProfile.cobalt: MeshPaletteColors(
    primary: Color(0xFF4A90E2), // Deep Cobalt Blue
    secondary: Color(0xFF2C3E50), // Muted Slate/Navy
    tertiary: Color(0xFF8E44AD), // Royal Indigo
  ),
  LifePilotPaletteProfile.emerald: MeshPaletteColors(
    primary: Color(0xFF2ECC71), // Vibrant Emerald Green
    secondary: Color(0xFF16A085), // Dark Teal
    tertiary: Color(0xFF27AE60), // Muted Forest Green
  ),
  LifePilotPaletteProfile.crimson: MeshPaletteColors(
    primary: Color(0xFFE74C3C), // Crimson Red
    secondary: Color(0xFF962D22), // Deep Maroon
    tertiary: Color(0xFFD35400), // Burnt Orange
  ),
};

class ThemePaletteNotifier extends Notifier<LifePilotPaletteProfile> {
  late final SharedPreferences _prefs;

  @override
  LifePilotPaletteProfile build() {
    _init();
    return LifePilotPaletteProfile.champagne;
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedValue = _prefs.getString('lifepilot_theme_palette');
      if (savedValue != null) {
        final profile = LifePilotPaletteProfile.values.firstWhere(
          (e) => e.name == savedValue,
          orElse: () => LifePilotPaletteProfile.champagne,
        );
        state = profile;
      }
    } catch (_) {
      // SharedPreferences fails in test/mock environments gracefully
    }
  }

  Future<void> setPaletteProfile(LifePilotPaletteProfile profile) async {
    state = profile;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('lifepilot_theme_palette', profile.name);
    } catch (_) {}
  }
}

final themePaletteProvider =
    NotifierProvider<ThemePaletteNotifier, LifePilotPaletteProfile>(
      ThemePaletteNotifier.new,
    );
