import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

void main() {
  group('StreakCalculator.isHabitStepSatisfiedForRoutine', () {
    test('returns false when no logs exist for positive habits', () {
      final habit = Habit(
        id: 'h1',
        title: 'Drink Water',
        color: '#3B82F6',
        targetType: HabitTargetType.boolean,
        frequencyType: HabitFrequencyType.timesPerDay,
        timesPerDay: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(StreakCalculator.isHabitStepSatisfiedForRoutine(habit, []), isFalse);
    });

    test('multi-slot habit (timesPerDay): single completed slot satisfies routine step', () {
      final habit = Habit(
        id: 'h1',
        title: 'Drink Water',
        color: '#3B82F6',
        targetType: HabitTargetType.boolean,
        frequencyType: HabitFrequencyType.timesPerDay,
        timesPerDay: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final singleSlotLog = HabitLog(
        id: 'log1',
        habitId: 'h1',
        date: '2026-09-01',
        timestamp: DateTime.now(),
        completed: true,
        intervalIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Whole day full completion is false (1 of 4)
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [singleSlotLog]), isFalse);

      // Routine step satisfaction is true (1 of 4 logged)
      expect(StreakCalculator.isHabitStepSatisfiedForRoutine(habit, [singleSlotLog]), isTrue);
    });

    test('numeric habit: partial increment (e.g. 5 of 20 pages) satisfies routine step', () {
      final habit = Habit(
        id: 'h2',
        title: 'Read 20 Pages',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        unit: 'pages',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final partialLog = HabitLog(
        id: 'log2',
        habitId: 'h2',
        date: '2026-09-01',
        timestamp: DateTime.now(),
        completed: false,
        value: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Whole day full completion is false (5 < 20)
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [partialLog]), isFalse);

      // Routine step satisfaction is true (5 pages logged)
      expect(StreakCalculator.isHabitStepSatisfiedForRoutine(habit, [partialLog]), isTrue);
    });

    test('timer habit: partial timer session (e.g. 15 mins of 45 mins) satisfies routine step', () {
      final habit = Habit(
        id: 'h3',
        title: 'Deep Focus',
        color: '#8B5CF6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.timer,
        targetValue: 45.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final timerLog = HabitLog(
        id: 'log3',
        habitId: 'h3',
        date: '2026-09-01',
        timestamp: DateTime.now(),
        completed: false,
        durationSeconds: 900, // 15 mins
        value: 15.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Whole day full completion is false (15 < 45)
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [timerLog]), isFalse);

      // Routine step satisfaction is true (15 mins recorded)
      expect(StreakCalculator.isHabitStepSatisfiedForRoutine(habit, [timerLog]), isTrue);
    });

    test('standard boolean habit: completed flag satisfies routine step', () {
      final habit = Habit(
        id: 'h4',
        title: 'Morning Meditation',
        color: '#EC4899',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final log = HabitLog(
        id: 'log4',
        habitId: 'h4',
        date: '2026-09-01',
        timestamp: DateTime.now(),
        completed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(StreakCalculator.isHabitStepSatisfiedForRoutine(habit, [log]), isTrue);
    });
  });
}
