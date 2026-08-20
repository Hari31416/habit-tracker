import '../habit_target_type.dart';

/// Supported physical health metrics from Google Health Connect.
enum HealthMetricType {
  steps,
  exerciseTime,
  moveMinutes,
  distance,
  activeCalories,
  hydration,
  sleepDuration;

  String get id {
    switch (this) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.exerciseTime:
        return 'exercise_time';
      case HealthMetricType.moveMinutes:
        return 'move_minutes';
      case HealthMetricType.distance:
        return 'distance';
      case HealthMetricType.activeCalories:
        return 'active_calories';
      case HealthMetricType.hydration:
        return 'hydration';
      case HealthMetricType.sleepDuration:
        return 'sleep_duration';
    }
  }

  String get displayName {
    switch (this) {
      case HealthMetricType.steps:
        return 'Daily Steps';
      case HealthMetricType.exerciseTime:
        return 'Active Exercise';
      case HealthMetricType.moveMinutes:
        return 'Move Minutes';
      case HealthMetricType.distance:
        return 'Distance';
      case HealthMetricType.activeCalories:
        return 'Active Calories';
      case HealthMetricType.hydration:
        return 'Hydration';
      case HealthMetricType.sleepDuration:
        return 'Sleep Duration';
    }
  }

  String get description {
    switch (this) {
      case HealthMetricType.steps:
        return 'Step count recorded from phone or fitness tracker';
      case HealthMetricType.exerciseTime:
        return 'Active workout and exercise duration in minutes';
      case HealthMetricType.moveMinutes:
        return 'Active movement and brisk activity minutes from Google Fit';
      case HealthMetricType.distance:
        return 'Total running, walking, and cycling distance traveled';
      case HealthMetricType.activeCalories:
        return 'Active energy and calories burned throughout the day';
      case HealthMetricType.hydration:
        return 'Total fluid and water intake logged';
      case HealthMetricType.sleepDuration:
        return 'Total sleep session duration in hours';
    }
  }

  String get defaultUnit {
    switch (this) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.exerciseTime:
      case HealthMetricType.moveMinutes:
        return 'min';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.activeCalories:
        return 'kcal';
      case HealthMetricType.hydration:
        return 'ml';
      case HealthMetricType.sleepDuration:
        return 'hrs';
    }
  }

  double get defaultTargetValue {
    switch (this) {
      case HealthMetricType.steps:
        return 10000.0;
      case HealthMetricType.exerciseTime:
        return 30.0;
      case HealthMetricType.moveMinutes:
        return 60.0;
      case HealthMetricType.distance:
        return 5.0;
      case HealthMetricType.activeCalories:
        return 400.0;
      case HealthMetricType.hydration:
        return 2500.0;
      case HealthMetricType.sleepDuration:
        return 8.0;
    }
  }

  HabitTargetType get defaultTargetType {
    switch (this) {
      case HealthMetricType.steps:
      case HealthMetricType.distance:
      case HealthMetricType.activeCalories:
      case HealthMetricType.hydration:
      case HealthMetricType.sleepDuration:
        return HabitTargetType.numeric;
      case HealthMetricType.exerciseTime:
      case HealthMetricType.moveMinutes:
        return HabitTargetType.timer;
    }
  }

  String get iconKey {
    switch (this) {
      case HealthMetricType.steps:
        return 'footprints';
      case HealthMetricType.exerciseTime:
        return 'dumbbell';
      case HealthMetricType.moveMinutes:
        return 'zap';
      case HealthMetricType.distance:
        return 'compass';
      case HealthMetricType.activeCalories:
        return 'flame';
      case HealthMetricType.hydration:
        return 'droplet';
      case HealthMetricType.sleepDuration:
        return 'moon';
    }
  }

  static HealthMetricType? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    switch (id.toLowerCase()) {
      case 'steps':
      case 'step_count':
        return HealthMetricType.steps;
      case 'exercise_time':
      case 'exercisetime':
      case 'exercise':
        return HealthMetricType.exerciseTime;
      case 'move_minutes':
      case 'moveminutes':
      case 'active_minutes':
      case 'activeminutes':
      case 'movement':
        return HealthMetricType.moveMinutes;
      case 'distance':
      case 'distance_km':
        return HealthMetricType.distance;
      case 'active_calories':
      case 'activecalories':
      case 'calories':
      case 'energy':
        return HealthMetricType.activeCalories;
      case 'hydration':
      case 'water':
        return HealthMetricType.hydration;
      case 'sleep_duration':
      case 'sleepduration':
      case 'sleep':
        return HealthMetricType.sleepDuration;
      default:
        return null;
    }
  }
}
