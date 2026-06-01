import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_customizer_provider.dart';

class AmbientBackdrop extends ConsumerWidget {
  const AmbientBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customizer = ref.watch(themeCustomizerProvider);
    final tint = customizer.backdropTintColor;

    final primaryGlow = const Color(
      0xFFD6BD92,
    ).withValues(alpha: isDark ? 0.12 : 0.10);
    final secondaryGlow = const Color(
      0xFFC8A97A,
    ).withValues(alpha: isDark ? 0.10 : 0.08);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: tint, end: tint),
      duration: const Duration(milliseconds: 300),
      builder: (context, animatedTint, child) {
        final currentTint = animatedTint ?? tint;
        final baseColor = isDark
            ? Color.alphaBlend(
                currentTint.withValues(alpha: 0.5),
                const Color(0xFF151316),
              )
            : Color.alphaBlend(
                currentTint.withValues(alpha: 0.1),
                const Color(0xFFF7F3EC),
              );
        return Stack(
          children: [
            Positioned.fill(child: Container(color: baseColor)),
            Positioned(
              top: -120,
              left: -120,
              width: 380,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primaryGlow, primaryGlow.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -150,
              width: 480,
              height: 480,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [secondaryGlow, secondaryGlow.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
