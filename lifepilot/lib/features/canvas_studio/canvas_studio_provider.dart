import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlassPhysicsState {
  final double blurSigma;
  final double specularOpacity;
  final double grainOpacity;

  const GlassPhysicsState({
    this.blurSigma = 20.0,
    this.specularOpacity = 0.15,
    this.grainOpacity = 0.015,
  });

  GlassPhysicsState copyWith({
    double? blurSigma,
    double? specularOpacity,
    double? grainOpacity,
  }) {
    return GlassPhysicsState(
      blurSigma: blurSigma ?? this.blurSigma,
      specularOpacity: specularOpacity ?? this.specularOpacity,
      grainOpacity: grainOpacity ?? this.grainOpacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassPhysicsState &&
          runtimeType == other.runtimeType &&
          blurSigma == other.blurSigma &&
          specularOpacity == other.specularOpacity &&
          grainOpacity == other.grainOpacity;

  @override
  int get hashCode =>
      blurSigma.hashCode ^ specularOpacity.hashCode ^ grainOpacity.hashCode;
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

      if (blurSigma != null ||
          specularOpacity != null ||
          grainOpacity != null) {
        state = GlassPhysicsState(
          blurSigma: blurSigma ?? 20.0,
          specularOpacity: specularOpacity ?? 0.15,
          grainOpacity: grainOpacity ?? 0.015,
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
}

final canvasStudioProvider =
    NotifierProvider<CanvasStudioNotifier, GlassPhysicsState>(
      CanvasStudioNotifier.new,
    );
