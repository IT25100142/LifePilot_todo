import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension GradientValueExtension on Gradient {
  Color get value => Colors
      .transparent; // Fallback color to allow LinearGradient(...).value to compile
}

class SatinGlassCard extends StatelessWidget {
  const SatinGlassCard({
    required this.child,
    this.isPressed = false,
    super.key,
  });

  final Widget child;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: isPressed
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              width: 0.5,
              color: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ).value, // Treat color layout linearly across angles
            ),
          ),
          child: CustomPaint(
            foregroundPainter: _GradientBorderPainter(
              radius: 24.0,
              strokeWidth: 0.5,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SatinGlassTextField extends StatefulWidget {
  const SatinGlassTextField({
    required this.controller,
    required this.labelText,
    this.style,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.focusNode,
    this.validator,
    this.maxLines = 1,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final TextStyle? style;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final String? hintText;

  @override
  State<SatinGlassTextField> createState() => _SatinGlassTextFieldState();
}

class _SatinGlassTextFieldState extends State<SatinGlassTextField> {
  late final FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFD6BD92);
    final borderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isFocused
          ? [gold.withValues(alpha: 0.55), gold.withValues(alpha: 0.20)]
          : [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.02),
            ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: CustomPaint(
            foregroundPainter: _GradientBorderPainter(
              radius: 24.0,
              strokeWidth: 0.5,
              gradient: borderGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _effectiveFocusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                inputFormatters: widget.inputFormatters,
                validator: widget.validator,
                maxLines: widget.maxLines,
                style:
                    widget.style ??
                    const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  labelStyle: TextStyle(
                    color: _isFocused
                        ? gold
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

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

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(bounds);

    final rrect = RRect.fromRectAndRadius(dRect, Radius.circular(dRadius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}
