import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_target_type.dart';
import '../models/health/health_connect_models.dart';
import '../models/health/health_metric_type.dart';

/// Computed update payload for a single habit based on health metrics.
class HealthSyncHabitUpdate {
  final Habit habit;
  final String date;
  final bool shouldUpdate;
  final double syncValue;
  final bool isCompleted;
  final int? durationSeconds;
  final bool wasNewlyCompleted;

  const HealthSyncHabitUpdate({
    required this.habit,
    required this.date,
    required this.shouldUpdate,
    required this.syncValue,
    required this.isCompleted,
    this.durationSeconds,
    this.wasNewlyCompleted = false,
  });
}

/// Pure deterministic calculation engine that converts Health Connect metrics
/// into habit log states, unit normalizations, and completion evaluations.
class HealthSyncEngine {
  const HealthSyncEngine();

  /// Evaluates an individual habit against incoming daily health metrics.
  HealthSyncHabitUpdate evaluateHabit({
    required Habit habit,
    required DailyHealthMetrics metrics,
    required List<HabitLog> existingLogs,
  }) {
    if (!habit.healthSyncEnabled || habit.healthMetric == null || habit.archived || habit.isDeleted) {
      return HealthSyncHabitUpdate(
        habit: habit,
        date: metrics.date,
        shouldUpdate: false,
        syncValue: 0.0,
        isCompleted: false,
      );
    }

    final rawValue = metrics.getValue(habit.healthMetric!);
    if (rawValue == null) {
      return HealthSyncHabitUpdate(
        habit: habit,
        date: metrics.date,
        shouldUpdate: false,
        syncValue: 0.0,
        isCompleted: false,
      );
    }

    final normalizedValue = _normalizeValue(habit, habit.healthMetric!, rawValue);
    final target = habit.targetValue ?? habit.healthMetric!.defaultTargetValue;
    final isCompleted = normalizedValue >= target;

    // Check existing state to determine if change occurred
    final wasAlreadyCompleted = existingLogs.any((l) => l.completed);
    final currentLoggedValue = existingLogs.fold<double>(
      0.0,
      (sum, l) => sum + (l.value ?? (l.durationSeconds != null ? l.durationSeconds! / 60.0 : 0.0)),
    );

    // Only update if value differs meaningfully or completion status changed
    final valueDiffers = (normalizedValue - currentLoggedValue).abs() >= 0.01;
    final completionChanged = isCompleted != wasAlreadyCompleted;
    final shouldUpdate = valueDiffers || completionChanged || existingLogs.isEmpty;

    final durationSec = habit.targetType == HabitTargetType.timer
        ? (normalizedValue * 60).toInt()
        : null;

    final wasNewlyCompleted = isCompleted && !wasAlreadyCompleted;

    return HealthSyncHabitUpdate(
      habit: habit,
      date: metrics.date,
      shouldUpdate: shouldUpdate,
      syncValue: normalizedValue,
      isCompleted: isCompleted,
      durationSeconds: durationSec,
      wasNewlyCompleted: wasNewlyCompleted,
    );
  }

  /// Evaluates all eligible habits for a specific date against incoming metrics.
  List<HealthSyncHabitUpdate> evaluateAll({
    required List<Habit> habits,
    required DailyHealthMetrics metrics,
    required Map<String, List<HabitLog>> logsByHabit,
  }) {
    final updates = <HealthSyncHabitUpdate>[];
    for (final habit in habits) {
      if (habit.healthSyncEnabled && habit.healthMetric != null) {
        final existing = logsByHabit[habit.id] ?? const [];
        final update = evaluateHabit(
          habit: habit,
          metrics: metrics,
          existingLogs: existing,
        );
        if (update.shouldUpdate) {
          updates.add(update);
        }
      }
    }
    return updates;
  }

  /// Normalizes units between Health Connect native units and user habit unit settings.
  double _normalizeValue(Habit habit, HealthMetricType metricType, double rawValue) {
    final unit = (habit.unit ?? metricType.defaultUnit).toLowerCase().trim();

    switch (metricType) {
      case HealthMetricType.steps:
        return rawValue.roundToDouble();

      case HealthMetricType.exerciseTime:
      case HealthMetricType.moveMinutes:
        // rawValue is in minutes
        if (unit == 'hrs' || unit == 'hours' || unit == 'h') {
          return (rawValue / 60.0 * 100).roundToDouble() / 100.0;
        }
        return rawValue;

      case HealthMetricType.distance:
        // rawValue is in kilometers (km)
        if (unit == 'm' || unit == 'meters' || unit == 'metres') {
          return (rawValue * 1000.0).roundToDouble();
        } else if (unit == 'mi' || unit == 'miles' || unit == 'mile') {
          // 1 mile ~ 1.60934 km
          return (rawValue / 1.60934 * 100).roundToDouble() / 100.0;
        }
        return (rawValue * 100).roundToDouble() / 100.0;

      case HealthMetricType.activeCalories:
        // rawValue is in kcal
        return rawValue.roundToDouble();

      case HealthMetricType.hydration:
        // rawValue is in milliliters (ml)
        if (unit == 'l' || unit == 'liters' || unit == 'litres') {
          return (rawValue / 1000.0 * 100).roundToDouble() / 100.0;
        } else if (unit == 'oz' || unit == 'fl oz') {
          // 1 fl oz ~ 29.5735 ml
          return (rawValue / 29.5735 * 10).roundToDouble() / 10.0;
        } else if (unit == 'glasses' || unit == 'cups') {
          // 1 standard glass ~ 250ml
          return (rawValue / 250.0 * 10).roundToDouble() / 10.0;
        }
        return rawValue;

      case HealthMetricType.sleepDuration:
        // rawValue is in hours
        if (unit == 'min' || unit == 'minutes' || unit == 'm') {
          return (rawValue * 60.0).roundToDouble();
        }
        return (rawValue * 10).roundToDouble() / 10.0; // round to 1 decimal
    }
  }
}
