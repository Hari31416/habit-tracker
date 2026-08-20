import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/health_sync_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/health/health_connect_models.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';

void main() {
  const engine = HealthSyncEngine();
  final now = DateTime.now();

  Habit createHabit({
    required String id,
    required String title,
    HealthMetricType? healthMetric,
    bool healthSyncEnabled = true,
    HabitTargetType targetType = HabitTargetType.numeric,
    double targetValue = 10000.0,
    String? unit,
    bool archived = false,
    bool isDeleted = false,
  }) {
    return Habit(
      id: id,
      title: title,
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: targetType,
      targetValue: targetValue,
      unit: unit,
      healthMetric: healthMetric,
      healthSyncEnabled: healthSyncEnabled,
      archived: archived,
      isDeleted: isDeleted,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('HealthSyncEngine Tests', () {
    test('Steps metric evaluates completion when step count reaches target', () {
      final habit = createHabit(
        id: 'h_steps',
        title: 'Daily 10k Steps',
        healthMetric: HealthMetricType.steps,
        targetValue: 10000,
        unit: 'steps',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 10500,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 10500.0);
      expect(update.isCompleted, isTrue);
      expect(update.wasNewlyCompleted, isTrue);
    });

    test('Steps metric marks as incomplete when below target', () {
      final habit = createHabit(
        id: 'h_steps',
        title: 'Daily 10k Steps',
        healthMetric: HealthMetricType.steps,
        targetValue: 10000,
        unit: 'steps',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 7420,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 7420.0);
      expect(update.isCompleted, isFalse);
      expect(update.wasNewlyCompleted, isFalse);
    });

    test('Active exercise minutes evaluates timer habit target', () {
      final habit = createHabit(
        id: 'h_exercise',
        title: 'Workout Session',
        healthMetric: HealthMetricType.exerciseTime,
        targetType: HabitTargetType.timer,
        targetValue: 30, // 30 minutes
        unit: 'min',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        exerciseMinutes: 45,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 45.0);
      expect(update.isCompleted, isTrue);
      expect(update.durationSeconds, 2700); // 45 min * 60
    });

    test('Hydration normalizes liters to ml target', () {
      final habit = createHabit(
        id: 'h_water',
        title: 'Drink Water',
        healthMetric: HealthMetricType.hydration,
        targetValue: 2.5, // 2.5 Liters
        unit: 'liters',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        hydrationMl: 2600, // 2.6 Liters
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 2.6);
      expect(update.isCompleted, isTrue);
    });

    test('Hydration normalizes glasses to ml', () {
      final habit = createHabit(
        id: 'h_water_glasses',
        title: 'Drink 8 Glasses',
        healthMetric: HealthMetricType.hydration,
        targetValue: 8.0,
        unit: 'glasses',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        hydrationMl: 2000, // 2000ml / 250ml = 8 glasses
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 8.0);
      expect(update.isCompleted, isTrue);
    });

    test('Move minutes evaluates timer target', () {
      final habit = createHabit(
        id: 'h_move',
        title: 'Daily Move Minutes',
        healthMetric: HealthMetricType.moveMinutes,
        targetType: HabitTargetType.timer,
        targetValue: 60.0,
        unit: 'min',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        moveMinutes: 75.0,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 75.0);
      expect(update.isCompleted, isTrue);
      expect(update.durationSeconds, 4500);
    });

    test('Distance evaluates km and normalizes miles', () {
      final habitKm = createHabit(
        id: 'h_dist_km',
        title: 'Walk 5km',
        healthMetric: HealthMetricType.distance,
        targetValue: 5.0,
        unit: 'km',
      );

      final habitMi = createHabit(
        id: 'h_dist_mi',
        title: 'Run 3.1 miles',
        healthMetric: HealthMetricType.distance,
        targetValue: 3.1,
        unit: 'miles',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        distanceKm: 5.2, // ~3.23 miles
        fetchedAt: now,
      );

      final updateKm = engine.evaluateHabit(
        habit: habitKm,
        metrics: metrics,
        existingLogs: const [],
      );

      final updateMi = engine.evaluateHabit(
        habit: habitMi,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(updateKm.shouldUpdate, isTrue);
      expect(updateKm.syncValue, 5.2);
      expect(updateKm.isCompleted, isTrue);

      expect(updateMi.shouldUpdate, isTrue);
      expect(updateMi.isCompleted, isTrue);
    });

    test('Active calories evaluates kcal target', () {
      final habit = createHabit(
        id: 'h_cal',
        title: 'Burn 400 kcal',
        healthMetric: HealthMetricType.activeCalories,
        targetValue: 400.0,
        unit: 'kcal',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        activeCalories: 450.0,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 450.0);
      expect(update.isCompleted, isTrue);
    });

    test('Sleep duration evaluates hours target', () {
      final habit = createHabit(
        id: 'h_sleep',
        title: 'Sleep 8 Hours',
        healthMetric: HealthMetricType.sleepDuration,
        targetValue: 8.0,
        unit: 'hrs',
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        sleepMinutes: 480, // 8 hours
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(update.shouldUpdate, isTrue);
      expect(update.syncValue, 8.0);
      expect(update.isCompleted, isTrue);
    });

    test('Does not update when health sync is disabled or habit is archived', () {
      final disabledHabit = createHabit(
        id: 'h_disabled',
        title: 'Disabled Sync',
        healthMetric: HealthMetricType.steps,
        healthSyncEnabled: false,
      );

      final archivedHabit = createHabit(
        id: 'h_archived',
        title: 'Archived Habit',
        healthMetric: HealthMetricType.steps,
        archived: true,
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 12000,
        fetchedAt: now,
      );

      final updateDisabled = engine.evaluateHabit(
        habit: disabledHabit,
        metrics: metrics,
        existingLogs: const [],
      );

      final updateArchived = engine.evaluateHabit(
        habit: archivedHabit,
        metrics: metrics,
        existingLogs: const [],
      );

      expect(updateDisabled.shouldUpdate, isFalse);
      expect(updateArchived.shouldUpdate, isFalse);
    });

    test('Does not mark shouldUpdate if value and completion are identical to existing log', () {
      final habit = createHabit(
        id: 'h_steps',
        title: 'Steps',
        healthMetric: HealthMetricType.steps,
        targetValue: 10000,
      );

      final existingLog = HabitLog(
        id: 'log_1',
        habitId: habit.id,
        date: '2026-08-20',
        timestamp: now,
        completed: true,
        value: 10500.0,
        createdAt: now,
        updatedAt: now,
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 10500.0,
        fetchedAt: now,
      );

      final update = engine.evaluateHabit(
        habit: habit,
        metrics: metrics,
        existingLogs: [existingLog],
      );

      expect(update.shouldUpdate, isFalse);
      expect(update.wasNewlyCompleted, isFalse);
    });

    test('evaluateAll evaluates batch of habits for a date', () {
      final habit1 = createHabit(
        id: 'h_steps',
        title: 'Daily Steps',
        healthMetric: HealthMetricType.steps,
        targetValue: 10000,
      );
      final habit2 = createHabit(
        id: 'h_water',
        title: 'Hydration',
        healthMetric: HealthMetricType.hydration,
        targetValue: 2000,
        unit: 'ml',
      );
      final habit3 = createHabit(
        id: 'h_manual',
        title: 'Manual Habit',
        healthMetric: null,
        healthSyncEnabled: false,
      );

      final metrics = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 12000,
        hydrationMl: 2200,
        fetchedAt: now,
      );

      final updates = engine.evaluateAll(
        habits: [habit1, habit2, habit3],
        metrics: metrics,
        logsByHabit: {},
      );

      expect(updates.length, 2);
      expect(updates.any((u) => u.habit.id == 'h_steps' && u.isCompleted), isTrue);
      expect(updates.any((u) => u.habit.id == 'h_water' && u.isCompleted), isTrue);
    });
  });
}
