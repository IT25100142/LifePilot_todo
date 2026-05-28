import 'dart:ui';
import 'package:flutter/material.dart';

class LifePilotTheme {
  static const _seed = Color(0xFF4DD7C8);
  static const glassRadius = 28.0;
  static const glassBlur = 24.0;
  static const quickCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const pageDuration = Duration(milliseconds: 420);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _themeFromScheme(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _themeFromScheme(scheme);
  }

  static ThemeData _themeFromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.dark
          ? const Color(0xFF060B0C)
          : const Color(0xFFF4FAFB),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          color: scheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          color: scheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.0,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: scheme.onSurface.withValues(alpha: 0.95),
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: scheme.onSurface,
        ),
      ),
      extensions: [
        GlassThemeExtension(
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.01),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.02),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.06),
                  ],
          ),
          blurSigma: 20.0,
          shadowColor: dark
              ? Colors.black.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glassRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.36),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.82),
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.82),
        foregroundColor: scheme.onPrimaryContainer,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.28)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        selectedColor: scheme.primaryContainer.withValues(alpha: 0.7),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.66),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        groupAlignment: -0.9,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.62),
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  const GlassThemeExtension({
    required this.cardGradient,
    required this.borderGradient,
    required this.blurSigma,
    required this.shadowColor,
  });

  final Gradient cardGradient;
  final Gradient borderGradient;
  final double blurSigma;
  final Color shadowColor;

  @override
  GlassThemeExtension copyWith({
    Gradient? cardGradient,
    Gradient? borderGradient,
    double? blurSigma,
    Color? shadowColor,
  }) {
    return GlassThemeExtension(
      cardGradient: cardGradient ?? this.cardGradient,
      borderGradient: borderGradient ?? this.borderGradient,
      blurSigma: blurSigma ?? this.blurSigma,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  GlassThemeExtension lerp(ThemeExtension<GlassThemeExtension>? other, double t) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
      borderGradient: Gradient.lerp(borderGradient, other.borderGradient, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}
