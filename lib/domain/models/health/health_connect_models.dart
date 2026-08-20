import 'health_metric_type.dart';

/// Status of Google Health Connect availability on the Android device.
enum HealthConnectStatus {
  available,
  notInstalled,
  notSupported;

  static HealthConnectStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'available':
        return HealthConnectStatus.available;
      case 'not_installed':
      case 'notinstalled':
        return HealthConnectStatus.notInstalled;
      case 'not_supported':
      case 'notsupported':
      default:
        return HealthConnectStatus.notSupported;
    }
  }
}

/// Aggregated physical health metrics for a specific calendar date.
class DailyHealthMetrics {
  final String date; // YYYY-MM-DD
  final double? steps;
  final double? exerciseMinutes;
  final double? moveMinutes;
  final double? distanceKm;
  final double? activeCalories;
  final double? hydrationMl;
  final double? sleepMinutes;
  final DateTime fetchedAt;

  const DailyHealthMetrics({
    required this.date,
    this.steps,
    this.exerciseMinutes,
    this.moveMinutes,
    this.distanceKm,
    this.activeCalories,
    this.hydrationMl,
    this.sleepMinutes,
    required this.fetchedAt,
  });

  double? getValue(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.steps:
        return steps;
      case HealthMetricType.exerciseTime:
        return exerciseMinutes;
      case HealthMetricType.moveMinutes:
        return moveMinutes ?? exerciseMinutes;
      case HealthMetricType.distance:
        return distanceKm;
      case HealthMetricType.activeCalories:
        return activeCalories;
      case HealthMetricType.hydration:
        return hydrationMl;
      case HealthMetricType.sleepDuration:
        return sleepMinutes != null ? sleepMinutes! / 60.0 : null; // in hours
    }
  }

  factory DailyHealthMetrics.fromMap(String date, Map<String, dynamic> map) {
    return DailyHealthMetrics(
      date: date,
      steps: (map['steps'] as num?)?.toDouble(),
      exerciseMinutes: (map['exercise_minutes'] as num?)?.toDouble() ??
          (map['exercise_time'] as num?)?.toDouble(),
      moveMinutes: (map['move_minutes'] as num?)?.toDouble() ??
          (map['active_minutes'] as num?)?.toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble() ??
          (map['distance'] as num?)?.toDouble(),
      activeCalories: (map['active_calories'] as num?)?.toDouble() ??
          (map['calories'] as num?)?.toDouble(),
      hydrationMl: (map['hydration_ml'] as num?)?.toDouble() ??
          (map['hydration'] as num?)?.toDouble(),
      sleepMinutes: (map['sleep_minutes'] as num?)?.toDouble() ??
          (map['sleep_duration'] as num?)?.toDouble(),
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'steps': steps,
        'exercise_minutes': exerciseMinutes,
        'move_minutes': moveMinutes,
        'distance_km': distanceKm,
        'active_calories': activeCalories,
        'hydration_ml': hydrationMl,
        'sleep_minutes': sleepMinutes,
        'fetched_at': fetchedAt.toIso8601String(),
      };
}

/// Summary result of a Health Connect sync operation.
class HealthSyncSummary {
  final DateTime syncTime;
  final int habitsChecked;
  final int habitsUpdated;
  final int habitsCompleted;
  final List<String> updatedHabitTitles;
  final String? errorMessage;
  final bool isSuccess;

  const HealthSyncSummary({
    required this.syncTime,
    this.habitsChecked = 0,
    this.habitsUpdated = 0,
    this.habitsCompleted = 0,
    this.updatedHabitTitles = const [],
    this.errorMessage,
    this.isSuccess = true,
  });

  factory HealthSyncSummary.error(String message) => HealthSyncSummary(
        syncTime: DateTime.now(),
        isSuccess: false,
        errorMessage: message,
      );
}
