import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

enum FocusTimerStatus { idle, active, paused }

class FocusTimerState {
  const FocusTimerState({
    this.status = FocusTimerStatus.idle,
    this.remaining = Duration.zero,
    this.total = Duration.zero,
    this.label = 'Deep Work',
    this.startedAt,
    this.showCompletion = false,
  });

  final FocusTimerStatus status;
  final Duration remaining;
  final Duration total;
  final String label;
  final DateTime? startedAt;
  final bool showCompletion;

  FocusTimerState copyWith({
    FocusTimerStatus? status,
    Duration? remaining,
    Duration? total,
    String? label,
    DateTime? startedAt,
    bool? showCompletion,
  }) {
    return FocusTimerState(
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
      label: label ?? this.label,
      startedAt: startedAt ?? this.startedAt,
      showCompletion: showCompletion ?? this.showCompletion,
    );
  }

  double get progress =>
      total.inSeconds > 0 ? 1.0 - (remaining.inSeconds / total.inSeconds) : 0.0;
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _ticker;

  @override
  FocusTimerState build() => const FocusTimerState();

  void start(Duration duration, String label) {
    _ticker?.cancel();
    state = FocusTimerState(
      status: FocusTimerStatus.active,
      remaining: duration,
      total: duration,
      label: label.trim().isEmpty ? 'Deep Work' : label.trim(),
      startedAt: DateTime.now(),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void pause() {
    if (state.status != FocusTimerStatus.active) return;
    _ticker?.cancel();
    state = state.copyWith(status: FocusTimerStatus.paused);
  }

  void resume() {
    if (state.status != FocusTimerStatus.paused) return;
    state = state.copyWith(status: FocusTimerStatus.active);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void cancel() {
    _ticker?.cancel();
    state = const FocusTimerState();
  }

  void dismissCompletion() {
    state = const FocusTimerState();
  }

  void _onTick() {
    final next = state.remaining - const Duration(seconds: 1);
    if (next.inSeconds <= 0) {
      _ticker?.cancel();
      _onComplete();
    } else {
      state = state.copyWith(remaining: next);
    }
  }

  void _onComplete() {
    final now = DateTime.now();
    final startTime = state.startedAt ?? now.subtract(state.total);
    final label = state.label;
    final totalMinutes = state.total.inMinutes;

    // Inject a calendar event into the timeline
    final db = ref.read(appDatabaseProvider);
    db.saveEvent(
      CalendarEventsCompanion.insert(
        title: 'Focus Session: $label',
        description: Value('$totalMinutes minute deep focus session'),
        date: DateTime(startTime.year, startTime.month, startTime.day),
        startTime: startTime,
        endTime: now,
      ),
    );

    state = FocusTimerState(
      status: FocusTimerStatus.idle,
      label: label,
      showCompletion: true,
      total: state.total,
    );
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(
      FocusTimerNotifier.new,
    );
