import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LifePilotMeshBackdrop extends StatefulWidget {
  const LifePilotMeshBackdrop({super.key});

  @override
  State<LifePilotMeshBackdrop> createState() => _LifePilotMeshBackdropState();
}

class _LifePilotMeshBackdropState extends State<LifePilotMeshBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;

          // Compute shifting positions & scales dynamically using sine & cosine waves
          // Orb 1: Soft Champagne Gold (Top-left drifting toward center-right)
          final x1 = size.width * (0.15 + 0.35 * math.sin(t * 2 * math.pi));
          final y1 = size.height * (0.2 + 0.3 * math.cos(t * 2 * math.pi));
          final scale1 = 1.0 + 0.25 * math.sin(t * 2 * math.pi);

          // Orb 2: Muted Velvet Indigo (Bottom-right drifting toward center-left)
          final x2 =
              size.width * (0.8 - 0.4 * math.cos((t + 0.25) * 2 * math.pi));
          final y2 =
              size.height * (0.75 - 0.35 * math.sin((t + 0.25) * 2 * math.pi));
          final scale2 = 0.95 + 0.3 * math.cos((t + 0.3) * 2 * math.pi);

          // Orb 3: Slate Charcoal / Deep Dark Teal (Bottom-left drifting toward top-right)
          final x3 =
              size.width * (0.25 + 0.45 * math.cos((t + 0.5) * 2 * math.pi));
          final y3 =
              size.height * (0.7 - 0.4 * math.sin((t + 0.5) * 2 * math.pi));
          final scale3 = 1.05 + 0.2 * math.sin((t + 0.6) * 2 * math.pi);

          const baseOrbSize = 500.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Orb 1 (Champagne Gold)
              Positioned(
                left: x1 - (baseOrbSize * scale1 / 2),
                top: y1 - (baseOrbSize * scale1 / 2),
                width: baseOrbSize * scale1,
                height: baseOrbSize * scale1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                        theme.colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Orb 2 (Muted Velvet Indigo)
              Positioned(
                left: x2 - (baseOrbSize * scale2 / 2),
                top: y2 - (baseOrbSize * scale2 / 2),
                width: baseOrbSize * scale2,
                height: baseOrbSize * scale2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.tertiary.withValues(alpha: 0.06),
                        theme.colorScheme.tertiary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Orb 3 (Slate Charcoal / Teal)
              Positioned(
                left: x3 - (baseOrbSize * scale3 / 2),
                top: y3 - (baseOrbSize * scale3 / 2),
                width: baseOrbSize * scale3,
                height: baseOrbSize * scale3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.05),
                        theme.colorScheme.secondary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Global heavy blur filter to melt everything into a seamless mesh
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 90.0, sigmaY: 90.0),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
