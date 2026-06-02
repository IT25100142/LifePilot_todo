import 'package:flutter/material.dart';

import '../utils/category_helpers.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.label, this.hasShadow = false});

  final String label;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cleaned = label.trim().toLowerCase();
    final tintColor = categoryBadgeColor(context, cleaned);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tintColor.withValues(alpha: 0.24),
          width: 1.0,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: tintColor.withValues(alpha: 0.08),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label.trim(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tintColor.withValues(alpha: dark ? 0.95 : 0.85),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
