import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LifePilotAccentColor {
  champagneClassic,
  liquidCyberCyan,
  electricViolet,
  auroraMint,
}

extension LifePilotAccentColorExt on LifePilotAccentColor {
  Color get color {
    switch (this) {
      case LifePilotAccentColor.champagneClassic:
        return const Color(0xFFE6C687);
      case LifePilotAccentColor.liquidCyberCyan:
        return const Color(0xFF00E5FF);
      case LifePilotAccentColor.electricViolet:
        return const Color(0xFFD500F9);
      case LifePilotAccentColor.auroraMint:
        return const Color(0xFF00E676);
    }
  }

  String get displayName {
    switch (this) {
      case LifePilotAccentColor.champagneClassic:
        return 'Champagne Classic';
      case LifePilotAccentColor.liquidCyberCyan:
        return 'Liquid Cyber Cyan';
      case LifePilotAccentColor.electricViolet:
        return 'Electric Violet';
      case LifePilotAccentColor.auroraMint:
        return 'Aurora Mint';
    }
  }
}

class GlassPhysicsState {
  final double blurSigma;
  final double specularOpacity;
  final double grainOpacity;
  final LifePilotAccentColor activeAccentColor;

  const GlassPhysicsState({
    this.blurSigma = 20.0,
    this.specularOpacity = 0.15,
    this.grainOpacity = 0.015,
    this.activeAccentColor = LifePilotAccentColor.champagneClassic,
  });

  GlassPhysicsState copyWith({
    double? blurSigma,
    double? specularOpacity,
    double? grainOpacity,
    LifePilotAccentColor? activeAccentColor,
  }) {
    return GlassPhysicsState(
      blurSigma: blurSigma ?? this.blurSigma,
      specularOpacity: specularOpacity ?? this.specularOpacity,
      grainOpacity: grainOpacity ?? this.grainOpacity,
      activeAccentColor: activeAccentColor ?? this.activeAccentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassPhysicsState &&
          runtimeType == other.runtimeType &&
          blurSigma == other.blurSigma &&
          specularOpacity == other.specularOpacity &&
          grainOpacity == other.grainOpacity &&
          activeAccentColor == other.activeAccentColor;

  @override
  int get hashCode =>
      blurSigma.hashCode ^
      specularOpacity.hashCode ^
      grainOpacity.hashCode ^
      activeAccentColor.hashCode;
}

class CanvasStudioNotifier extends Notifier<GlassPhysicsState> {
  late final SharedPreferences _prefs;

  @override
  GlassPhysicsState build() {
    _init();
    return const GlassPhysicsState();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final blurSigma = _prefs.getDouble('lifepilot_glass_blur_sigma');
      final specularOpacity = _prefs.getDouble(
        'lifepilot_glass_specular_opacity',
      );
      final grainOpacity = _prefs.getDouble('lifepilot_glass_grain_opacity');
      final accentColorStr = _prefs.getString('lifepilot_active_accent_color');

      if (blurSigma != null ||
          specularOpacity != null ||
          grainOpacity != null ||
          accentColorStr != null) {
        LifePilotAccentColor activeAccentColor =
            LifePilotAccentColor.champagneClassic;
        if (accentColorStr != null) {
          activeAccentColor = LifePilotAccentColor.values.firstWhere(
            (e) => e.name == accentColorStr,
            orElse: () => LifePilotAccentColor.champagneClassic,
          );
        }

        state = GlassPhysicsState(
          blurSigma: blurSigma ?? 20.0,
          specularOpacity: specularOpacity ?? 0.15,
          grainOpacity: grainOpacity ?? 0.015,
          activeAccentColor: activeAccentColor,
        );
      }
    } catch (_) {
      // SharedPreferences fails in test/mock environments gracefully
    }
  }

  Future<void> setBlurSigma(double val) async {
    state = state.copyWith(blurSigma: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_glass_blur_sigma', val);
    } catch (_) {}
  }

  Future<void> setSpecularOpacity(double val) async {
    state = state.copyWith(specularOpacity: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_glass_specular_opacity', val);
    } catch (_) {}
  }

  Future<void> setGrainOpacity(double val) async {
    state = state.copyWith(grainOpacity: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('lifepilot_glass_grain_opacity', val);
    } catch (_) {}
  }

  Future<void> setActiveAccentColor(LifePilotAccentColor val) async {
    state = state.copyWith(activeAccentColor: val);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('lifepilot_active_accent_color', val.name);
    } catch (_) {}
  }
}

final canvasStudioProvider =
    NotifierProvider<CanvasStudioNotifier, GlassPhysicsState>(
      CanvasStudioNotifier.new,
    );
