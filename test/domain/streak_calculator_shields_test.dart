import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:intl/intl.dart';

void main() {
  group('StreakCalculator with Habit Shields (Streak Freeze)', () {
    final now = DateTime(2026, 8, 18);
    final formatter = DateFormat('yyyy-MM-dd');
    final habit = Habit(
      id: 'habit-shield-test',
      title: 'Daily Meditation',
      color: '#3B82F6',
      icon: 'self_improvement',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    test('missed day without shield breaks current streak', () {
      // Days completed: Aug 18 (today), Aug 17, Aug 16, missed Aug 15, completed Aug 14, 13
      final List<HabitLog> logs = [
        HabitLog(
          id: 'l-18',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 18)),
          timestamp: DateTime(2026, 8, 18),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-17',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 17)),
          timestamp: DateTime(2026, 8, 17),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-16',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 16)),
          timestamp: DateTime(2026, 8, 16),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-14',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 14)),
          timestamp: DateTime(2026, 8, 14),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-13',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 13)),
          timestamp: DateTime(2026, 8, 13),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final result = StreakCalculator.calculateStreak(habit, logs, now);
      // Streak without shield on Aug 15 is 3 (Aug 16, 17, 18)
      expect(result.currentStreak, 3);
      expect(result.totalShieldedDays, 0);
      expect(result.totalCompletions, 5);
    });

    test('shield on missed day preserves streak chain unbroken while genuine completion count remains accurate', () {
      // Days completed: Aug 18 (today), Aug 17, Aug 16, missed Aug 15 (shielded!), completed Aug 14, 13
      final List<HabitLog> logs = [
        HabitLog(
          id: 'l-18',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 18)),
          timestamp: DateTime(2026, 8, 18),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-17',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 17)),
          timestamp: DateTime(2026, 8, 17),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-16',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 16)),
          timestamp: DateTime(2026, 8, 16),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-14',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 14)),
          timestamp: DateTime(2026, 8, 14),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: 'l-13',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 13)),
          timestamp: DateTime(2026, 8, 13),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final shields = [
        HabitShield(
          id: 's-15',
          habitId: habit.id,
          date: formatter.format(DateTime(2026, 8, 15)),
          autoApplied: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final result = StreakCalculator.calculateStreak(habit, logs, now, shields);
      // Streak with shield on Aug 15 is 5 (Aug 13, 14, 16, 17, 18 unbroken chain!)
      expect(result.currentStreak, 5);
      expect(result.totalShieldedDays, 1);
      // Genuine completions are strictly 5 (does NOT falsely increment for shielded missed day)
      expect(result.totalCompletions, 5);
    });
  });
}
