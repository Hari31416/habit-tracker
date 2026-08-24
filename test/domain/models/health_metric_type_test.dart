import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';

void main() {
  group('HealthMetricType', () {
    test('all enum values expose correct properties', () {
      for (final type in HealthMetricType.values) {
        expect(type.id.isNotEmpty, isTrue);
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.description.isNotEmpty, isTrue);
        expect(type.defaultUnit.isNotEmpty, isTrue);
        expect(type.defaultTargetValue, greaterThan(0));
        expect(type.iconKey.isNotEmpty, isTrue);
      }
    });

    test('defaultTargetType returns expected target types', () {
      expect(HealthMetricType.steps.defaultTargetType, HabitTargetType.numeric);
      expect(HealthMetricType.distance.defaultTargetType, HabitTargetType.numeric);
      expect(HealthMetricType.activeCalories.defaultTargetType, HabitTargetType.numeric);
      expect(HealthMetricType.hydration.defaultTargetType, HabitTargetType.numeric);
      expect(HealthMetricType.sleepDuration.defaultTargetType, HabitTargetType.numeric);

      expect(HealthMetricType.exerciseTime.defaultTargetType, HabitTargetType.timer);
      expect(HealthMetricType.moveMinutes.defaultTargetType, HabitTargetType.timer);
    });

    test('fromId parses standard and alternate identifiers correctly', () {
      expect(HealthMetricType.fromId('steps'), HealthMetricType.steps);
      expect(HealthMetricType.fromId('step_count'), HealthMetricType.steps);

      expect(HealthMetricType.fromId('exercise_time'), HealthMetricType.exerciseTime);
      expect(HealthMetricType.fromId('exercisetime'), HealthMetricType.exerciseTime);
      expect(HealthMetricType.fromId('exercise'), HealthMetricType.exerciseTime);

      expect(HealthMetricType.fromId('move_minutes'), HealthMetricType.moveMinutes);
      expect(HealthMetricType.fromId('moveminutes'), HealthMetricType.moveMinutes);
      expect(HealthMetricType.fromId('active_minutes'), HealthMetricType.moveMinutes);
      expect(HealthMetricType.fromId('movement'), HealthMetricType.moveMinutes);

      expect(HealthMetricType.fromId('distance'), HealthMetricType.distance);
      expect(HealthMetricType.fromId('distance_km'), HealthMetricType.distance);

      expect(HealthMetricType.fromId('active_calories'), HealthMetricType.activeCalories);
      expect(HealthMetricType.fromId('calories'), HealthMetricType.activeCalories);
      expect(HealthMetricType.fromId('energy'), HealthMetricType.activeCalories);

      expect(HealthMetricType.fromId('hydration'), HealthMetricType.hydration);
      expect(HealthMetricType.fromId('water'), HealthMetricType.hydration);

      expect(HealthMetricType.fromId('sleep_duration'), HealthMetricType.sleepDuration);
      expect(HealthMetricType.fromId('sleepduration'), HealthMetricType.sleepDuration);
      expect(HealthMetricType.fromId('sleep'), HealthMetricType.sleepDuration);

      expect(HealthMetricType.fromId(null), isNull);
      expect(HealthMetricType.fromId(''), isNull);
      expect(HealthMetricType.fromId('unknown_metric'), isNull);
    });
  });
}
