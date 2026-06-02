import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../theme/theme_customizer_provider.dart';
import 'glass_panel.dart';

export 'interactive_button.dart';
export 'satin_glass_card.dart';
export 'glass_panel.dart';

class LiquidBackground extends ConsumerStatefulWidget {
  const LiquidBackground({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends ConsumerState<LiquidBackground>
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
    final customizer = ref.watch(themeCustomizerProvider);
    final tint = customizer.backdropTintColor;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: tint, end: tint),
      duration: const Duration(milliseconds: 300),
      builder: (context, animatedTint, child) {
        final currentTint = animatedTint ?? tint;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final baseColors = dark
                ? [
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.45),
                      const Color(0xFF151316),
                    ),
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.3),
                      const Color(0xFF1A171A),
                    ),
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.15),
                      const Color(0xFF1D1A1E),
                    ),
                  ]
                : [
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.08),
                      const Color(0xFFF7F3EC),
                    ),
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.05),
                      const Color(0xFFF9F6F0),
                    ),
                    Color.alphaBlend(
                      currentTint.withValues(alpha: 0.02),
                      const Color(0xFFFFFCF8),
                    ),
                  ];

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.9 + t * 0.22, -1),
                  end: Alignment(0.9 - t * 0.18, 1),
                  colors: baseColors,
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
                            const Color(
                              0xFFD6BD92,
                            ).withValues(alpha: dark ? 0.12 : 0.16),
                            Colors.transparent,
                            const Color(
                              0xFFC8A97A,
                            ).withValues(alpha: dark ? 0.10 : 0.14),
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
      },
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
      radius: 22,
      blur: 18,
      padding: const EdgeInsets.all(10),
      opacity: theme.brightness == Brightness.dark ? 0.28 : 0.70,
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
