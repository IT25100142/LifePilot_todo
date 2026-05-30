import 'package:flutter/material.dart';

import 'glass_panel.dart';

class InteractiveButton extends StatefulWidget {
  const InteractiveButton({
    required this.child,
    this.onTap,
    this.radius = 16.0,
    this.padding,
    this.constraints,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    // Specular border gradient becomes brighter and clearer on hover
    final defaultBorderGradient = dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(
                0xFFE0CFA7,
              ).withValues(alpha: _isHovered ? 0.65 : 0.40),
              const Color(
                0xFFC8B89A,
              ).withValues(alpha: _isHovered ? 0.25 : 0.10),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(
                0xFFD4C4A0,
              ).withValues(alpha: _isHovered ? 0.60 : 0.35),
              const Color(
                0xFFB5AAA0,
              ).withValues(alpha: _isHovered ? 0.28 : 0.12),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        child: LifePilotGlassCard(
          radius: widget.radius,
          padding: widget.padding,
          constraints: widget.constraints,
          borderGradient: defaultBorderGradient,
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
