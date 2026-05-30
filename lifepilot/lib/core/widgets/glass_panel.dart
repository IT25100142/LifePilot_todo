import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/canvas_studio/canvas_studio_provider.dart';

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

class LifePilotGlassCard extends ConsumerStatefulWidget {
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
    this.isPressed = false,
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
  final bool isPressed;

  @override
  ConsumerState<LifePilotGlassCard> createState() => _LifePilotGlassCardState();
}

class _LifePilotGlassCardState extends ConsumerState<LifePilotGlassCard> {
  bool _isHovered = false;
  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final glassExt = theme.extension<GlassThemeExtension>();
    final glassPhysics = ref.watch(canvasStudioProvider);

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

    final resolvedBlurSigma = widget.blurSigma ?? glassPhysics.blurSigma;
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
        boxShadow: widget.isPressed
            ? []
            : [
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
            spotlightColor: glassPhysics.activeAccentColor.color,
            noiseImage: GlassNoiseCache.noiseImage,
            radius: widget.radius,
            isPressed: widget.isPressed,
            grainOpacity: glassPhysics.grainOpacity,
          ),
          foregroundPainter: SpecularBorderPainter(
            radius: widget.radius,
            strokeWidth: 0.75, // Crisp 0.75px specular border highlight
            customBorderGradient: resolvedBorderGradient,
            isPressed: widget.isPressed,
            specularOpacity: glassPhysics.specularOpacity,
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
    required this.radius,
    required this.isPressed,
    required this.grainOpacity,
  });

  final bool isHovered;
  final Offset mousePosition;
  final Color spotlightColor;
  final ui.Image noiseImage;
  final double radius;
  final bool isPressed;
  final double grainOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (isPressed) {
      // Draw neomorphic inset depression shadows
      canvas.save();
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.clipRRect(rrect);

      // Top-Left dark inset shadow
      final shadowPath = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + radius)
        ..arcToPoint(
          Offset(rect.left + radius, rect.top),
          radius: Radius.circular(radius),
        )
        ..lineTo(rect.right, rect.top);

      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawPath(shadowPath, shadowPaint);

      // Bottom-Right light inset reflection
      final lightPath = Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - radius)
        ..arcToPoint(
          Offset(rect.right - radius, rect.bottom),
          radius: Radius.circular(radius),
        )
        ..lineTo(rect.left, rect.bottom);

      final lightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawPath(lightPath, lightPaint);

      canvas.restore();
    } else {
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
      ..color = Colors.white.withValues(alpha: grainOpacity.clamp(0.0, 1.0));

    canvas.drawRect(rect, noisePaint);
  }

  @override
  bool shouldRepaint(covariant GlassBackgroundEffectsPainter oldDelegate) {
    return oldDelegate.isHovered != isHovered ||
        oldDelegate.mousePosition != mousePosition ||
        oldDelegate.spotlightColor != spotlightColor ||
        oldDelegate.noiseImage != noiseImage ||
        oldDelegate.radius != radius ||
        oldDelegate.isPressed != isPressed ||
        oldDelegate.grainOpacity != grainOpacity;
  }
}

class SpecularBorderPainter extends CustomPainter {
  SpecularBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.specularOpacity,
    this.customBorderGradient,
    this.isPressed = false,
  });

  final double radius;
  final double strokeWidth;
  final double specularOpacity;
  final Gradient? customBorderGradient;
  final bool isPressed;

  @override
  void paint(Canvas canvas, Size size) {
    final halfStroke = strokeWidth / 2;
    final dRect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final dRadius = math.max(0.0, radius - halfStroke);
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

    // 1. Top-Left Path (Highlight / Deep Translucent Shadow Line)
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
      ..shader =
          (isPressed
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(
                          alpha: (specularOpacity * 1.33).clamp(0.0, 1.0),
                        ),
                        const Color(0x00000000),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(
                          alpha: specularOpacity.clamp(0.0, 1.0),
                        ),
                        Colors.white.withValues(
                          alpha: (specularOpacity * 0.13).clamp(0.0, 1.0),
                        ),
                      ],
                    ))
              .createShader(bounds);

    canvas.drawPath(pathTopLeft, highlightPaint);

    // 2. Bottom-Right Path (Shadow / Faint White Light Capture)
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
      ..shader =
          (isPressed
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0x00FFFFFF),
                        Colors.white.withValues(
                          alpha: (specularOpacity * 0.53).clamp(0.0, 1.0),
                        ),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0x00000000),
                        Colors.black.withValues(
                          alpha: (specularOpacity * 1.33).clamp(0.0, 1.0),
                        ),
                      ],
                    ))
              .createShader(bounds);

    canvas.drawPath(pathBottomRight, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant SpecularBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.customBorderGradient != customBorderGradient ||
        oldDelegate.isPressed != isPressed ||
        oldDelegate.specularOpacity != specularOpacity;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specular Light Sweep ("Gleam" Effect) components
// ─────────────────────────────────────────────────────────────────────────────

class LifePilotGleamRegistry {
  static final _controllers = <String, LifePilotGleamController>{};

  static void register(String id, LifePilotGleamController controller) {
    _controllers[id] = controller;
  }

  static void unregister(String id) {
    _controllers.remove(id);
  }

  static void trigger(String id) {
    _controllers[id]?.trigger();
  }
}

class LifePilotGleamController extends ChangeNotifier {
  void trigger() {
    notifyListeners();
  }
}

class LifePilotGleam extends StatefulWidget {
  const LifePilotGleam({
    required this.child,
    this.controller,
    this.gleamId,
    this.radius = LifePilotTheme.glassRadius,
    super.key,
  });

  final Widget child;
  final LifePilotGleamController? controller;
  final String? gleamId;
  final double radius;

  @override
  State<LifePilotGleam> createState() => _LifePilotGleamState();
}

class _LifePilotGleamState extends State<LifePilotGleam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final LifePilotGleamController _localController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _localController = widget.controller ?? LifePilotGleamController();
    _localController.addListener(_onTrigger);
    if (widget.gleamId != null) {
      LifePilotGleamRegistry.register(widget.gleamId!, _localController);
    }
  }

  @override
  void didUpdateWidget(covariant LifePilotGleam oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gleamId != widget.gleamId) {
      if (oldWidget.gleamId != null) {
        LifePilotGleamRegistry.unregister(oldWidget.gleamId!);
      }
      if (widget.gleamId != null) {
        LifePilotGleamRegistry.register(widget.gleamId!, _localController);
      }
    }
  }

  @override
  void dispose() {
    if (widget.gleamId != null) {
      LifePilotGleamRegistry.unregister(widget.gleamId!);
    }
    _localController.removeListener(_onTrigger);
    if (widget.controller == null) {
      _localController.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _onTrigger() {
    if (_animController.isAnimating) {
      _animController.stop();
    }
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _GleamPainter(
          animation: _animController,
          radius: widget.radius,
        ),
        child: widget.child,
      ),
    );
  }
}

class _GleamPainter extends CustomPainter {
  _GleamPainter({required this.animation, required this.radius})
    : super(repaint: animation);

  final Animation<double> animation;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0.0 || t == 1.0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.5 + t * 3.0, -1.5 + t * 3.0),
        end: Alignment(-0.5 + t * 3.0, -0.5 + t * 3.0),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.1, 0.5, 0.9],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GleamPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}
