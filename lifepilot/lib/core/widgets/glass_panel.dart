import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LifePilotGlassCard extends StatelessWidget {
  const LifePilotGlassCard({
    required this.child,
    this.padding,
    this.radius = LifePilotTheme.glassRadius,
    this.constraints,
    this.onTap,
    this.cardGradient,
    this.borderGradient,
    this.shadowColor,
    this.blurSigma,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;
  final Gradient? cardGradient;
  final Gradient? borderGradient;
  final Color? shadowColor;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final glassExt = theme.extension<GlassThemeExtension>();

    // Fallbacks if theme extension is not registered
    final resolvedCardGradient =
        cardGradient ??
        glassExt?.cardGradient ??
        LinearGradient(
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
        );

    final resolvedBorderGradient =
        borderGradient ??
        glassExt?.borderGradient ??
        LinearGradient(
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
        );

    final resolvedBlurSigma = blurSigma ?? glassExt?.blurSigma ?? 22.0;
    final resolvedShadowColor =
        shadowColor ??
        glassExt?.shadowColor ??
        (dark
            ? Colors.black.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.06));

    Widget content = AnimatedContainer(
      duration: LifePilotTheme.pageDuration,
      curve: LifePilotTheme.quickCurve,
      padding: padding,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: resolvedCardGradient,
        boxShadow: [
          BoxShadow(
            color: resolvedShadowColor,
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: dark
                ? const Color(0xFFF2EBDD).withValues(alpha: 0.06)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.55),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: resolvedBlurSigma,
          sigmaY: resolvedBlurSigma,
        ),
        child: CustomPaint(
          foregroundPainter: GradientBorderPainter(
            gradient: resolvedBorderGradient,
            strokeWidth: 1.0,
            radius: radius,
          ),
          child: content,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class GradientBorderPainter extends CustomPainter {
  GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  final Gradient gradient;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    // Deflate the rect so that the stroke renders exactly inside the card boundaries
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius - strokeWidth / 2),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
