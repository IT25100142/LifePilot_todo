import 'dart:ui';
import 'package:flutter/material.dart';

class LifePilotTheme {
  static const _seed = Color(0xFFC3A56A);
  static const glassRadius = 30.0;
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
    final premiumScheme = scheme.copyWith(
      primary: dark ? const Color(0xFFD7C39A) : const Color(0xFF9E8558),
      onPrimary: dark ? const Color(0xFF2A2218) : const Color(0xFFF9F7F3),
      secondary: dark ? const Color(0xFFC2B7A2) : const Color(0xFF8A7D66),
      tertiary: dark ? const Color(0xFFBCA98B) : const Color(0xFFA38C68),
      error: dark ? const Color(0xFFD98681) : const Color(0xFF9E4C4A),
      surface: dark ? const Color(0xFF131214) : const Color(0xFFFBF9F5),
      onSurface: dark ? const Color(0xFFF2EEE6) : const Color(0xFF262320),
      onSurfaceVariant: dark
          ? const Color(0xFFC6C0B3)
          : const Color(0xFF6D665B),
      outlineVariant: dark ? const Color(0x665F5850) : const Color(0x336E665A),
      surfaceContainerHighest: dark
          ? const Color(0xFF242124)
          : const Color(0xFFF1ECE3),
      primaryContainer: dark
          ? const Color(0xFF4C3E2C)
          : const Color(0xFFE6D7BC),
      onPrimaryContainer: dark
          ? const Color(0xFFF2E9DB)
          : const Color(0xFF3F3324),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: premiumScheme,
      scaffoldBackgroundColor: premiumScheme.brightness == Brightness.dark
          ? const Color(0xFF111012)
          : const Color(0xFFF7F4EE),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
          color: premiumScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.1,
          color: premiumScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.0,
          color: premiumScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: premiumScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: premiumScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: premiumScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: premiumScheme.onSurface.withValues(alpha: 0.88),
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: premiumScheme.onSurface.withValues(alpha: 0.95),
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.35,
          color: premiumScheme.onSurface.withValues(alpha: 0.82),
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: premiumScheme.onSurface,
        ),
      ),
      extensions: [
        GlassThemeExtension(
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    const Color(0xFFF8F1E5).withValues(alpha: 0.12),
                    const Color(0xFFCFC8BE).withValues(alpha: 0.07),
                  ]
                : [
                    const Color(0xFFFFFFFF).withValues(alpha: 0.15),
                    const Color(0xFFE5DED2).withValues(alpha: 0.08),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    const Color(0xFFE0CFA7).withValues(alpha: 0.40),
                    const Color(0xFFC8B89A).withValues(alpha: 0.10),
                  ]
                : [
                    const Color(0xFFD4C4A0).withValues(alpha: 0.35),
                    const Color(0xFFB5AAA0).withValues(alpha: 0.12),
                  ],
          ),
          blurSigma: 22.0,
          shadowColor: dark
              ? const Color(0xFF0A090A).withValues(alpha: 0.30)
              : const Color(0xFF58514A).withValues(alpha: 0.12),
        ),
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: premiumScheme.onSurface,
        titleTextStyle: TextStyle(
          color: premiumScheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
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
        fillColor: premiumScheme.surfaceContainerHighest.withValues(
          alpha: 0.44,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: premiumScheme.outlineVariant.withValues(alpha: 0.46),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: premiumScheme.primary.withValues(alpha: 0.74),
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
        backgroundColor: premiumScheme.primaryContainer.withValues(alpha: 0.86),
        foregroundColor: premiumScheme.onPrimaryContainer,
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
        side: BorderSide(
          color: premiumScheme.outlineVariant.withValues(alpha: 0.36),
        ),
        backgroundColor: premiumScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        selectedColor: premiumScheme.primaryContainer.withValues(alpha: 0.72),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: premiumScheme.primaryContainer.withValues(alpha: 0.72),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: premiumScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        groupAlignment: -0.9,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        indicatorColor: premiumScheme.primaryContainer.withValues(alpha: 0.70),
        selectedIconTheme: IconThemeData(
          color: premiumScheme.onPrimaryContainer,
        ),
        selectedLabelTextStyle: TextStyle(
          color: premiumScheme.onSurface,
          fontWeight: FontWeight.w700,
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
  GlassThemeExtension lerp(
    ThemeExtension<GlassThemeExtension>? other,
    double t,
  ) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
      borderGradient: Gradient.lerp(borderGradient, other.borderGradient, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}
