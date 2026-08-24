import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/health/health_connect_models.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';

void main() {
  group('HealthConnectStatus', () {
    test('fromString parses string values accurately', () {
      expect(HealthConnectStatus.fromString('available'), HealthConnectStatus.available);
      expect(HealthConnectStatus.fromString('not_installed'), HealthConnectStatus.notInstalled);
      expect(HealthConnectStatus.fromString('notinstalled'), HealthConnectStatus.notInstalled);
      expect(HealthConnectStatus.fromString('not_supported'), HealthConnectStatus.notSupported);
      expect(HealthConnectStatus.fromString('notsupported'), HealthConnectStatus.notSupported);
      expect(HealthConnectStatus.fromString(null), HealthConnectStatus.notSupported);
      expect(HealthConnectStatus.fromString('random_value'), HealthConnectStatus.notSupported);
    });
  });

  group('DailyHealthMetrics', () {
    test('getValue maps all HealthMetricTypes correctly', () {
      final metrics = DailyHealthMetrics(
        date: '2026-08-24',
        steps: 8500,
        exerciseMinutes: 45,
        moveMinutes: 60,
        distanceKm: 6.2,
        activeCalories: 380,
        hydrationMl: 2200,
        sleepMinutes: 480, // 8.0 hrs
        fetchedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      );

      expect(metrics.getValue(HealthMetricType.steps), 8500);
      expect(metrics.getValue(HealthMetricType.exerciseTime), 45);
      expect(metrics.getValue(HealthMetricType.moveMinutes), 60);
      expect(metrics.getValue(HealthMetricType.distance), 6.2);
      expect(metrics.getValue(HealthMetricType.activeCalories), 380);
      expect(metrics.getValue(HealthMetricType.hydration), 2200);
      expect(metrics.getValue(HealthMetricType.sleepDuration), 8.0);
    });

    test('getValue falls back to exerciseMinutes when moveMinutes is null', () {
      final metrics = DailyHealthMetrics(
        date: '2026-08-24',
        exerciseMinutes: 30,
        moveMinutes: null,
        fetchedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      );

      expect(metrics.getValue(HealthMetricType.moveMinutes), 30);
    });

    test('fromMap and toMap serialize correctly', () {
      final map = {
        'steps': 10000.0,
        'exercise_minutes': 40.0,
        'move_minutes': 50.0,
        'distance_km': 7.5,
        'active_calories': 450.0,
        'hydration_ml': 2500.0,
        'sleep_minutes': 450.0,
      };

      final metrics = DailyHealthMetrics.fromMap('2026-08-24', map);
      expect(metrics.date, '2026-08-24');
      expect(metrics.steps, 10000.0);
      expect(metrics.exerciseMinutes, 40.0);
      expect(metrics.moveMinutes, 50.0);
      expect(metrics.distanceKm, 7.5);
      expect(metrics.activeCalories, 450.0);
      expect(metrics.hydrationMl, 2500.0);
      expect(metrics.sleepMinutes, 450.0);

      final exported = metrics.toMap();
      expect(exported['date'], '2026-08-24');
      expect(exported['steps'], 10000.0);
      expect(exported['distance_km'], 7.5);
    });
  });

  group('HealthSyncSummary', () {
    test('error factory constructs unsuccessful summary', () {
      final summary = HealthSyncSummary.error('Permission denied');
      expect(summary.isSuccess, isFalse);
      expect(summary.errorMessage, 'Permission denied');
    });

    test('default constructor creates successful summary', () {
      final now = DateTime.now();
      final summary = HealthSyncSummary(
        syncTime: now,
        habitsChecked: 3,
        habitsUpdated: 2,
        habitsCompleted: 1,
        updatedHabitTitles: ['Morning Run', 'Drink Water'],
      );
      expect(summary.isSuccess, isTrue);
      expect(summary.habitsChecked, 3);
      expect(summary.habitsUpdated, 2);
      expect(summary.habitsCompleted, 1);
      expect(summary.updatedHabitTitles, contains('Morning Run'));
    });
  });
}
