import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'glass_panel.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({required this.child, super.key});

  final Widget child;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
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
    final dark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.9 + t * 0.22, -1),
              end: Alignment(0.9 - t * 0.18, 1),
              colors: dark
                  ? const [
                      Color(0xFF061312),
                      Color(0xFF0E1824),
                      Color(0xFF101015),
                    ]
                  : const [
                      Color(0xFFEAFDFC),
                      Color(0xFFF4F7FF),
                      Color(0xFFFFFFFF),
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        theme.colorScheme.primary.withValues(
                          alpha: dark ? 0.16 : 0.22,
                        ),
                        Colors.transparent,
                        theme.colorScheme.tertiary.withValues(
                          alpha: dark ? 0.14 : 0.2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: child!),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}


class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding,
    this.radius = LifePilotTheme.glassRadius,
    this.opacity,
    this.borderOpacity,
    this.blur = LifePilotTheme.glassBlur,
    this.constraints,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double? opacity;
  final double? borderOpacity;
  final double blur;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LifePilotGlassCard(
      padding: padding,
      radius: radius,
      constraints: constraints,
      onTap: onTap,
      child: child,
    );
  }
}

class GlassIcon extends StatelessWidget {
  const GlassIcon({required this.icon, this.color, super.key});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      radius: 18,
      blur: 18,
      padding: const EdgeInsets.all(10),
      opacity: theme.brightness == Brightness.dark ? 0.22 : 0.66,
      child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
    );
  }
}

class AnimatedGlassItem extends StatelessWidget {
  const AnimatedGlassItem({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: LifePilotTheme.pageDuration + delay,
      curve: LifePilotTheme.quickCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
