import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_customizer_provider.dart';

class AmbientCanvasBackground extends ConsumerStatefulWidget {
  const AmbientCanvasBackground({super.key});

  @override
  ConsumerState<AmbientCanvasBackground> createState() =>
      _AmbientCanvasBackgroundState();
}

class _AmbientCanvasBackgroundState
    extends ConsumerState<AmbientCanvasBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _elapsedTime = 0.0;
  double _lastAnimationValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Use a long-duration controller for a continuous ticking baseline
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3600),
    );
    _controller.addListener(_updateTime);
    _controller.repeat();
  }

  void _updateTime() {
    final customizer = ref.read(themeCustomizerProvider);
    final currentVal = _controller.value;
    double delta = currentVal - _lastAnimationValue;
    if (delta < 0) {
      // Handled loop wrap around
      delta += 1.0;
    }
    _lastAnimationValue = currentVal;

    // Scale delta speed dynamically based on active customizer parameters
    setState(() {
      _elapsedTime += delta * 150.0 * customizer.animationSpeed;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateTime);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customizer = ref.watch(themeCustomizerProvider);
    final colors = customizer.activeAtmosphere.atmosphereColors;

    return ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
        child: CustomPaint(
          painter: _AmbientCanvasPainter(colors: colors, time: _elapsedTime),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AmbientCanvasPainter extends CustomPainter {
  final List<Color> colors;
  final double time;

  _AmbientCanvasPainter({required this.colors, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // 1. Draw solid/gradient background base layer
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader =
        ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), [
          colors[0].withValues(alpha: 0.90),
          colors.length > 1 ? colors[1].withValues(alpha: 0.80) : colors[0],
        ]);
    canvas.drawRect(rect, paint);

    // Apply global canvas coordinate rotation relative to the viewport center
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(time * 0.005);
    canvas.translate(-size.width / 2, -size.height / 2);

    // 2. Draw drifting color vector blobs
    final int blobCount = colors.length;
    for (int i = 0; i < blobCount; i++) {
      final color = colors[i];

      final speedX = 0.03 + (i * 0.015);
      final speedY = 0.02 + (i * 0.02);
      final phase = i * (math.pi / 2.0);

      // Map drifting center of gradient
      final driftX =
          size.width * (0.5 + 0.35 * math.sin(time * speedX + phase));
      final driftY =
          size.height * (0.5 + 0.35 * math.cos(time * speedY + phase));

      // Map expanding radius size
      final baseRadius = math.min(size.width, size.height) * 0.65;
      final radius = baseRadius * (0.8 + 0.25 * math.sin(time * 0.02 + phase));

      paint.shader = ui.Gradient.radial(Offset(driftX, driftY), radius, [
        color.withValues(alpha: 0.50),
        color.withValues(alpha: 0.0),
      ]);

      canvas.drawCircle(Offset(driftX, driftY), radius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AmbientCanvasPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.colors != colors;
  }
}
