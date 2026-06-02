import 'package:flutter/material.dart';

Color categoryBadgeColor(BuildContext context, String cleanedTag) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;

  switch (cleanedTag) {
    case 'work':
    case 'work & focus':
    case 'focus':
      return dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    case 'personal':
      return theme.colorScheme.primary;
    case 'health':
    case 'urgent':
    case 'health/urgent':
    case 'health & fitness':
    case 'fitness':
      return const Color(0xFFE0516F);
    case 'ideas':
    case 'mind & soul':
    case 'mindfulness':
      return dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
    case 'finance':
    case 'learning':
    case 'study':
      return const Color(0xFF286C63);
    case 'daily routine':
    case 'routine':
      return dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    default:
      return theme.colorScheme.secondary;
  }
}
