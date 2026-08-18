import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/shield_banking_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:intl/intl.dart';

void main() {
  group('ShieldBankingEngine', () {
    final now = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'habit-1',
      title: 'Workout',
      color: '#10B981',
      icon: 'fitness_center',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    test('gives 1 starter shield by default when no streak consistency', () {
      final state = ShieldBankingEngine.calculateBankState(
        habits: [habit],
        logs: [],
        shields: [],
        referenceDate: now,
        maxCapacity: 3,
        autoConsumeEnabled: true,
      );

      expect(state.totalShieldsEarned, 1);
      expect(state.usedShieldsCount, 0);
      expect(state.availableShields, 1);
      expect(state.daysToNextShield, 14);
      expect(state.progressToNextShield, 0.0);
      expect(state.autoConsumeEnabled, true);
    });

    test('earns 1 additional shield for every 14 days of unbroken consistency', () {
      // Create 28 days of logs
      final logs = <HabitLog>[];
      final formatter = DateFormat('yyyy-MM-dd');
      for (int i = 1; i <= 28; i++) {
        final d = now.subtract(Duration(days: i));
        logs.add(HabitLog(
          id: 'log-$i',
          habitId: habit.id,
          date: formatter.format(d),
          timestamp: d,
          completed: true,
          createdAt: d,
          updatedAt: d,
        ));
      }

      final state = ShieldBankingEngine.calculateBankState(
        habits: [habit],
        logs: logs,
        shields: [],
        referenceDate: now,
        maxCapacity: 5,
        autoConsumeEnabled: true,
      );

      // Starter 1 + (28 ~/ 14 = 2) = 3 total earned
      expect(state.totalShieldsEarned, 3);
      expect(state.availableShields, 3);
      expect(state.daysToNextShield, 14);
      expect(state.progressToNextShield, 0.0);
    });

    test('correctly accounts for used/active shields and caps at maxCapacity', () {
      // Create 42 days of unbroken streak (starter 1 + 3 earned = 4 total)
      final logs = <HabitLog>[];
      final formatter = DateFormat('yyyy-MM-dd');
      for (int i = 1; i <= 42; i++) {
        final d = now.subtract(Duration(days: i));
        logs.add(HabitLog(
          id: 'log-$i',
          habitId: habit.id,
          date: formatter.format(d),
          timestamp: d,
          completed: true,
          createdAt: d,
          updatedAt: d,
        ));
      }

      final appliedShield = HabitShield(
        id: 'shield-1',
        habitId: habit.id,
        date: '2026-08-01',
        autoApplied: true,
        createdAt: now,
        updatedAt: now,
      );

      final state = ShieldBankingEngine.calculateBankState(
        habits: [habit],
        logs: logs,
        shields: [appliedShield],
        referenceDate: now,
        maxCapacity: 2, // capped at 2
        autoConsumeEnabled: true,
      );

      expect(state.totalShieldsEarned, 4);
      expect(state.usedShieldsCount, 1);
      // Earned 4 - Used 1 = 3, but capped at maxCapacity 2
      expect(state.availableShields, 2);
    });
  });
}
