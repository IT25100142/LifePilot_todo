import 'package:flutter/material.dart';

import 'glass.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedGlassItem(
      child: GlassPanel(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || action != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.86,
                              ),
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            if (title != null || action != null) const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
