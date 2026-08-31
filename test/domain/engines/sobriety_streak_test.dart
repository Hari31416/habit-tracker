import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

void main() {
  group('Sobriety / Negative Habit Streak Engine Tests', () {
    final now = DateTime(2026, 8, 31, 12, 0, 0);

    Habit createAbstinenceHabit({
      String id = 'abstinence_smoking',
      DateTime? cleanSince,
      DateTime? createdAt,
    }) {
      return Habit(
        id: id,
        title: 'Quit Smoking',
        color: '#EF4444',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        isNegative: true,
        cleanSince: cleanSince ?? now.subtract(const Duration(days: 10)),
        createdAt: createdAt ?? now.subtract(const Duration(days: 30)),
        updatedAt: now,
      );
    }

    test('clean duration calculates consecutive days without relapses', () {
      final habit = createAbstinenceHabit(
        cleanSince: now.subtract(const Duration(days: 7)),
      );

      final streak = StreakCalculator.calculateStreak(
        habit,
        [],
        now,
      );

      expect(streak.currentStreak, equals(8)); // 7 days ago + today = 8 days clean
      expect(streak.bestStreak, equals(8));
      expect(streak.completionRate30Days, equals(100));
    });

    test('relapse log resets current streak and evaluates best streak', () {
      final habit = createAbstinenceHabit(
        cleanSince: now.subtract(const Duration(days: 20)),
      );

      // Relapse logged 3 days ago
      final relapseDate = now.subtract(const Duration(days: 3));
      final relapseDateStr = StreakCalculator.formatIsoDate(relapseDate);

      final logs = [
        HabitLog(
          id: 'log_relapse_1',
          habitId: habit.id,
          date: relapseDateStr,
          timestamp: relapseDate,
          completed: false, // Relapse
          note: 'Stress at work triggered smoking',
          createdAt: relapseDate,
          updatedAt: relapseDate,
        ),
      ];

      final streak = StreakCalculator.calculateStreak(
        habit,
        logs,
        now,
      );

      // Relapse occurred 3 days ago. Current clean chain is: 2 days ago, 1 day ago, today = 3 days clean
      expect(streak.currentStreak, equals(3));
      // Best streak before relapse was 20 days ago to 4 days ago = 17 days
      expect(streak.bestStreak, equals(17));
    });

    test('isHabitCompletedOnDate returns true by default for negative habit without relapse', () {
      final habit = createAbstinenceHabit();
      expect(StreakCalculator.isHabitCompletedOnDate(habit, []), isTrue);
    });

    test('isHabitCompletedOnDate returns false if relapse log exists on that date', () {
      final habit = createAbstinenceHabit();
      final logs = [
        HabitLog(
          id: 'log_1',
          habitId: habit.id,
          date: '2026-08-31',
          timestamp: now,
          completed: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(StreakCalculator.isHabitCompletedOnDate(habit, logs), isFalse);
    });

    test('isHabitCompletedOnDate returns true for dates within clean period', () {
      final habit = createAbstinenceHabit(
        cleanSince: now.subtract(const Duration(days: 5)),
      );
      final checkDate = now.subtract(const Duration(days: 2));
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [], checkDate), isTrue);
    });

    test('isHabitCompletedOnDate returns false for dates before cleanSince', () {
      final habit = createAbstinenceHabit(
        cleanSince: now.subtract(const Duration(days: 3)),
      );
      final beforeStart = now.subtract(const Duration(days: 10));
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [], beforeStart), isFalse);
    });

    test('isHabitCompletedOnDate returns false for future dates', () {
      final habit = createAbstinenceHabit(
        cleanSince: now.subtract(const Duration(days: 3)),
      );
      final futureDate = now.add(const Duration(days: 2));
      expect(StreakCalculator.isHabitCompletedOnDate(habit, [], futureDate), isFalse);
    });

    test('Habit.elapsedCleanTime returns duration from cleanSince', () {
      final startTime = DateTime.now().subtract(const Duration(days: 2, hours: 5));
      final habit = Habit(
        id: 'h_test',
        title: 'Social Media Detox',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        isNegative: true,
        cleanSince: startTime,
        createdAt: startTime,
        updatedAt: startTime,
      );

      final elapsed = habit.elapsedCleanTime;
      expect(elapsed.inDays, equals(2));
      expect(elapsed.inHours, greaterThanOrEqualTo(53));
    });
  });
}
