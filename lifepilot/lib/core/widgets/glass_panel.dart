import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class GlassNoiseCache {
  static ui.Image? _noiseImage;

  static ui.Image get noiseImage {
    _noiseImage ??= _generateNoiseImageSync();
    return _noiseImage!;
  }

  static ui.Image _generateNoiseImageSync() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 128;
    const height = 128;
    final rand = math.Random(42);

    final List<Offset> darkPoints = [];
    final List<Offset> lightPoints = [];

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final r = rand.nextDouble();
        if (r < 0.15) {
          darkPoints.add(Offset(x.toDouble(), y.toDouble()));
        } else if (r < 0.30) {
          lightPoints.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    final darkPaint = Paint()
      ..color =
          const Color(0x14000000) // Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawPoints(ui.PointMode.points, darkPoints, darkPaint);

    final lightPaint = Paint()
      ..color =
          const Color(0x14FFFFFF) // Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawPoints(ui.PointMode.points, lightPoints, lightPaint);

    final picture = recorder.endRecording();
    return picture.toImageSync(width, height);
  }
}

class LifePilotGlassCard extends StatefulWidget {
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
  State<LifePilotGlassCard> createState() => _LifePilotGlassCardState();
}

class _LifePilotGlassCardState extends State<LifePilotGlassCard> {
  bool _isHovered = false;
  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final glassExt = theme.extension<GlassThemeExtension>();

    // Fallbacks if theme extension is not registered
    final resolvedCardGradient =
        widget.cardGradient ??
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
        widget.borderGradient ?? glassExt?.borderGradient;

    final resolvedBlurSigma = widget.blurSigma ?? glassExt?.blurSigma ?? 22.0;
    final resolvedShadowColor =
        widget.shadowColor ??
        glassExt?.shadowColor ??
        (dark
            ? Colors.black.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.06));

    Widget container = AnimatedContainer(
      duration: LifePilotTheme.pageDuration,
      curve: LifePilotTheme.quickCurve,
      padding: widget.padding,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
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
      child: widget.child,
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: resolvedBlurSigma,
          sigmaY: resolvedBlurSigma,
        ),
        child: CustomPaint(
          painter: GlassBackgroundEffectsPainter(
            isHovered: _isHovered,
            mousePosition: _mousePosition,
            spotlightColor: const Color(
              0xFFD6BD92,
            ), // Champagne Gold theme tone
            noiseImage: GlassNoiseCache.noiseImage,
          ),
          foregroundPainter: SpecularBorderPainter(
            radius: widget.radius,
            strokeWidth: 0.75, // Crisp 0.75px specular border highlight
            customBorderGradient: resolvedBorderGradient,
          ),
          child: container,
        ),
      ),
    );

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (event) => setState(() {
        _isHovered = true;
        _mousePosition = event.localPosition;
      }),
      onHover: (event) => setState(() {
        _mousePosition = event.localPosition;
      }),
      onExit: (event) => setState(() {
        _isHovered = false;
      }),
      child: content,
    );
  }
}

class GlassBackgroundEffectsPainter extends CustomPainter {
  GlassBackgroundEffectsPainter({
    required this.isHovered,
    required this.mousePosition,
    required this.spotlightColor,
    required this.noiseImage,
  });

  final bool isHovered;
  final Offset mousePosition;
  final Color spotlightColor;
  final ui.Image noiseImage;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Draw Spotlight (Dynamic Pointer Illuminator)
    if (isHovered) {
      final spotlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          mousePosition,
          120.0, // wide radius: 120 logical units
          [
            spotlightColor.withValues(alpha: 0.04), // micro-opacity cap: 0.04
            spotlightColor.withValues(alpha: 0.0),
          ],
        );
      canvas.drawRect(rect, spotlightPaint);
    }

    // 2. Draw Sandblasted Grain Filter (Tiled Noise)
    final noiseShader = ImageShader(
      noiseImage,
      TileMode.repeated,
      TileMode.repeated,
      Float64List.fromList([
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
      ]),
    );

    final noisePaint = Paint()
      ..shader = noiseShader
      ..color = const Color(
        0x03FFFFFF,
      ); // Colors.white.withValues(alpha: 0.015) (0.015 * 255 = 3.825 ~= 3)

    canvas.drawRect(rect, noisePaint);
  }

  @override
  bool shouldRepaint(covariant GlassBackgroundEffectsPainter oldDelegate) {
    return oldDelegate.isHovered != isHovered ||
        oldDelegate.mousePosition != mousePosition ||
        oldDelegate.spotlightColor != spotlightColor ||
        oldDelegate.noiseImage != noiseImage;
  }
}

class SpecularBorderPainter extends CustomPainter {
  SpecularBorderPainter({
    required this.radius,
    required this.strokeWidth,
    this.customBorderGradient,
  });

  final double radius;
  final double strokeWidth;
  final Gradient? customBorderGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final halfStroke = strokeWidth / 2;
    final dRect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final dRadius = radius - halfStroke;
    final bounds = Offset.zero & size;

    if (customBorderGradient != null) {
      final paint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..shader = customBorderGradient!.createShader(bounds);

      final rrect = RRect.fromRectAndRadius(dRect, Radius.circular(dRadius));
      canvas.drawRRect(rrect, paint);
      return;
    }

    // 1. Top-Left Path (Highlight)
    final pathTopLeft = Path()
      ..moveTo(dRect.left, dRect.bottom - dRadius)
      ..lineTo(dRect.left, dRect.top + dRadius)
      ..arcToPoint(
        Offset(dRect.left + dRadius, dRect.top),
        radius: Radius.circular(dRadius),
      )
      ..lineTo(dRect.right - dRadius, dRect.top);

    final highlightPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x26FFFFFF), // Colors.white.withValues(alpha: 0.15)
          Color(0x05FFFFFF), // Colors.white.withValues(alpha: 0.02)
        ],
      ).createShader(bounds);

    canvas.drawPath(pathTopLeft, highlightPaint);

    // 2. Bottom-Right Path (Shadow)
    final pathBottomRight = Path()
      ..moveTo(dRect.right - dRadius, dRect.top)
      ..arcToPoint(
        Offset(dRect.right, dRect.top + dRadius),
        radius: Radius.circular(dRadius),
      )
      ..lineTo(dRect.right, dRect.bottom - dRadius)
      ..arcToPoint(
        Offset(dRect.right - dRadius, dRect.bottom),
        radius: Radius.circular(dRadius),
      )
      ..lineTo(dRect.left + dRadius, dRect.bottom)
      ..arcToPoint(
        Offset(dRect.left, dRect.bottom - dRadius),
        radius: Radius.circular(dRadius),
      );

    final shadowPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x00000000), // Colors.black.withValues(alpha: 0.0)
          Color(0x33000000), // Colors.black.withValues(alpha: 0.20)
        ],
      ).createShader(bounds);

    canvas.drawPath(pathBottomRight, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant SpecularBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.customBorderGradient != customBorderGradient;
  }
}
