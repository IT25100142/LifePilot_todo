import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCustomizerState {
  final double glassBlurScale;
  final double surfaceOpacity;
  final Color backdropTintColor;
  final double specularGrainIntensity;
  final String interfaceDensity;
  final String activeAtmosphere;
  final double animationSpeed;

  const ThemeCustomizerState({
    this.glassBlurScale = 20.0,
    this.surfaceOpacity = 0.15,
    this.backdropTintColor = const Color(0xFF0F0E11),
    this.specularGrainIntensity = 0.5,
    this.interfaceDensity = 'Zen',
    this.activeAtmosphere = 'ObsidianNight',
    this.animationSpeed = 1.0,
  });

  ThemeCustomizerState copyWith({
    double? glassBlurScale,
    double? surfaceOpacity,
    Color? backdropTintColor,
    double? specularGrainIntensity,
    String? interfaceDensity,
    String? activeAtmosphere,
    double? animationSpeed,
  }) {
    return ThemeCustomizerState(
      glassBlurScale: glassBlurScale ?? this.glassBlurScale,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      backdropTintColor: backdropTintColor ?? this.backdropTintColor,
      specularGrainIntensity:
          specularGrainIntensity ?? this.specularGrainIntensity,
      interfaceDensity: interfaceDensity ?? this.interfaceDensity,
      activeAtmosphere: activeAtmosphere ?? this.activeAtmosphere,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }

  static ThemeCustomizerState lerp(
    ThemeCustomizerState a,
    ThemeCustomizerState b,
    double t,
  ) {
    return ThemeCustomizerState(
      glassBlurScale:
          ui.lerpDouble(a.glassBlurScale, b.glassBlurScale, t) ??
          b.glassBlurScale,
      surfaceOpacity:
          ui.lerpDouble(a.surfaceOpacity, b.surfaceOpacity, t) ??
          b.surfaceOpacity,
      backdropTintColor:
          Color.lerp(a.backdropTintColor, b.backdropTintColor, t) ??
          b.backdropTintColor,
      specularGrainIntensity:
          ui.lerpDouble(
            a.specularGrainIntensity,
            b.specularGrainIntensity,
            t,
          ) ??
          b.specularGrainIntensity,
      interfaceDensity: t < 0.5 ? a.interfaceDensity : b.interfaceDensity,
      activeAtmosphere: t < 0.5 ? a.activeAtmosphere : b.activeAtmosphere,
      animationSpeed:
          ui.lerpDouble(a.animationSpeed, b.animationSpeed, t) ??
          b.animationSpeed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeCustomizerState &&
          runtimeType == other.runtimeType &&
          glassBlurScale == other.glassBlurScale &&
          surfaceOpacity == other.surfaceOpacity &&
          backdropTintColor == other.backdropTintColor &&
          specularGrainIntensity == other.specularGrainIntensity &&
          interfaceDensity == other.interfaceDensity &&
          activeAtmosphere == other.activeAtmosphere &&
          animationSpeed == other.animationSpeed;

  @override
  int get hashCode =>
      glassBlurScale.hashCode ^
      surfaceOpacity.hashCode ^
      backdropTintColor.hashCode ^
      specularGrainIntensity.hashCode ^
      interfaceDensity.hashCode ^
      activeAtmosphere.hashCode ^
      animationSpeed.hashCode;
}

class ThemeCustomizerStateTween extends Tween<ThemeCustomizerState> {
  ThemeCustomizerStateTween({super.begin, super.end});

  @override
  ThemeCustomizerState lerp(double t) {
    return ThemeCustomizerState.lerp(
      begin ?? const ThemeCustomizerState(),
      end ?? const ThemeCustomizerState(),
      t,
    );
  }
}

class ThemeCustomizerNotifier extends Notifier<ThemeCustomizerState> {
  late final SharedPreferences _prefs;

  @override
  ThemeCustomizerState build() {
    _init();
    return const ThemeCustomizerState();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final blur = _prefs.getDouble('lifepilot_theme_glass_blur_scale');
      final opacity = _prefs.getDouble('lifepilot_theme_surface_opacity');
      final tintValue = _prefs.getInt('lifepilot_theme_backdrop_tint_color');
      final grain = _prefs.getDouble(
        'lifepilot_theme_specular_grain_intensity',
      );
      final density = _prefs.getString('lifepilot_theme_interface_density');
      final atmosphere = _prefs.getString('lifepilot_theme_active_atmosphere');
      final speed = _prefs.getDouble('lifepilot_theme_animation_speed');

      state = ThemeCustomizerState(
        glassBlurScale: blur ?? 20.0,
        surfaceOpacity: opacity ?? 0.15,
        backdropTintColor: tintValue != null
            ? Color(tintValue)
            : const Color(0xFF0F0E11),
        specularGrainIntensity: grain ?? 0.5,
        interfaceDensity: density ?? 'Zen',
        activeAtmosphere: atmosphere ?? 'ObsidianNight',
        animationSpeed: speed ?? 1.0,
      );
    } catch (_) {
      // Safe fallback for test/mock environments
    }
  }

  Future<void> setGlassBlurScale(double val) async {
    state = state.copyWith(glassBlurScale: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_theme_glass_blur_scale', val);
    } catch (_) {}
  }

  Future<void> setSurfaceOpacity(double val) async {
    state = state.copyWith(surfaceOpacity: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_theme_surface_opacity', val);
    } catch (_) {}
  }

  Future<void> setBackdropTintColor(Color color) async {
    state = state.copyWith(backdropTintColor: color);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setInt(
        'lifepilot_theme_backdrop_tint_color',
        color.toARGB32(),
      );
    } catch (_) {}
  }

  Future<void> setSpecularGrainIntensity(double val) async {
    state = state.copyWith(specularGrainIntensity: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_theme_specular_grain_intensity', val);
    } catch (_) {}
  }

  Future<void> setInterfaceDensity(String density) async {
    if (density != 'Zen' && density != 'Executive') return;
    state = state.copyWith(interfaceDensity: density);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('lifepilot_theme_interface_density', density);
    } catch (_) {}
  }

  Future<void> setActiveAtmosphere(String atmosphere) async {
    if (atmosphere != 'ObsidianNight' &&
        atmosphere != 'NordicAurora' &&
        atmosphere != 'CyberNeon') {
      return;
    }
    state = state.copyWith(activeAtmosphere: atmosphere);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('lifepilot_theme_active_atmosphere', atmosphere);
    } catch (_) {}
  }

  Future<void> setAnimationSpeed(double val) async {
    if (val < 0.5 || val > 3.0) return;
    state = state.copyWith(animationSpeed: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_theme_animation_speed', val);
    } catch (_) {}
  }
}

final themeCustomizerProvider =
    NotifierProvider<ThemeCustomizerNotifier, ThemeCustomizerState>(
      ThemeCustomizerNotifier.new,
    );

extension AtmosphereColors on String {
  List<Color> get atmosphereColors {
    switch (this) {
      case 'NordicAurora':
        return const [
          Color(0xFF0B2B28), // Deep emerald
          Color(0xFF004D40), // Dark green teal
          Color(0xFF00796B), // Muted cyan teal
          Color(0xFF00E5FF), // Icy cyan
        ];
      case 'CyberNeon':
        return const [
          Color(0xFF2D003E), // Cyber violet/indigo
          Color(0xFFFF007F), // Hot magenta
          Color(0xFF00F0FF), // Electric cyan
          Color(0xFF7000FF), // Vibrant purple
        ];
      case 'ObsidianNight':
      default:
        return const [
          Color(0xFF0F0E11), // Deep obsidian
          Color(0xFF1F1D24), // Very dark plum/indigo
          Color(0xFF111726), // Deep midnight blue
          Color(0xFF1F1235), // Dark violet
        ];
    }
  }
}
