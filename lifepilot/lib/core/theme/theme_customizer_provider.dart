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

  const ThemeCustomizerState({
    this.glassBlurScale = 20.0,
    this.surfaceOpacity = 0.15,
    this.backdropTintColor = const Color(0xFF0F0E11),
    this.specularGrainIntensity = 0.5,
    this.interfaceDensity = 'Zen',
  });

  ThemeCustomizerState copyWith({
    double? glassBlurScale,
    double? surfaceOpacity,
    Color? backdropTintColor,
    double? specularGrainIntensity,
    String? interfaceDensity,
  }) {
    return ThemeCustomizerState(
      glassBlurScale: glassBlurScale ?? this.glassBlurScale,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      backdropTintColor: backdropTintColor ?? this.backdropTintColor,
      specularGrainIntensity:
          specularGrainIntensity ?? this.specularGrainIntensity,
      interfaceDensity: interfaceDensity ?? this.interfaceDensity,
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
          interfaceDensity == other.interfaceDensity;

  @override
  int get hashCode =>
      glassBlurScale.hashCode ^
      surfaceOpacity.hashCode ^
      backdropTintColor.hashCode ^
      specularGrainIntensity.hashCode ^
      interfaceDensity.hashCode;
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

      state = ThemeCustomizerState(
        glassBlurScale: blur ?? 20.0,
        surfaceOpacity: opacity ?? 0.15,
        backdropTintColor: tintValue != null
            ? Color(tintValue)
            : const Color(0xFF0F0E11),
        specularGrainIntensity: grain ?? 0.5,
        interfaceDensity: density ?? 'Zen',
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
}

final themeCustomizerProvider =
    NotifierProvider<ThemeCustomizerNotifier, ThemeCustomizerState>(
      ThemeCustomizerNotifier.new,
    );
