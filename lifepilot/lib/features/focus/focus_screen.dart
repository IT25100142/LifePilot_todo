import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_panel.dart';
import 'focus_providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _completionController;
  final TextEditingController _labelController = TextEditingController(
    text: 'Deep Work',
  );
  int _selectedMinutes = 25;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _completionController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusTimerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRunning =
        state.status == FocusTimerStatus.active ||
        state.status == FocusTimerStatus.paused;

    if (state.showCompletion &&
        _completionController.status != AnimationStatus.forward) {
      _completionController.forward(from: 0.0);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Ambient Background ──
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              color: isRunning
                  ? (isDark ? const Color(0xFF0D0B0E) : const Color(0xFF1A1520))
                  : Colors.transparent,
            ),
          ),

          // ── Idle State Content ──
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isRunning || state.showCompletion ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isRunning || state.showCompletion,
              child: _buildIdleContent(theme, isDark),
            ),
          ),

          // ── Active Timer State ──
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isRunning ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isRunning,
              child: _buildActiveContent(state, theme),
            ),
          ),

          // ── Completion Overlay ──
          if (state.showCompletion)
            AnimatedBuilder(
              animation: _completionController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(
                  _completionController.value,
                );
                return Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
                );
              },
              child: _buildCompletionOverlay(state, theme, isDark),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Idle State — Duration selector, label field, start button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildIdleContent(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.self_improvement_rounded,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 20),
              Text(
                'DEEP FOCUS',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Eliminate distractions. Enter the zone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 40),

              // ── Activity Label ──
              LifePilotGlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _labelController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Session label...',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Duration Selector ──
              Text(
                'SESSION LENGTH',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final mins in [25, 45, 60])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _DurationCapsule(
                        minutes: mins,
                        isSelected: _selectedMinutes == mins,
                        onTap: () => setState(() => _selectedMinutes = mins),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),

              // ── Start Button ──
              SizedBox(
                width: 200,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(focusTimerProvider.notifier)
                        .start(
                          Duration(minutes: _selectedMinutes),
                          _labelController.text,
                        );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(
                    'BEGIN FOCUS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Active State — Breathing circular countdown ring
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActiveContent(FocusTimerState state, ThemeData theme) {
    final minutes = state.remaining.inMinutes;
    final seconds = state.remaining.inSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isPaused = state.status == FocusTimerStatus.paused;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Breathing Countdown Ring ──
            AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                final breathe =
                    1.0 +
                    0.04 * Curves.easeInOut.transform(_breatheController.value);
                return Transform.scale(
                  scale: isPaused ? 1.0 : breathe,
                  child: child,
                );
              },
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Arc ring
                    CustomPaint(
                      size: const Size(260, 260),
                      painter: _CountdownRingPainter(
                        progress: state.progress,
                        color: theme.colorScheme.primary,
                        trackColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    // Time readout
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2.0,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.label.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 48),

            // ── Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel
                _FocusControlButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: () => ref.read(focusTimerProvider.notifier).cancel(),
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 32),
                // Pause / Resume
                _FocusControlButton(
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: isPaused ? 'Resume' : 'Pause',
                  onTap: () {
                    final notifier = ref.read(focusTimerProvider.notifier);
                    isPaused ? notifier.resume() : notifier.pause();
                  },
                  color: theme.colorScheme.primary,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Completion Overlay — Gold congratulatory card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCompletionOverlay(
    FocusTimerState state,
    ThemeData theme,
    bool isDark,
  ) {
    final totalMinutes = state.total.inMinutes;

    return Positioned.fill(
      child: Container(
        color: isDark ? const Color(0xE6100E12) : const Color(0xE61A1520),
        child: SafeArea(
          child: Center(
            child: LifePilotGlassCard(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                ],
              ),
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SESSION COMPLETE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalMinutes minutes of ${state.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saved to your calendar timeline.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      _completionController.reset();
                      ref.read(focusTimerProvider.notifier).dismissCompletion();
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration Selector Capsule
// ─────────────────────────────────────────────────────────────────────────────

class _DurationCapsule extends StatelessWidget {
  const _DurationCapsule({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          '${minutes}m',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus Control Button
// ─────────────────────────────────────────────────────────────────────────────

class _FocusControlButton extends StatelessWidget {
  const _FocusControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isPrimary ? 64 : 52,
            height: isPrimary ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              border: Border.all(
                color: color.withValues(alpha: isPrimary ? 0.5 : 0.25),
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: color, size: isPrimary ? 28 : 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown Ring Painter — Arc-based circular progress indicator
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 4.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
